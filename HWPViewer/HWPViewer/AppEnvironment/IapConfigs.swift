//
//  IapConfigs.swift
//  HWPViewer
//
//  Remote `iap_configs` (Firebase Remote Config, JSON parameter). Plans are data, not code:
//  the paywall renders one card per entry of `plans`, so adding a weekly/monthly/lifetime product
//  or swapping the trial product needs no app update.
//
//  {
//    "plans": [
//      {"id": "hwp.sub.yearly",       "period": "year", "trial": false},
//      {"id": "hwp.sub.yearly.trial", "period": "year", "trial": true, "badge": "best_offer", "selected": true}
//    ],
//    "enable_trial": true,                       // false → trial plans are dropped
//    "show_paywall_at": ["after_splash", "after_intro", "tools", "view_file"],
//    "percent_show_paywall": 35,                 // chance (0–100) an automatic show actually happens
//    "max_paywall_shows_per_session": 2,         // automatic shows per app session
//    "time_show_button_close_purchase_since_second_time": 1,   // seconds the X stays hidden from the 2nd show on
//    "continue_button_version": 1,               // 1 = CONTINUE, 2 = "Start free trial" / "Subscribe now"
//    "title_trial_version": 2                    // 1 = fixed title, 2 = "Try … free for N days" when a trial is selected
//  }
//  Legacy keys (`monthly_id`, `weekly_id`, `yearly_id`, `yearly_trial_id`, `is_show_in_tools`,
//  `is_show_in_view_file`) are still understood when `plans` / `show_paywall_at` are absent.
//

import Foundation

/// One purchasable subscription shown as a card on the paywall.
struct IapPlan: Codable, Equatable {
    enum Period: String, Codable {
        case week, month, year
    }

    let id: String
    var period: Period = .year
    var trial: Bool = false
    /// `"best_offer"` → localized "Best Offer" ribbon; any other text is shown as-is; nil → no ribbon.
    var badge: String?
    /// Preselected card. When none is flagged the last plan is selected.
    var selected: Bool = false

    enum CodingKeys: String, CodingKey { case id, period, trial, badge, selected }

    init(id: String, period: Period = .year, trial: Bool = false, badge: String? = nil, selected: Bool = false) {
        self.id = id; self.period = period; self.trial = trial; self.badge = badge; self.selected = selected
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        period = (try? c.decode(Period.self, forKey: .period)) ?? .year
        trial = (try? c.decode(Bool.self, forKey: .trial)) ?? false
        badge = try? c.decode(String.self, forKey: .badge)
        selected = (try? c.decode(Bool.self, forKey: .selected)) ?? false
    }
}

/// Where the app may open the paywall on its own (user taps on crown / gated features always work).
enum PaywallAutoTrigger: String, CaseIterable {
    case afterSplash = "after_splash"
    case afterIntro = "after_intro"
    case tools
    case viewFile = "view_file"
}

struct IapConfigs: Codable {
    var plans: [IapPlan]?
    var enableTrial: Bool?
    var showPaywallAt: [String]?
    var percentShowPaywall: Int?
    var maxPaywallShowsPerSession: Int?
    var closeButtonDelaySeconds: Int?
    var continueButtonVersion: Int?
    var titleTrialVersion: Int?
    // Legacy (base-project) keys, mapped when the new ones are missing.
    var monthlyId: String?
    var weeklyId: String?
    var weeklyTrialId: String?
    var yearlyId: String?
    var yearlyTrialId: String?
    var isShowInTools: Bool?
    var isShowInViewFile: Bool?

    enum CodingKeys: String, CodingKey {
        case plans
        case enableTrial = "enable_trial"
        case showPaywallAt = "show_paywall_at"
        case percentShowPaywall = "percent_show_paywall"
        case maxPaywallShowsPerSession = "max_paywall_shows_per_session"
        case closeButtonDelaySeconds = "time_show_button_close_purchase_since_second_time"
        case continueButtonVersion = "continue_button_version"
        case titleTrialVersion = "title_trial_version"
        case monthlyId = "monthly_id"
        case weeklyId = "weekly_id"
        case weeklyTrialId = "weekly_trial_id"
        case yearlyId = "yearly_id"
        case yearlyTrialId = "yearly_trial_id"
        case isShowInTools = "is_show_in_tools"
        case isShowInViewFile = "is_show_in_view_file"
    }

    /// Compiled-in fallback = the App Store Connect products of this app.
    static let fallbackPlans: [IapPlan] = [
        IapPlan(id: "hwp.sub.yearly", period: .year, trial: false),
        IapPlan(id: "hwp.sub.yearly.trial", period: .year, trial: true, badge: "best_offer", selected: true),
    ]

    static var current: IapConfigs {
        FirebaseRemoteConfigStore.shared.value("iap_configs", as: IapConfigs.self) ?? IapConfigs()
    }

    // MARK: - Derived

    /// Plans to show, in order: remote `plans` → legacy ids → compiled fallback; trial plans dropped when
    /// `enable_trial` is false (a card whose product fails to load is skipped by the paywall).
    var effectivePlans: [IapPlan] {
        var list = plans ?? legacyPlans
        if list.isEmpty { list = Self.fallbackPlans }
        if enableTrial == false { list = list.filter { !$0.trial } }
        if list.isEmpty { list = Self.fallbackPlans.filter { !$0.trial } }
        // Same product twice (e.g. legacy monthly == weekly) → keep the first.
        var seen = Set<String>()
        return list.filter { seen.insert($0.id).inserted }
    }

    var defaultPlan: IapPlan? {
        let list = effectivePlans
        return list.first(where: \.selected) ?? list.last
    }

    private var legacyPlans: [IapPlan] {
        var list: [IapPlan] = []
        if let weeklyId, !weeklyId.isEmpty { list.append(IapPlan(id: weeklyId, period: .week)) }
        if let monthlyId, !monthlyId.isEmpty { list.append(IapPlan(id: monthlyId, period: .month)) }
        // Legacy apps ship both a trial and a plain yearly id; the trial one is used only while
        // `enable_trial` is on, otherwise the plain yearly product takes its place.
        if enableTrial != false, let yearlyTrialId, !yearlyTrialId.isEmpty {
            list.append(IapPlan(id: yearlyTrialId, period: .year, trial: true, badge: "best_offer", selected: true))
        } else if let yearlyId, !yearlyId.isEmpty {
            list.append(IapPlan(id: yearlyId, period: .year, badge: "best_offer", selected: true))
        }
        return list
    }

    func allowsAutoShow(_ trigger: PaywallAutoTrigger) -> Bool {
        if let showPaywallAt { return showPaywallAt.contains(trigger.rawValue) }
        switch trigger {
        case .tools: return isShowInTools ?? true
        case .viewFile: return isShowInViewFile ?? true
        case .afterSplash, .afterIntro: return true
        }
    }

    var autoShowPercent: Int { min(max(percentShowPaywall ?? 100, 0), 100) }
    var autoShowsPerSession: Int { max(maxPaywallShowsPerSession ?? 2, 0) }
    var closeDelay: TimeInterval { TimeInterval(max(closeButtonDelaySeconds ?? 0, 0)) }
    var isTrialAwareContinue: Bool { (continueButtonVersion ?? 1) >= 2 }
    var isTrialAwareTitle: Bool { (titleTrialVersion ?? 1) >= 2 }
}
