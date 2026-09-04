//
//  PaywallPresenter.swift
//  HWPViewer
//
//  Bridges the app paywall (`PurchaseViewController` + `IAPVCEvent`) to the coordinator's
//  `presentPaywall` hook, which just needs a completion when the paywall goes away.
//

import UIKit
import SPNComponent

final class PaywallPresenter {
    static let shared = PaywallPresenter()
    private var activeBridges: [PaywallBridge] = []
    /// Paywalls shown this session (any reason) — drives the close-button delay "from the 2nd time".
    private(set) var showCount = 0
    /// Automatic (non user-initiated) shows this session — capped by `max_paywall_shows_per_session`.
    private(set) var autoShowCount = 0
    private var firedTriggers = Set<PaywallAutoTrigger>()

    /// Onboarding hook (after splash / after intro). Returns `false` when the paywall is skipped.
    @MainActor
    @discardableResult
    func present(trigger: SPNPaywallTrigger, from presenter: UIViewController, completion: @escaping () -> Void) -> Bool {
        let auto: PaywallAutoTrigger = trigger == .afterSplash ? .afterSplash : .afterIntro
        return presentIfAllowed(at: auto, from: presenter, completion: completion)
    }

    /// Automatic paywall for `trigger`, subject to remote `iap_configs`: place enabled in `show_paywall_at`,
    /// once per trigger per session, at most `max_paywall_shows_per_session`, with `percent_show_paywall` odds.
    /// Returns `false` (and calls `completion` immediately) when nothing is shown.
    @MainActor
    @discardableResult
    func presentIfAllowed(at trigger: PaywallAutoTrigger, from presenter: UIViewController, completion: @escaping () -> Void = {}) -> Bool {
        let config = IapConfigs.current
        guard !SPNSession.shared.isPremium,
              config.allowsAutoShow(trigger),
              !firedTriggers.contains(trigger),
              autoShowCount < config.autoShowsPerSession,
              Int.random(in: 0..<100) < config.autoShowPercent
        else {
            completion()
            return false
        }
        firedTriggers.insert(trigger)
        autoShowCount += 1
        logger("[Paywall] auto show at \(trigger.rawValue) (#\(autoShowCount)/\(config.autoShowsPerSession))")
        return present(from: presenter, completion: completion)
    }

    /// Feature-gated / settings entry point (no onboarding trigger).
    @MainActor
    @discardableResult
    func present(from presenter: UIViewController, completion: @escaping () -> Void = {}) -> Bool {
        guard !SPNSession.shared.isPremium else { return false }
        let purchaseVC = PaywallViewController()
        purchaseVC.isRepeatShow = showCount > 0
        showCount += 1
        let bridge = PaywallBridge { [weak self, weak purchaseVC] in
            self?.activeBridges.removeAll { $0 === purchaseVC?.delegate as? PaywallBridge }
            completion()
        }
        activeBridges.append(bridge)
        purchaseVC.delegate = bridge
        purchaseVC.modalPresentationStyle = .fullScreen
        presenter.present(purchaseVC, animated: true)
        return true
    }
}

final class PaywallBridge: IAPVCEvent {
    private var completion: (() -> Void)?

    init(completion: @escaping () -> Void) {
        self.completion = completion
    }

    private func finish() {
        let block = completion
        completion = nil
        block?()
    }

    func dismiss() { finish() }
    func dismissWhenPurchased() { finish() }
}
