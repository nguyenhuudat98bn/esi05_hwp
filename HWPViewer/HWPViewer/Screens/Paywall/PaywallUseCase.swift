//
//  PaywallUseCase.swift
//  HWPViewer
//
//  StoreKit access for the paywall: fetch the two products, buy, restore.
//

import SPNComponent
import Foundation
import Combine
import StoreKit

protocol PurchaseUseCase {
    func fetchItems() -> AnyPublisher<[Product], Error>
    func restore()
    func buy(with identifier: String)
}

final class PurchaseUseCaseImpl: PurchaseUseCase {
    func buy(with identifier: String) {
        guard !identifier.isEmpty else { return }
        StoreKitManager.shared.purchaseProduct(productID: identifier)
    }

    func restore() {
        StoreKitManager.shared.restorePurchases()
    }

    func fetchItems() -> AnyPublisher<[Product], Error> {
        Future { promise in
            let ids = PaywallPlan.allCases.map(\.identifier)
            var didResume = false
            StoreKitManager.shared.fetchProducts(identifiers: ids) { result in
                guard !didResume else { return }
                didResume = true
                switch result {
                case .success(let products):
                    let mapped = products.compactMap { sk -> Product? in
                        guard let plan = PaywallPlan.plan(for: sk.productIdentifier) else { return nil }
                        return Product(
                            id: sk.productIdentifier,
                            plan: plan,
                            price: Self.format(sk.price, locale: sk.priceLocale) ?? "",
                            introPrice: Self.introPrice(for: sk),
                            trialDays: Self.trialDays(for: sk),
                            skProduct: sk
                        )
                    }.sorted { $0.plan == .monthly && $1.plan == .yearly }
                    promise(.success(mapped))
                case .failure(let error):
                    promise(.failure(error))
                }
            }
        }.eraseToAnyPublisher()
    }

    // MARK: - Formatting

    static func format(_ price: NSDecimalNumber, locale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: price)
    }

    private static func introPrice(for product: SKProduct) -> String? {
        guard let offer = product.introductoryPrice, offer.paymentMode == .payAsYouGo || offer.paymentMode == .payUpFront else { return nil }
        return format(offer.price, locale: offer.priceLocale)
    }

    private static func trialDays(for product: SKProduct) -> Int {
        guard let offer = product.introductoryPrice, offer.paymentMode == .freeTrial else { return 0 }
        let units = offer.subscriptionPeriod.numberOfUnits
        switch offer.subscriptionPeriod.unit {
        case .day: return units
        case .week: return units * 7
        case .month: return units * 30
        case .year: return units * 365
        @unknown default: return units
        }
    }
}
