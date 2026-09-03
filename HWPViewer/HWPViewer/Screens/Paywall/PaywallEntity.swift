//
//  PaywallEntity.swift
//  HWPViewer
//
//  Products shown on the paywall (Figma H2): monthly with intro price + yearly with free trial.
//  Identifiers come from remote `iap_configs` with compiled-in fallbacks.
//

import Foundation
import StoreKit

struct Product {
    let id: String
    let plan: PaywallPlan
    let price: String
    /// Introductory price string (e.g. "₫99,000") when the product has a pay-as-you-go intro offer.
    let introPrice: String?
    /// Free-trial length in days (0 = none).
    let trialDays: Int
    let skProduct: SKProduct
}

enum PaywallPlan: CaseIterable {
    case monthly
    case yearly

    static var monthlyId: String { IapConfigs.config()?.monthlyId ?? "com.spn.hwpviewer.editor.monthly" }
    static var yearlyId: String { IapConfigs.config()?.yearlyTrialId ?? IapConfigs.config()?.yearlyId ?? "com.spn.hwpviewer.editor.yearly" }

    var identifier: String {
        switch self {
        case .monthly: return Self.monthlyId
        case .yearly: return Self.yearlyId
        }
    }

    static func plan(for identifier: String) -> PaywallPlan? {
        allCases.first { $0.identifier == identifier }
    }

    var isBestOffer: Bool { self == .yearly }
}

/// Legacy alias kept for StoreKitManager (`productItems`).
enum ProductItem: String, CaseIterable {
    case monthly, yearly

    var identifier: String {
        switch self {
        case .monthly: return PaywallPlan.monthlyId
        case .yearly: return PaywallPlan.yearlyId
        }
    }
}
