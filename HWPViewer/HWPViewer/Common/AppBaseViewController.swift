//
//  AppBaseViewController.swift
//  HWPViewer
//
//  App-level base: SPN ads/navigation + premium helpers shared by every screen.
//

import UIKit
import Combine
import SPNComponent

class AppBaseViewController: SPNBaseViewController {
    var isPremium: Bool { SPNSession.shared.isPremium }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        statusBarView.backgroundColor = navigationView.configuration.backgroundColor
        if !hidesBottomBarByDefault {
            // Tab roots: content (including the native ad slot) must end above the floating tab bar.
            // The tab controller reserves that space through `additionalSafeAreaInsets`.
            // Ads covered by other UI violate AdMob policy.
            containerStackView.snp.remakeConstraints { make in
                make.top.equalTo(statusBarView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            }
        }
        NotificationCenter.default.publisher(for: actionWhenPurchaseCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.premiumStatusDidChange() }
            .store(in: &cancellables)
    }

    /// Called after a purchase / restore: hide ads, unlock gated features.
    func premiumStatusDidChange() {
        guard isPremium else { return }
        // Hiding alone leaves the loaded ad alive underneath and it reappears on the next layout;
        // detach so the slot is really gone for a paying user.
        nativeAdSlot.detach()
        nativeAdSlot.isHidden = true
    }

    /// Runs `action` if the user is premium, otherwise presents the paywall and runs it on success.
    func requirePremium(_ action: @escaping () -> Void) {
        if isPremium {
            action()
            return
        }
        PaywallPresenter.shared.present(from: self) { [weak self] in
            guard let self, self.isPremium else { return }
            action()
        }
    }

    func presentPaywall() {
        PaywallPresenter.shared.present(from: self)
    }
}
