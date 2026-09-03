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

    /// Presents the paywall full screen. Returns `false` when it should be skipped.
    @MainActor
    func present(trigger: SPNPaywallTrigger, from presenter: UIViewController, completion: @escaping () -> Void) -> Bool {
        let purchaseVC = PurchaseViewController()
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

private final class PaywallBridge: IAPVCEvent {
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
