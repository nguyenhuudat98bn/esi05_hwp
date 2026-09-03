//
//  SettingsViewController.swift
//  HWPViewer
//
//  Settings (Figma H1): premium banner + rows (Language, Rate, Share, Manage Subscriptions, Privacy, Terms, EU Consent).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import StoreKit
import SafariServices
import SPNComponent

final class SettingsViewController: AppBaseViewController {
    private enum Row: CaseIterable {
        case language, rate, share, manageSubscriptions, privacy, terms, euConsent

        var title: String {
            switch self {
            case .language: return L10n.settingsLanguage
            case .rate: return L10n.settingsRateApp
            case .share: return L10n.settingsShareApp
            case .manageSubscriptions: return L10n.settingsManageSubscriptions
            case .privacy: return L10n.settingsPrivacyPolicy
            case .terms: return L10n.settingsTermsOfUse
            case .euConsent: return L10n.settingsEuConsent
            }
        }

        var icon: UIImage {
            switch self {
            case .language: return Asset.Assets.App.icSettingsLanguage.image
            case .rate: return Asset.Assets.App.icSettingsStar.image
            case .share: return Asset.Assets.App.icSettingsShare.image
            case .manageSubscriptions: return Asset.Assets.App.icSettingsWallet.image
            case .privacy: return Asset.Assets.App.icSettingsShieldCheck.image
            case .terms: return Asset.Assets.App.icSettingsShieldUser.image
            case .euConsent: return Asset.Assets.App.icSettingsCertificate.image
            }
        }
    }

    private let scrollView = UIScrollView()
    private let premiumBanner = PremiumBannerView()
    private let languageValue = UILabel()
    private var consentRow: SettingsRowView?

    init() {
        super.init(place: .settings, navigationConfigs: SPNNavigationConfiguration(
            title: L10n.settingsTitle, hasBackButton: false,
            titleFont: AppFonts.bold(22), titleColor: AppColors.textPrimary, backgroundColor: AppColors.background
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var hidesBottomBarByDefault: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.snp.updateConstraints { $0.height.equalTo(52) }
        containerStackView.addArrangedSubview(scrollView)
        containerStackView.addArrangedSubview(nativeAdSlot)
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false

        let card = UIView()
        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = 16
        card.layer.borderWidth = 1
        card.layer.borderColor = AppColors.divider.cgColor
        let rows = UIStackView()
        rows.axis = .vertical
        rows.spacing = 8
        for row in Row.allCases {
            let view = SettingsRowView(icon: row.icon, title: row.title)
            if row == .language {
                view.setValue(SPNSession.shared.currentLanguage.title)
            }
            if row == .euConsent { consentRow = view }
            view.tapPublisher.receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.handle(row) }
                .store(in: &cancellables)
            rows.addArrangedSubview(view)
        }
        card.addSubview(rows)
        rows.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)) }

        let content = UIStackView(arrangedSubviews: [premiumBanner, card])
        content.axis = .vertical
        content.spacing = 16
        scrollView.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 8, left: 16, bottom: 24, right: 16))
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-32)
        }
        premiumBanner.snp.makeConstraints { $0.height.equalTo(72) }
        premiumBanner.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.presentPaywall() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .languageChanged)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.languageDidChange() }
            .store(in: &cancellables)

        premiumStatusDidChange()
        consentRow?.isHidden = !SPNAdsManager.shared.consent.isPrivacyOptionsRequired
        setupAdvertiser(on: .settings)
    }

    override func premiumStatusDidChange() {
        super.premiumStatusDidChange()
        premiumBanner.isHidden = isPremium
    }

    private func languageDidChange() {
        // Package strings re-resolve on next screen build; rebuild the tab bar so every title updates.
        guard let window = view.window else { return }
        let nav = UINavigationController(rootViewController: MainTabBarController())
        nav.isNavigationBarHidden = true
        window.rootViewController = nav
        (nav.viewControllers.first as? MainTabBarController)?.selectedIndex = MainTabBarController.Tab.settings.rawValue
    }

    private func handle(_ row: Row) {
        switch row {
        case .language:
            let vc = SPNLanguageViewController(config: OnboardingConfigs.language(), source: .settings)
            navigationController?.pushViewController(vc, animated: true)
        case .rate:
            if let scene = view.window?.windowScene {
                SKStoreReviewController.requestReview(in: scene)
            } else if let url = URL(string: appStoreUrl) {
                UIApplication.shared.open(url)
            }
        case .share:
            var items: [Any] = [L10n.settingsShareMessage]
            if let url = URL(string: appStoreUrl) { items.append(url) }
            let activity = UIActivityViewController(activityItems: items, applicationActivities: nil)
            activity.popoverPresentationController?.sourceView = view
            present(activity, animated: true)
        case .manageSubscriptions:
            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                UIApplication.shared.open(url)
            }
        case .privacy:
            openWeb(privacyUrl)
        case .terms:
            openWeb(termOfUseUrl)
        case .euConsent:
            SPNAdsManager.shared.consent.showPrivacyOptions(from: self)
        }
    }

    private func openWeb(_ string: String) {
        guard let url = URL(string: string), url.scheme?.hasPrefix("http") == true else {
            showToast(L10n.popupErrorTitle)
            return
        }
        present(SFSafariViewController(url: url), animated: true)
    }
}

// MARK: - Row

final class SettingsRowView: UIControl {
    private let valueLabel = UILabel()
    private let caret = UIImageView(image: Asset.Assets.App.icCaretDown.image.withRenderingMode(.alwaysTemplate))

    init(icon: UIImage, title: String) {
        super.init(frame: .zero)
        let iconView = UIImageView(image: icon.withRenderingMode(.alwaysTemplate))
        iconView.tintColor = AppColors.primary
        iconView.contentMode = .scaleAspectFit
        let label = UILabel()
        label.text = title
        label.font = AppFonts.medium(16)
        label.textColor = AppColors.textPrimary
        valueLabel.font = AppFonts.medium(14)
        valueLabel.textColor = AppColors.textPrimary
        valueLabel.isHidden = true
        caret.tintColor = AppColors.textPrimary
        caret.isHidden = true
        addSubview(iconView)
        addSubview(label)
        addSubview(valueLabel)
        addSubview(caret)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        label.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        caret.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
        valueLabel.snp.makeConstraints { make in
            make.trailing.equalTo(caret.snp.leading).offset(-2)
            make.centerY.equalToSuperview()
            make.leading.greaterThanOrEqualTo(label.snp.trailing).offset(8)
        }
        snp.makeConstraints { $0.height.equalTo(52) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setValue(_ value: String?) {
        valueLabel.text = value
        valueLabel.isHidden = value == nil
        caret.isHidden = value == nil
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.6 : 1 }
    }

    var tapPublisher: AnyPublisher<Void, Never> { spnPublisher(for: .touchUpInside) }
}

// MARK: - Premium banner

final class PremiumBannerView: UIControl {
    private let gradient = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 12
        clipsToBounds = true
        gradient.colors = AppColors.gradientPremium.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradient)

        let texture = UIImageView(image: Asset.Assets.App.imgPremiumBannerBg.image)
        texture.contentMode = .scaleAspectFill
        texture.alpha = 0.6
        texture.isUserInteractionEnabled = false
        addSubview(texture)
        texture.snp.makeConstraints { $0.edges.equalToSuperview() }

        let crown = UIImageView(image: Asset.Assets.App.imgPremiumBannerCrown.image)
        crown.contentMode = .scaleAspectFit
        crown.isUserInteractionEnabled = false
        addSubview(crown)
        crown.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(-22)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 112, height: 114))
        }
        let sparkle = UIImageView(image: Asset.Assets.App.imgPremiumBannerSparkle.image)
        sparkle.contentMode = .scaleAspectFit
        addSubview(sparkle)
        sparkle.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(120)
            make.top.equalToSuperview().inset(3)
            make.size.equalTo(34)
        }

        let title = UILabel()
        title.text = L10n.settingsPremiumTitle
        title.font = AppFonts.bold(16)
        title.textColor = .white
        let subtitle = UILabel()
        subtitle.text = L10n.settingsPremiumSubtitle
        subtitle.font = AppFonts.regular(12)
        subtitle.textColor = .white
        let stack = UIStackView(arrangedSubviews: [title, subtitle])
        stack.axis = .vertical
        stack.spacing = 4
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.centerY.equalToSuperview().offset(-2)
            make.trailing.lessThanOrEqualTo(crown.snp.leading).offset(-8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    var tapPublisher: AnyPublisher<Void, Never> { spnPublisher(for: .touchUpInside) }
}
