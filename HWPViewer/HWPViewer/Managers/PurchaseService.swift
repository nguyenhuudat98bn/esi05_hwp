//
//  PurchaseService.swift
//  HWPViewer
//
//  StoreKit 2 purchase layer: loads products, buys (tagged with the IAP-hub appAccountToken),
//  restores, and keeps the premium flag in step with the App Store's entitlement list.
//
//  Premium = any verified, non-revoked entry in `Transaction.currentEntitlements` (signed by the
//  App Store, checked on device, readable offline). It is re-read at launch, on every foreground and
//  after every transaction, so a lapsed or refunded subscription turns premium off on its own — the
//  old verifyReceipt flow only re-checked when a new transaction happened to arrive, and it shipped
//  the App Store shared secret inside the binary.
//
//  AppsFlyer purchase revenue is reported server-side by the IAP hub (AppsFlyerAttributionHub.swift):
//  nothing here may log purchases to AppsFlyer, or revenue counts twice.
//

import Foundation
import StoreKit
import FacebookCore
import SPNComponent

enum PurchaseOutcome {
    case purchased
    /// Ask to Buy / Strong Customer Authentication: the App Store completes it later, and the
    /// transaction then arrives through `Transaction.updates`.
    case pending
    case cancelled
}

enum PurchaseServiceError: LocalizedError {
    case productUnavailable(String)
    case unverified

    var errorDescription: String? { L10n.purchaseFailedMessage }
}

@MainActor
final class PurchaseService {
    static let shared = PurchaseService()

    /// Why premium was just switched on — decides which confirmation the user gets.
    enum ActivationReason {
        case purchase
        case restore
        /// Launch / foreground re-check: turn premium on silently.
        case sync
    }

    /// Products loaded from the App Store so far, by product id.
    private var catalog: [String: StoreKit.Product] = [:]
    private var updatesTask: Task<Void, Never>?

    private init() {}

    // MARK: - Lifecycle

    /// Call once at launch. Listens for transactions that do not come back from `purchase` —
    /// renewals, Ask to Buy approvals, purchases on other devices, refunds, and anything left
    /// unfinished by a previous run (including StoreKit 1 transactions from older app versions) —
    /// then syncs the premium flag.
    func start() {
        guard updatesTask == nil else { return }
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                await self?.handleUpdate(update)
            }
        }
        Task { await refreshEntitlements() }
    }

    // MARK: - Products

    func products(for ids: [String]) async throws -> [StoreKit.Product] {
        let products = try await StoreKit.Product.products(for: ids)
        for product in products {
            catalog[product.id] = product
        }
        // StoreKit drops ids it cannot find without an error (not in App Store Connect / StoreKit
        // configuration, agreement or bundle id mismatch) — the paywall then shows "—".
        let missing = Set(ids).subtracting(products.map(\.id))
        logger("[IAP] products \(products.map { "\($0.id)=\($0.displayPrice)" })\(missing.isEmpty ? "" : " missing \(missing.sorted())")")
        return products
    }

    // MARK: - Purchase / restore

    func purchase(productID: String) async throws -> PurchaseOutcome {
        do {
            let product = try await storeProduct(id: productID)
            // The hub must hold token → appsflyer_id before Apple's server notification can reach it.
            // `register` times out after 5 s and never fails the purchase.
            let token = await AttributionAPI.register()
            let result = try await product.purchase(options: [.appAccountToken(token)])
            switch result {
            case .success(let verification):
                let transaction = try verified(verification)
                IapTracking.shared.purchaseSucceeded(productID: productID)
                AppEvents.logPurchaseEvent(product: product, transactionID: transaction.id)
                grant(transaction, reason: .purchase)
                await transaction.finish()
                return .purchased
            case .pending:
                logger("[IAP] \(productID) pending approval")
                return .pending
            case .userCancelled:
                IapTracking.shared.purchaseCancelled(productID: productID)
                return .cancelled
            @unknown default:
                IapTracking.shared.purchaseCancelled(productID: productID)
                return .cancelled
            }
        } catch {
            logger("[IAP] purchase \(productID) failed: \(error)")
            IapTracking.shared.purchaseFailed(productID: productID, error: error)
            throw error
        }
    }

    /// Restore button: syncs with the App Store (may ask the user to sign in), then re-reads the
    /// entitlements. Returns whether the user is premium afterwards.
    func restore() async throws -> Bool {
        try await AppStore.sync()
        return await refreshEntitlements(reason: .restore)
    }

    // MARK: - Entitlements

    /// Sets the premium flag from the App Store's current entitlement list. The app sells a single
    /// premium level, so any active entitlement unlocks it.
    @discardableResult
    func refreshEntitlements(reason: ActivationReason = .sync) async -> Bool {
        var active: Transaction?
        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement, transaction.revocationDate == nil else { continue }
            active = transaction
        }
        if let active {
            activate(productID: active.productID, reason: reason)
            return true
        }
        deactivate()
        return false
    }

    // MARK: - Private

    private func storeProduct(id: String) async throws -> StoreKit.Product {
        if let cached = catalog[id] { return cached }
        guard let fetched = try await products(for: [id]).first else {
            throw PurchaseServiceError.productUnavailable(id)
        }
        return fetched
    }

    private func handleUpdate(_ update: VerificationResult<Transaction>) async {
        guard case .verified(let transaction) = update else {
            logger("[IAP] unverified transaction update ignored")
            return
        }
        logger("[IAP] update \(transaction.productID) id=\(transaction.id) revoked=\(transaction.revocationDate != nil)")
        // An Ask to Buy approval of a purchase started from the paywall still counts as that
        // paywall's conversion; renewals have no pending paywall purchase and are ignored there.
        if transaction.revocationDate == nil {
            IapTracking.shared.purchaseSucceeded(productID: transaction.productID)
        }
        await transaction.finish()
        await refreshEntitlements(reason: .purchase)
    }

    /// Premium from a transaction just returned by `purchase`, before it is finished.
    private func grant(_ transaction: Transaction, reason: ActivationReason) {
        guard transaction.revocationDate == nil else { return }
        if let expiry = transaction.expirationDate, expiry < Date() { return }
        activate(productID: transaction.productID, reason: reason)
    }

    /// Idempotent: the success banner and `actionWhenPurchaseCompleted` fire only on the switch
    /// from free to premium — `PaywallViewController` dismisses on that notification, so a second
    /// post would dismiss whatever screen took its place.
    private func activate(productID: String, reason: ActivationReason) {
        let session = SPNSession.shared
        session.subscriptionPackage = productID
        guard !session.isPremium else { return }
        session.isPremium = true
        logger("[IAP] premium on (\(productID), \(reason))")
        switch reason {
        case .purchase:
            ReminderManager.shared.fireReminder(title: L10n.purchaseTitle, message: L10n.purchaseSuccessMessage)
        case .restore:
            ReminderManager.shared.fireReminder(title: L10n.purchaseTitle, message: L10n.purchaseRestoreSuccessMessage)
        case .sync:
            break
        }
        NotificationCenter.default.post(name: actionWhenPurchaseCompleted, object: nil)
    }

    private func deactivate() {
        guard SPNSession.shared.isPremium else { return }
        SPNSession.shared.isPremium = false
        logger("[IAP] no active entitlement, premium off")
    }

    private func verified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .verified(let value):
            return value
        case .unverified(_, let error):
            logger("[IAP] unverified transaction: \(error)")
            throw PurchaseServiceError.unverified
        }
    }
}
