//
//  PaywallEntity.swift
//  HWPViewer
//
//  Products shown on the paywall (Figma H2). Which products, in what order, with which badge comes
//  from remote `iap_configs.plans` (see IapConfigs.swift) — the paywall draws one card per plan.
//

import Foundation
import StoreKit

typealias PaywallPlan = IapPlan

struct Product {
    let id: String
    let plan: PaywallPlan
    /// Regular price, e.g. "₫1,159,000".
    let price: String
    /// Introductory price string (e.g. "₫99,000") when the product has a pay-as-you-go / pay-up-front intro offer.
    let introPrice: String?
    /// Free-trial length in days (0 = none).
    let trialDays: Int
    let skProduct: SKProduct
}

extension PaywallPlan {
    static var configured: [PaywallPlan] { IapConfigs.current.effectivePlans }

    static func plan(for identifier: String) -> PaywallPlan? {
        configured.first { $0.id == identifier }
    }

    /// Localized period unit ("week" / "month" / "year") for price strings.
    var periodName: String {
        switch period {
        case .week: return L10n.paywallPeriodWeek
        case .month: return L10n.paywallPeriodMonth
        case .year: return L10n.paywallPeriodYear
        }
    }

    var badgeText: String? {
        switch badge {
        case nil, "": return nil
        case "best_offer": return L10n.paywallOptionBestOffer
        case let text?: return text
        }
    }
}
