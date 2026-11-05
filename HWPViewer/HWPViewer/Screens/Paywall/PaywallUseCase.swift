//
//  PaywallUseCase.swift
//  HWPViewer
//
//  What the paywall needs from the store: the configured plans as products, buy, restore.
//

import Foundation

protocol PaywallUseCase {
    /// Products for the remote `iap_configs.plans`, in remote order; plans the store does not
    /// return are dropped.
    func loadProducts() async throws -> [PaywallProduct]
    func buy(productID: String) async throws -> PurchaseOutcome
    /// Whether the user is premium after the restore.
    func restore() async throws -> Bool
}

final class StoreKitPaywallUseCase: PaywallUseCase {
    /// nil → the remote `iap_configs.plans`; set for a paywall that sells something else (gift box).
    private let plansOverride: [PaywallPlan]?

    init(plans: [PaywallPlan]? = nil) {
        plansOverride = plans
    }

    func loadProducts() async throws -> [PaywallProduct] {
        let plans = plansOverride ?? PaywallPlan.configured
        let storeProducts = try await PurchaseService.shared.products(for: plans.map(\.id))
        var products: [PaywallProduct] = []
        for plan in plans {
            guard let storeProduct = storeProducts.first(where: { $0.id == plan.id }) else { continue }
            products.append(await PaywallProduct(plan: plan, storeProduct: storeProduct))
        }
        return products
    }

    func buy(productID: String) async throws -> PurchaseOutcome {
        try await PurchaseService.shared.purchase(productID: productID)
    }

    func restore() async throws -> Bool {
        try await PurchaseService.shared.restore()
    }
}
