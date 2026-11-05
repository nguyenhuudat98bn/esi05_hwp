//
//  AppBaseViewController.swift
//  HWPViewer
//
//  App-level base: SPN ads/navigation + premium helpers shared by every screen.
//

import UIKit
import Combine
import SnapKit
import SPNComponent

class AppBaseViewController: SPNBaseViewController, ToastInsetProviding {
    var isPremium: Bool { SPNSession.shared.isPremium }

    /// Anchored banner under the screen's content, on every screen: shown where remote
    /// `banner_advertiser_places` enables this screen's place (`interstitialPlace`, e.g. "home_screen"),
    /// collapsed elsewhere. Its height is added to the bottom safe area, so everything laid out
    /// against the safe area (bottom bars, the content stack) ends above it.
    let bannerAdSlot = SPNBannerAdSlot()

    /// Toasts are hosted in the window, whose safe area knows nothing about the space the tab
    /// controller reserves for the floating pill tab bar — so on a tab root a plain 24pt inset put
    /// the toast behind the pill. Add back whatever this screen had reserved.
    var toastBottomInset: CGFloat {
        let windowBottom = view.window?.safeAreaInsets.bottom ?? 0
        let reserved = max(0, view.safeAreaInsets.bottom - windowBottom)
        return 24 + reserved
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = AppColors.background
        statusBarView.backgroundColor = navigationView.configuration.backgroundColor
        layoutContainer()
        setupBanner()
        // Premium on (purchase / restore) or off (expired / refunded subscription).
        NotificationCenter.default.publisher(for: actionWhenPurchaseCompleted)
            .merge(with: NotificationCenter.default.publisher(for: premiumDidEnd))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.premiumStatusDidChange() }
            .store(in: &cancellables)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Screens add their own views after this base (bottom bars pinned to the screen's bottom edge
        // with a background running under the safe area): the banner must stay on top of them —
        // a covered ad violates AdMob policy. Their controls sit above it through the safe area.
        view.bringSubviewToFront(bannerAdSlot)
    }

    /// Tab roots: content (including the native ad slot) must end above the floating tab bar — the tab
    /// controller reserves that space through `additionalSafeAreaInsets`. Pushed screens run to the
    /// bottom edge, except above a banner. Ads covered by other UI violate AdMob policy.
    private func layoutContainer() {
        let endsAtSafeArea = !hidesBottomBarByDefault || bannerAdSlot.currentHeight > 0
        containerStackView.snp.remakeConstraints { make in
            make.top.equalTo(statusBarView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            if endsAtSafeArea {
                make.bottom.equalTo(view.safeAreaLayoutGuide)
            } else {
                make.bottom.equalToSuperview()
            }
        }
    }

    private func setupBanner() {
        view.addSubview(bannerAdSlot)
        // The banner sits in the band its own height adds under the safe area (above the home
        // indicator / the floating tab bar).
        bannerAdSlot.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        bannerAdSlot.onHeightChanged = { [weak self] height in
            guard let self else { return }
            additionalSafeAreaInsets.bottom = height
            layoutContainer()
            view.bringSubviewToFront(bannerAdSlot)
        }
        // The keyboard covers the bottom of the screen: keep the banner's room, hide the ad meanwhile
        // (an ad under the keyboard would count as obscured).
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)
            .sink { [weak self] _ in self?.bannerAdSlot.alpha = 0 }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)
            .sink { [weak self] _ in self?.bannerAdSlot.alpha = 1 }
            .store(in: &cancellables)
        guard !isPremium else { return }
        bannerAdSlot.attach(place: interstitialPlace, rootViewController: self)
    }

    /// Pushed screens run to the bottom edge (bottom bars pad themselves above the home indicator).
    /// When the native ad is the last row instead, close the stack with an empty row as tall as the
    /// bottom safe area, so the ad (its CTA) never sits under the home indicator. 0 high when the
    /// stack already ends at the safe area (banner shown, tab roots).
    func addBottomSafeAreaSpacer() {
        let spacer = UIView()
        containerStackView.addArrangedSubview(spacer)
        spacer.snp.makeConstraints { $0.top.equalTo(view.safeAreaLayoutGuide.snp.bottom) }
    }

    /// Called after a purchase / restore, and when a subscription ends: hide ads, unlock gated
    /// features (overrides also refresh premium-dependent UI such as AD badges on the way back).
    func premiumStatusDidChange() {
        guard isPremium else { return }
        // Hiding alone leaves the loaded ad alive underneath and it reappears on the next layout;
        // detach so the slot is really gone for a paying user.
        nativeAdSlot.detach()
        nativeAdSlot.isHidden = true
        bannerAdSlot.detach()
    }

    /// Runs `action` if the user is premium, otherwise presents the paywall and runs it on success.
    func requirePremium(at placement: PaywallPlacement, _ action: @escaping () -> Void) {
        if isPremium {
            action()
            return
        }
        PaywallPresenter.shared.present(from: self, placement: placement) { [weak self] in
            guard let self, self.isPremium else { return }
            action()
        }
    }

    func presentPaywall(at placement: PaywallPlacement) {
        PaywallPresenter.shared.present(from: self, placement: placement)
    }
}
