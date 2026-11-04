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

/// One plan card: the remote plan joined with its StoreKit 2 product.
struct PaywallProduct {
    let plan: PaywallPlan
    let storeProduct: StoreKit.Product
    /// Free-trial length in days this user would actually get (0 = none / not eligible).
    let trialDays: Int
    /// Paid intro price (pay-as-you-go / pay-up-front) this user would actually get, e.g. "₫99,000".
    let introPrice: String?

    var id: String { storeProduct.id }
    /// Regular price, localized by the App Store, e.g. "₫1,159,000".
    var price: String { storeProduct.displayPrice }

    /// Intro wording follows eligibility: someone who already used the intro offer of this
    /// subscription group is charged full price, so the card must not promise them a trial
    /// (App Review 3.1.2). StoreKit 1 could not tell, and showed the trial to everyone.
    init(plan: PaywallPlan, storeProduct: StoreKit.Product) async {
        self.plan = plan
        self.storeProduct = storeProduct
        let eligible = await storeProduct.subscription?.isEligibleForIntroOffer ?? false
        let offer = eligible ? storeProduct.subscription?.introductoryOffer : nil
        if let offer, offer.paymentMode == .freeTrial {
            trialDays = offer.period.approximateDays
            introPrice = nil
        } else if let offer, offer.paymentMode == .payAsYouGo || offer.paymentMode == .payUpFront {
            trialDays = 0
            introPrice = offer.displayPrice
        } else {
            trialDays = 0
            introPrice = nil
        }
    }
}

extension StoreKit.Product.SubscriptionPeriod {
    /// Length in days (months as 30, years as 365) — used for "<n>-day free trial" and `sub_id`.
    var approximateDays: Int {
        switch unit {
        case .day: return value
        case .week: return value * 7
        case .month: return value * 30
        case .year: return value * 365
        @unknown default: return value
        }
    }
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
