//
//  StoreKitManager.swift
//  
//
//  Created by Đạt Nguyễn hữu on 23/2/25.
//

import SPNComponent
import StoreKit
import SVProgressHUD
import FacebookCore

enum PurchaseErrorType: Error {
    case canMakePaymentsFailed
}

protocol StoreKitManagerDelegate: AnyObject {
    func didPurchaseSuccess()
    func didPurchaseFail(error: Error?)
    func didRestorePurchases()
}

final class StoreKitManager: NSObject {
    
    static let shared = StoreKitManager()
    weak var delegate: StoreKitManagerDelegate?
    typealias FetchProductCallback = (Result<Set<SKProduct>, Error>) -> Void
    private var completionHandlers: FetchProductCallback?
    private var receiptValidator = ReceiptValidator()
    var availableProducts: [String: SKProduct] = [:]
    var productItems: [Product] = []
    
    private override init() {}
    
    func purchaseProduct(productID: String) {
        if SKPaymentQueue.canMakePayments() {
            DispatchQueue.main.async {
                SVProgressHUD.show()
            }
            let paymentRequest = SKMutablePayment()
            paymentRequest.productIdentifier = productID
            SKPaymentQueue.default().add(paymentRequest)
        } else {
            delegate?.didPurchaseFail(error: nil)
        }
    }
    
    func restorePurchases() {
        if (SKPaymentQueue.canMakePayments()) {
          SKPaymentQueue.default().restoreCompletedTransactions()
        }
    }
    
    func finishTransactions(transaction: SKPaymentTransaction) {
        SKPaymentQueue.default().finishTransaction(transaction)
    }
}

extension StoreKitManager: SKPaymentTransactionObserver, SKProductsRequestDelegate {
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        if transactions.first(where: {
            $0.transactionState == .purchased || $0.transactionState == .restored
        }) != nil {
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
                logger("-------------> SVProgressHUD dismiss updatedTransactions")
            }
            self.validateReceipt()
        }
        
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                let productId = transaction.payment.productIdentifier
                let transactionTime = transaction.transactionDate?.timeIntervalSinceNow ?? 0

                let key = "logged_\(productId)"
                let savedValue = UserDefaults.standard.double(forKey: key)

                if savedValue != transactionTime,
                   let product = availableProducts[transaction.payment.productIdentifier] {
                    let amount = product.price.doubleValue
                    let currencyCode = product.priceLocale.currencyCode ?? "USD"
                    AppEvents.logPurchaseEvent(
                        product: product,
                        amount: amount,
                        currency: currencyCode,
                        additionalParams: [
                            .orderID: transaction.transactionIdentifier ?? "unknown",
                            .contentType: "product",
                            .contentID: product.productIdentifier
                        ]
                    )
                    UserDefaults.standard.set(transactionTime, forKey: key)
                    
                    logger("--------->purchased logPurchaseEvent\(transaction.transactionDate?.timeIntervalSinceNow)")
                }
                SKPaymentQueue.default().finishTransaction(transaction)
                // StoreKit itself is the authoritative local signal that the user paid. Receipt
                // validation below only refines it (expiry, product id) — waiting for that round
                // trip left paying users on the paywall with ads whenever it failed.
                activateVipUser()
                delegate?.didPurchaseSuccess()
            case .failed:
                delegate?.didPurchaseFail(error: transaction.error)
                ReminderManager.shared.fireReminder(title: L10n.applicationName, message: L10n.purchaseFailedMessage)
                
                if let error = transaction.error as NSError?,
                   error.code == SKError.paymentCancelled.rawValue {
                    DispatchQueue.main.async {
                        SVProgressHUD.dismiss()
                        logger("-------------> SVProgressHUD dismiss updatedTransactions")
                    }                           }
                SKPaymentQueue.default().finishTransaction(transaction)
            case .restored:
                SKPaymentQueue.default().finishTransaction(transaction)
                activateVipUser()
                delegate?.didRestorePurchases()
            default:
                break
            }
        }
    }
    
    func fetchProducts(identifiers: [String], completion: @escaping (FetchProductCallback)) {
        self.completionHandlers = completion
        let request = SKProductsRequest(productIdentifiers: Set(identifiers))
        request.delegate = self
        request.start()
    }
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        for product in response.products {
            availableProducts[product.productIdentifier] = product
        }
        
        self.report(result: .success(Set(response.products)), from: request)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        self.report(result: .failure(error), from: request)
    }
    
    private func report(result: Result<Set<SKProduct>, Error>, from request: SKRequest) {
        logger("---------> result\(result)")
        self.completionHandlers?(result)
    }
}

extension StoreKitManager {
    /// Idempotent: the transaction observer and receipt validation both call this for one purchase,
    /// and the notification must fire once — `PaywallViewController` dismisses on it, so a second
    /// post would dismiss whatever screen took its place.
    func activateVipUser() {
        guard !ApplicationSession.shared.isVipSubscription else { return }
        ReminderManager.shared.fireReminder(title: L10n.purchaseTitle, message: L10n.purchaseSuccessMessage)
        ApplicationSession.shared.isVipSubscription = true
//        SKANManager.shared.updateConversion(for: .subscription)
        NotificationCenter.default.post(name: actionWhenPurchaseCompleted, object: nil, userInfo: nil)
    }
    
    func inactiveUser() {
        ApplicationSession.shared.isVipSubscription = false
    }
    
    func validateReceipt(isSwitchEvr: Bool = false) {
        // Implement your server-side receipt validation here
        // Example: Send the receipt to your server for validation
        DispatchQueue.main.async {
            SVProgressHUD.show()
        }
        receiptValidator.validateReceipt(isSwitchEvr: isSwitchEvr) { [weak self] result in
            switch result {
            case .success(let response):
                self?.handleReceiptValidation(response: response, isSwitchEvr: isSwitchEvr)
            case .failure(let failure):
                logger("---------> \(failure.localizedDescription)")
            }
            DispatchQueue.main.async {
                SVProgressHUD.dismiss()
            }
        }
    }
    
    func handleReceiptValidation(response: [String: Any], isSwitchEvr: Bool = false) {
        receiptValidator.handleReceiptValidation(response: response, isSwitchEvr: isSwitchEvr) {[weak self] result in
            switch result {
            case .active:
                self?.activateVipUser()
            case .expired:
                // Apple answered and the subscription really has lapsed — the only safe downgrade.
                self?.inactiveUser()
            case .isSandbox, .validationFailure, .invalidate:
                // No verdict (offline, wrong shared secret, Apple error). Revoking here logged
                // paying users back out to the paywall, so keep whatever state we already have.
                break
            }
        }
    }
}
