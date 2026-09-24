//
//  PaywallPlanVisibility.swift
//  HWPViewer
//
//  Which configured plans the paywall actually shows once the StoreKit products are in.
//
//  App Review (guideline 3.1.2(c), build 1.0 (6)) rejected a paywall that listed the plain yearly
//  plan next to the yearly-with-trial plan and labelled the second one "Free trial enabled /
//  disabled": two cards for the same period read as a toggle that adds or removes the trial, and
//  the wording promised a trial the App Store Connect product did not carry. The rules here make
//  that impossible whatever remote `iap_configs.plans` says:
//
//   1. Trial wording is never taken from the config flag, only from the loaded product's
//      introductory offer (`Product.trialDays`), so the card cannot promise a trial that does not exist.
//   2. Only one plan per billing period is shown. When the config lists a trial and a plain variant
//      of the same period, the one whose product really has a free trial wins; otherwise the one
//      flagged `selected`, otherwise the first. The user sees one clear offer per period.
//   3. A plan whose product failed to load is hidden (nothing to buy) — unless nothing loaded at
//      all, in which case every card stays with its placeholder price so the screen is not empty.
//

import Foundation

enum PaywallPlanVisibility {

    /// Plans to show, in config order, filtered as described in the file header.
    /// - Parameters:
    ///   - plans: `IapConfigs.effectivePlans` (config order).
    ///   - products: StoreKit products loaded so far; empty means "not loaded yet".
    static func visiblePlans(plans: [PaywallPlan], products: [Product]) -> [PaywallPlan] {
        guard !products.isEmpty else { return plans }

        func product(for plan: PaywallPlan) -> Product? { products.first { $0.plan == plan } }

        // Rule 3: drop plans the store does not know about.
        let loaded = plans.filter { product(for: $0) != nil }

        // Rule 2: one plan per period.
        var chosen: [PaywallPlan] = []
        for plan in loaded where !chosen.contains(where: { $0.period == plan.period }) {
            let samePeriod = loaded.filter { $0.period == plan.period }
            let winner = samePeriod.first { (product(for: $0)?.trialDays ?? 0) > 0 }
                ?? samePeriod.first(where: \.selected)
                ?? plan
            chosen.append(winner)
        }
        return chosen
    }

    /// The plan to preselect among the visible ones: keep the current selection if it is still
    /// shown, otherwise the config's `selected` plan, otherwise the last card (the Figma default).
    static func selection(current: PaywallPlan?, visible: [PaywallPlan]) -> PaywallPlan? {
        if let current, visible.contains(current) { return current }
        return visible.first(where: \.selected) ?? visible.last
    }
}
