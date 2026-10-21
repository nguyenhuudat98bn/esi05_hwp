//
//  RatePromptManager.swift
//  HWPViewer
//
//  Asks for an App Store rating with the system sheet at a "success moment" (convert / save /
//  open), gated by remote `app_extra_configs.rate_prompt`. Spec: docs/flows/rate-app-prompt.md.
//  iOS decides whether the sheet actually appears (3 per 365 days) and never reports the result,
//  so "prompted" only means the API was called.
//

import StoreKit
import UIKit
import SPNComponent

enum RatePromptTrigger: String {
    case convertSuccess = "convert_success"
    case saveSuccess = "save_success"
    case openSuccess = "open_success"
}

final class RatePromptManager {
    static let shared = RatePromptManager()

    private enum Key {
        static let configVersion = "rate_config_version"
        static let sessionCount = "rate_session_count"
        static let installDate = "rate_install_date"
        static let successCount = "rate_success_count"
        static let promptCount = "rate_prompt_count"
        static let lastPromptAt = "rate_last_prompt_at"
        static let manualRated = "rate_manual_rated"
    }

    private let defaults = UserDefaults.standard
    /// Set by the interstitial callback and on every return to foreground (app-open ad shows there).
    private var lastFullScreenAdDismissedAt: Date?
    private var pending: DispatchWorkItem?
    private var isActive = true

    private init() {
        let center = NotificationCenter.default
        center.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isActive = true
            self?.lastFullScreenAdDismissedAt = Date()
        }
        center.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { [weak self] _ in
            self?.isActive = false
            self?.cancelPending(reason: "background")
        }
    }

    // MARK: - Counters

    /// One cold launch = one session. Also stamps the install date on the first launch.
    func markLaunch() {
        if defaults.object(forKey: Key.installDate) == nil {
            defaults.set(Date(), forKey: Key.installDate)
        }
        defaults.set(sessionCount + 1, forKey: Key.sessionCount)
    }

    func noteFullScreenAdDismissed() {
        lastFullScreenAdDismissedAt = Date()
    }

    private var sessionCount: Int { defaults.integer(forKey: Key.sessionCount) }
    private var successCount: Int { defaults.integer(forKey: Key.successCount) }
    private var promptCount: Int { defaults.integer(forKey: Key.promptCount) }
    private var lastPromptAt: Date? { defaults.object(forKey: Key.lastPromptAt) as? Date }
    private var manualRated: Bool { defaults.bool(forKey: Key.manualRated) }
    private var installDate: Date {
        defaults.object(forKey: Key.installDate) as? Date ?? SPNSession.shared.firstTimeOnboard
    }
    private var daysSinceInstall: Int {
        Calendar.current.dateComponents([.day], from: installDate, to: Date()).day ?? 0
    }

    // MARK: - Success moments

    /// Call once per success moment. Counts it, then prompts (after `delay_seconds`) when every gate passes.
    @MainActor
    func recordSuccess(_ trigger: RatePromptTrigger, from presenter: UIViewController) {
        let config = AppRemoteConfigs.current.rate
        resetIfConfigVersionChanged(config)
        defaults.set(successCount + 1, forKey: Key.successCount)

        if let reason = gateReason(config, trigger: trigger) {
            skip(trigger, reason: reason)
            return
        }
        cancelPending(reason: nil)
        let work = DispatchWorkItem { [weak self, weak presenter] in
            guard let self else { return }
            self.pending = nil
            guard let presenter else { return }
            if let reason = self.lateGateReason(config, presenter: presenter) {
                self.skip(trigger, reason: reason)
                return
            }
            self.request(trigger, from: presenter)
        }
        pending = work
        DispatchQueue.main.asyncAfter(deadline: .now() + config.delaySeconds, execute: work)
    }

    /// Settings row: always allowed, marks the user as rated so the automatic prompt stops.
    @MainActor
    func manualRateTapped(from presenter: UIViewController) {
        defaults.set(true, forKey: Key.manualRated)
        TrackingManager.shared.logCustomEvent(.rateManualTapped, parameters: ["source": "settings"])
        if let scene = presenter.view.window?.windowScene {
            SKStoreReviewController.requestReview(in: scene)
        } else if let url = URL(string: appStoreUrl + "?action=write-review") {
            UIApplication.shared.open(url)
        }
    }

    // MARK: - Gates

    /// Cheap checks done immediately at the success moment.
    private func gateReason(_ config: RatePromptConfig, trigger: RatePromptTrigger) -> String? {
        if !config.enabled { return "disabled" }
        if !config.triggers.contains(trigger.rawValue) { return "trigger_off" }
        if manualRated { return "manual_rated" }
        if promptCount >= config.maxPromptsTotal { return "exhausted" }
        if sessionCount < config.minSessions || daysSinceInstall < config.minDaysSinceInstall { return "cold" }
        if successCount < config.minSuccessEvents { return "success_events" }
        if let last = lastPromptAt,
           Date().timeIntervalSince(last) < TimeInterval(config.cooldownDays) * 86_400 { return "cooldown" }
        return nil
    }

    /// Checks re-run after the delay, when the screen has settled.
    private func lateGateReason(_ config: RatePromptConfig, presenter: UIViewController) -> String? {
        if !isActive { return "background" }
        if PaywallPresenter.shared.isPresenting { return "paywall" }
        if let adAt = lastFullScreenAdDismissedAt,
           Date().timeIntervalSince(adAt) < TimeInterval(config.adGapSeconds) { return "ad_gap" }
        let onTop = presenter.view.window != nil
            && presenter.presentedViewController == nil
            && (presenter.navigationController.map { $0.topViewController === presenter } ?? true)
        if !onTop { return "popup" }
        return nil
    }

    private func resetIfConfigVersionChanged(_ config: RatePromptConfig) {
        guard defaults.integer(forKey: Key.configVersion) != config.version else { return }
        defaults.set(config.version, forKey: Key.configVersion)
        defaults.set(0, forKey: Key.successCount)
        defaults.set(0, forKey: Key.promptCount)
        defaults.removeObject(forKey: Key.lastPromptAt)
        defaults.set(false, forKey: Key.manualRated)
    }

    // MARK: - Prompt

    @MainActor
    private func request(_ trigger: RatePromptTrigger, from presenter: UIViewController) {
        guard let scene = presenter.view.window?.windowScene else {
            skip(trigger, reason: "no_scene")
            return
        }
        defaults.set(promptCount + 1, forKey: Key.promptCount)
        defaults.set(Date(), forKey: Key.lastPromptAt)
        TrackingManager.shared.logCustomEvent(.ratePromptRequested, parameters: [
            "trigger": trigger.rawValue,
            "mode": "system",
            "prompt_index": promptCount,
            "session_count": sessionCount,
            "days_since_install": daysSinceInstall,
        ])
        SKStoreReviewController.requestReview(in: scene)
    }

    private func skip(_ trigger: RatePromptTrigger, reason: String) {
        TrackingManager.shared.logCustomEvent(.ratePromptSkipped, parameters: [
            "trigger": trigger.rawValue, "reason": reason,
        ])
    }

    private func cancelPending(reason: String?) {
        pending?.cancel()
        pending = nil
    }
}
