//
//  IapTracking.swift
//  HWPViewer
//
//  IAP funnel events (MO order "IAP tracking event"), logged to Firebase through TrackingManager:
//    iap_purchase_show → iap_continue_click → iap_purchase_success | iap_purchase_cancelled | iap_purchase_failed
//  Every event carries:
//    where       – paywall placement (`PaywallPlacement`)
//    when        – "1st_open" during the first launch after install, else "returning_open"
//    sub_id      – plan as "<period>[_<n>d]", e.g. "year", "week_3d" (n = free-trial days)
//    ui_version  – `iap_configs.continue_button_version` (1, 2)
//    value       – price of the selected plan in the store currency (`currency` sent alongside)
//

import Foundation
import StoreKit
import SPNComponent

/// Where the paywall was opened. Raw values are the `where` param.
enum PaywallPlacement: String {
    // Automatic shows
    case afterIntro = "after_intro"     // end of first-open onboarding
    case beforeHome = "before_home"     // after splash, returning users
    case beforeView = "before_view"     // before opening a document
    case tools                          // opening the Tools tab
    // User-initiated
    case homeCrown = "home_crown"
    case toolsCrown = "tools_crown"
    case setting
    // Premium-gated features
    case convert
    case edit

    init(_ trigger: PaywallAutoTrigger) {
        switch trigger {
        case .afterSplash: self = .beforeHome
        case .afterIntro: self = .afterIntro
        case .tools: self = .tools
        case .viewFile: self = .beforeView
        }
    }
}

final class IapTracking {
    static let shared = IapTracking()

    private enum Event: String {
        case show = "iap_purchase_show"
        case continueClick = "iap_continue_click"
        case cancelled = "iap_purchase_cancelled"
        case failed = "iap_purchase_failed"
        case success = "iap_purchase_success"
    }

    private static let launchedBeforeKey = "iap_tracking_launched_before"
    /// Snapshot taken once at launch (`markLaunch`), so the whole first session reports "1st_open".
    private var isFirstOpenSession = false

    /// Placement of the paywall currently on screen.
    private var placement: PaywallPlacement?
    /// Purchase started from the paywall and not finished yet: outcome events are only sent for it,
    /// so renewals / restores delivered by StoreKit later are not counted as paywall conversions.
    private var pending: (productID: String, params: [String: Any])?

    private init() {}

    /// Call once in `didFinishLaunching`.
    func markLaunch() {
        let defaults = UserDefaults.standard
        isFirstOpenSession = !defaults.bool(forKey: Self.launchedBeforeKey)
        defaults.set(true, forKey: Self.launchedBeforeKey)
    }

    // MARK: - Paywall

    func paywallPresented(at placement: PaywallPlacement) {
        self.placement = placement
    }

    /// Once per paywall, when its products arrive (`product` = preselected plan, nil if StoreKit failed).
    func logShow(plan: IapPlan?, product: SKProduct?) {
        log(.show, params(plan: plan, product: product))
    }

    func logContinueClick(plan: IapPlan, product: SKProduct?) {
        let params = params(plan: plan, product: product)
        pending = (plan.id, params)
        log(.continueClick, params)
    }

    // MARK: - StoreKit outcomes

    func transactionPurchased(productID: String) {
        guard let params = consumePending(productID) else { return }
        log(.success, params)
    }

    func transactionFailed(productID: String, error: Error?) {
        guard var params = consumePending(productID) else { return }
        if let skError = error as? SKError, skError.code == .paymentCancelled {
            log(.cancelled, params)
        } else {
            if let error = error as NSError? { params["error_code"] = error.code }
            log(.failed, params)
        }
    }

    // MARK: - Helpers

    private func consumePending(_ productID: String) -> [String: Any]? {
        guard let pending, pending.productID == productID else { return nil }
        self.pending = nil
        return pending.params
    }

    private func params(plan: IapPlan?, product: SKProduct?) -> [String: Any] {
        var params: [String: Any] = [
            "where": placement?.rawValue ?? "unknown",
            "when": isFirstOpenSession ? "1st_open" : "returning_open",
            "ui_version": IapConfigs.current.continueButtonVersion ?? 1,
        ]
        if let plan { params["sub_id"] = Self.subID(plan: plan, product: product) }
        if let product {
            // Via the decimal string: NSDecimalNumber.doubleValue gives 19.990000000000002 for 19.99.
            params["value"] = Double(product.price.stringValue) ?? product.price.doubleValue
            params["currency"] = product.priceLocale.currencyCode ?? "USD"
        }
        return params
    }

    /// "<period>[_<n>d]": period from the StoreKit product when loaded, else from the config plan.
    static func subID(plan: IapPlan, product: SKProduct?) -> String {
        var period = plan.period.rawValue
        if let unit = product?.subscriptionPeriod?.unit {
            switch unit {
            case .day: period = "day"
            case .week: period = "week"
            case .month: period = "month"
            case .year: period = "year"
            @unknown default: break
            }
        }
        guard let offer = product?.introductoryPrice, offer.paymentMode == .freeTrial else { return period }
        let units = offer.subscriptionPeriod.numberOfUnits
        let days: Int
        switch offer.subscriptionPeriod.unit {
        case .day: days = units
        case .week: days = units * 7
        case .month: days = units * 30
        case .year: days = units * 365
        @unknown default: days = units
        }
        return "\(period)_\(days)d"
    }

    private func log(_ event: Event, _ params: [String: Any]) {
        TrackingManager.shared.logEvent(event.rawValue, parameters: params)
    }
}
