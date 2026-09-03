//
//  PurchaseUseCase.swift
//  HWPViewer
//
//  Created by Eragon on 25/8/25.
//

import SPNComponent
import Foundation
import Combine
import PDFKit
import SVProgressHUD
import StoreKit

protocol PurchaseFormatService {
    func formatPrice(for product: SKProduct) -> String?
    func calculateWeeklyPrice(for product: SKProduct) -> NSNumber?
    func getFreeDayTrial(for product: SKProduct) -> String
    func formatPricePerWeek(for product: SKProduct) -> String?
}

extension PurchaseFormatService {
    func formatPrice(for product: SKProduct) -> String? {
        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        return priceFormatter.string(from: product.price)
    }
    
    func calculateWeeklyPrice(for product: SKProduct) -> NSNumber? {
        let price = product.price as Decimal
        var pricePerWeek: Decimal = 0
        switch product.productIdentifier {
        case ProductItem.week.identifier:
            pricePerWeek = price
        case ProductItem.year.identifier:
            pricePerWeek = price / Decimal(365) * Decimal(7)
        default:
            return nil
        }
        return pricePerWeek as NSDecimalNumber
    }

    func getFreeDayTrial(for product: SKProduct) -> String {
        var freeTrial = ""
        if let introductoryOffer = product.introductoryPrice, introductoryOffer.paymentMode == .freeTrial {
            let subscriptionPeriod = introductoryOffer.subscriptionPeriod
            let numberOfUnits = subscriptionPeriod.numberOfUnits
            switch subscriptionPeriod.unit {
            case .day:
                freeTrial = L10n.purchaseFreeTrial("\(numberOfUnits)")
            case .week:
                freeTrial = L10n.purchaseFreeTrial("\(numberOfUnits * 7)")
            default:
                logger("Unknown subscription period.")
            }
        }
        logger("---------------> \(freeTrial)")
        return freeTrial
    }
        
    func formatPricePerWeek(for product: SKProduct) -> String? {
        let priceFormatter = NumberFormatter()
        priceFormatter.numberStyle = .currency
        priceFormatter.locale = product.priceLocale
        if let pricePerWeek = priceFormatter.string(from: calculateWeeklyPrice(for: product) ?? 0) {
            return L10n.purchasePricePerWeek(pricePerWeek)
        }
        return nil
    }
}

protocol PurchaseUseCase {
    func fetchItems() -> AnyPublisher<[Product], Error>
    func restore()
    func buy(with identifier: String)
}

class PurchaseUseCaseImpl: PurchaseUseCase, PurchaseFormatService {
    func buy(with identifier: String) {
        guard !identifier.isEmpty else {
            return
        }
        StoreKitManager.shared.purchaseProduct(productID: identifier)
    }
    
    func fetchItems() -> AnyPublisher<[Product], Error> {
        Future { [weak self] promise in
            Task { [weak self] in
                do {
                    let items = try await self?.fetchProducts(identifiers: ProductItem.allCases.map { $0.identifier }) ?? []
                    promise(.success(items))
                } catch let error {
                    logger("Error loading PDF files: \(error)")
                    let error = NSError(domain: "Error", code: 404, userInfo: [NSLocalizedDescriptionKey: "No Items"])
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }
        
    func restore(){
        StoreKitManager.shared.restorePurchases()
    }
    
    private func fetchProducts(identifiers: [String]) async throws -> [Product] {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            DispatchQueue.main.async {
                SVProgressHUD.show()
            }
            var didResume = false
            StoreKitManager.shared.fetchProducts(identifiers: identifiers) { [weak self] result in
                DispatchQueue.main.async {
                    SVProgressHUD.dismiss()
                }
                guard let self else {return}
                guard !didResume else { return }
                didResume = true
                switch result {
                case .success(let listProduct):
                    let result = listProduct.sorted(by: { p1, p2 in
                        p1.price.compare(p2.price) == .orderedAscending
                    }).map { [weak self] in
                        let productItem = ProductItem(rawValue: $0.productIdentifier)
                        return Product(
                            id: $0.productIdentifier,
                            title: productItem.title,
                            name: productItem.name,
                            description: $0.localizedDescription,
                            price: self?.formatPrice(for: $0) ?? "",
                            pricePerWeek: self?.formatPricePerWeek(for: $0) ?? "",
                            freeDayTrial: self?.getFreeDayTrial(for: $0) ?? "",
                            isBestValue: productItem.isBestValue
                        )
                    }
                    continuation.resume(with: .success(result))
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
}
