//
//  PaywallViewController.swift
//  HWPViewer
//
//  Paywall (Figma H2): header art + hero, X / Restore, "Go Premium with HWP Pro", PRO/BASIC table,
//  fine print, one plan card per remote `iap_configs.plans` entry (badge / trial from config), CONTINUE,
//  Terms | Privacy. Close-button delay, title and CONTINUE wording variants also come from `iap_configs`.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SafariServices
import SPNComponent

protocol IAPVCEvent: AnyObject {
    func dismiss()
    func dismissWhenPurchased()
}

final class PaywallViewController: UIViewController {
    weak var delegate: IAPVCEvent?

    private let viewModel = PurchaseViewModel(useCase: PurchaseUseCaseImpl())
    private let fetchSubject = PassthroughSubject<Void, Never>()
    private let restoreSubject = PassthroughSubject<Void, Never>()
    private let buySubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()

    private let config = IapConfigs.current
    private var products: [Product] = []
    private lazy var plans: [PaywallPlan] = config.effectivePlans
    private lazy var selectedPlan: PaywallPlan? = config.defaultPlan
    /// Set by PaywallPresenter: true when this is not the first paywall of the session (X may be delayed).
    var isRepeatShow = false

    // MARK: - Controls
    private let headerImage = UIImageView(image: Asset.Assets.App.imgPaywallHeaderBg.image)
    private let heroImage = UIImageView(image: Asset.Assets.App.imgPaywallHero.image)
    private let closeButton = UIButton(type: .system)
    private let restoreButton = UIButton(type: .system)
    private let finePrint = UILabel()
    private let titleLabel = UILabel()
    private var planCards: [PlanCardView] = []
    private let continueButton = GradientButton(title: L10n.paywallContinue, colors: AppColors.gradientContinue)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        bind()
        fetchSubject.send()
        // Ask here, not on purchase: the answer is in before the transaction finishes, so the
        // success banner can fire straight away instead of the permission dialog interrupting.
        ReminderManager.shared.requestAuthorizationIfNeeded()
    }

    // MARK: - Setup
    private func setupViews() {
        headerImage.contentMode = .scaleAspectFill
        headerImage.clipsToBounds = true
        view.addSubview(headerImage)
        headerImage.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-60)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(300)
        }
        let fade = GradientView(colors: [UIColor.white.withAlphaComponent(0), .white], startPoint: CGPoint(x: 0.5, y: 0.55), endPoint: CGPoint(x: 0.5, y: 0.95))
        view.addSubview(fade)
        fade.snp.makeConstraints { $0.edges.equalTo(headerImage) }

        heroImage.contentMode = .scaleAspectFit
        view.addSubview(heroImage)
        heroImage.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(24)
            make.size.equalTo(CGSize(width: 168, height: 150))
        }

        closeButton.setImage(Asset.Assets.App.icPaywallCloseTimes.image.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = AppColors.textTertiary
        restoreButton.setTitle(L10n.purchaseButtonRestore, for: .normal)
        restoreButton.titleLabel?.font = AppFonts.regular(12)
        restoreButton.setTitleColor(AppColors.textTertiary, for: .normal)
        view.addSubview(closeButton)
        view.addSubview(restoreButton)
        closeButton.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.size.equalTo(40)
        }
        restoreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalTo(closeButton)
            make.height.equalTo(40)
        }

        let title = titleLabel
        title.text = L10n.paywallTitle
        title.font = AppFonts.condensedBold(28)
        title.textColor = AppColors.textPrimary
        title.textAlignment = .center
        title.numberOfLines = 2
        view.addSubview(title)
        title.snp.makeConstraints { make in
            make.top.equalTo(heroImage.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(48)
        }

        // Feature table
        let table = UIStackView()
        table.axis = .vertical
        table.spacing = 12
        table.addArrangedSubview(featureRow(nil, pro: nil, basic: nil))
        let features: [(String, Bool)] = [
            (L10n.paywallFeatureOpenRead, true),
            (L10n.paywallFeatureEdit, false),
            (L10n.paywallFeatureConvert, false),
            (L10n.paywallFeatureUnlimited, false),
            (L10n.paywallFeaturePrint, false),
            (L10n.paywallFeatureAdFree, false),
        ]
        for (text, basic) in features {
            table.addArrangedSubview(featureRow(text, pro: true, basic: basic))
        }
        view.addSubview(table)
        table.snp.makeConstraints { make in
            make.top.equalTo(title.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(15)
        }

        // Bottom block
        finePrint.font = AppFonts.medium(12)
        finePrint.textColor = AppColors.textTertiary
        finePrint.textAlignment = .center
        finePrint.numberOfLines = 0

        // One card per configured plan (remote order).
        planCards = plans.map { plan in
            let card = PlanCardView()
            card.onTap = { [weak self] in self?.select(plan) }
            return card
        }
        let plans = UIStackView(arrangedSubviews: planCards)
        plans.axis = .vertical
        plans.spacing = 16

        let legal = UIStackView(arrangedSubviews: [
            legalButton(L10n.purchaseTermOfUse) { [weak self] in self?.openWeb(termOfUseUrl) },
            legalSeparator(),
            legalButton(L10n.purchasePrivacyPolicy) { [weak self] in self?.openWeb(privacyUrl) },
        ])
        legal.axis = .horizontal
        legal.spacing = 19
        legal.alignment = .center
        let legalWrap = UIView()
        legalWrap.addSubview(legal)
        legal.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.bottom.equalToSuperview()
        }

        let bottom = UIStackView(arrangedSubviews: [finePrint, plans, continueButton, legalWrap])
        bottom.axis = .vertical
        bottom.spacing = 12
        bottom.setCustomSpacing(16, after: plans)
        view.addSubview(bottom)
        bottom.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(24)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(8)
            make.top.greaterThanOrEqualTo(table.snp.bottom).offset(12)
        }
        continueButton.snp.makeConstraints { $0.height.equalTo(46) }

        if let selectedPlan { select(selectedPlan) }
        updateTexts()
        applyCloseDelay()
    }

    /// From the 2nd paywall of the session on, keep the X hidden for `time_show_button_close_purchase_since_second_time` s.
    private func applyCloseDelay() {
        let delay = config.closeDelay
        guard isRepeatShow, delay > 0 else { return }
        closeButton.alpha = 0
        closeButton.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self else { return }
            self.closeButton.isUserInteractionEnabled = true
            UIView.animate(withDuration: 0.25) { self.closeButton.alpha = 1 }
        }
    }

    private func featureRow(_ text: String?, pro: Bool?, basic: Bool?) -> UIView {
        let row = UIView()
        let label = UILabel()
        label.font = AppFonts.medium(14)
        label.textColor = AppColors.textPaywall
        label.numberOfLines = 2
        if let text {
            label.text = "•  \(text)"
        }
        let proView = markView(pro, header: L10n.paywallColumnPro)
        let basicView = markView(basic, header: L10n.paywallColumnBasic)
        row.addSubview(label)
        row.addSubview(proView)
        row.addSubview(basicView)
        basicView.snp.makeConstraints { make in
            make.trailing.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(50)
            make.top.bottom.equalToSuperview()
        }
        proView.snp.makeConstraints { make in
            make.trailing.equalTo(basicView.snp.leading)
            make.centerY.equalToSuperview()
            make.width.equalTo(50)
        }
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview()
            make.trailing.lessThanOrEqualTo(proView.snp.leading).offset(-8)
            make.centerY.equalToSuperview()
        }
        row.snp.makeConstraints { $0.height.equalTo(22) }
        return row
    }

    private func markView(_ value: Bool?, header: String) -> UIView {
        if let value {
            let image = value ? Asset.Assets.App.icPaywallFeatureCheck.image : Asset.Assets.App.icPaywallFeatureCross.image
            let iv = UIImageView(image: image)
            iv.contentMode = .scaleAspectFit
            let wrap = UIView()
            wrap.addSubview(iv)
            iv.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(20)
            }
            return wrap
        }
        let label = UILabel()
        label.text = header
        label.font = AppFonts.bold(14)
        label.textColor = AppColors.textPaywall
        label.textAlignment = .center
        return label
    }

    private func legalButton(_ title: String, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = AppFonts.regular(11)
        button.setTitleColor(AppColors.textPrimary, for: .normal)
        button.tapPublisher.receive(on: DispatchQueue.main).sink { _ in action() }.store(in: &cancellables)
        return button
    }

    private func legalSeparator() -> UIView {
        let line = UIView()
        line.backgroundColor = AppColors.textPrimary
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(13)
        }
        return line
    }

    // MARK: - Bind
    private func bind() {
        let output = viewModel.transform(PurchaseViewModel.Input(
            fetchFiles: fetchSubject.eraseToAnyPublisher(),
            restore: restoreSubject.eraseToAnyPublisher(),
            buy: buySubject.eraseToAnyPublisher()
        ))
        output.$listItems.compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] products in
                self?.products = products
                self?.updateTexts()
            }
            .store(in: &cancellables)
        output.$isLoading.compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showLoadingHUD($0) }
            .store(in: &cancellables)
        output.$errorMessage.compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in self?.showToast($0) }
            .store(in: &cancellables)

        closeButton.tapPublisher
            .debounce(for: .seconds(0.3), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true) { self?.delegate?.dismiss() }
            }
            .store(in: &cancellables)
        restoreButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.restoreSubject.send() }
            .store(in: &cancellables)
        continueButton.tapPublisher
            .throttle(for: .seconds(0.5), scheduler: RunLoop.main, latest: false)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, let selectedPlan else { return }
                buySubject.send(selectedPlan.id)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: actionWhenPurchaseCompleted)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true) { self?.delegate?.dismissWhenPurchased() }
            }
            .store(in: &cancellables)
    }

    private func select(_ plan: PaywallPlan) {
        selectedPlan = plan
        for (card, candidate) in zip(planCards, plans) {
            card.setSelected(candidate == plan)
        }
        updateTexts()
    }

    private func product(for plan: PaywallPlan) -> Product? {
        products.first { $0.plan == plan }
    }

    /// Card title/subtitle from the StoreKit product: trial plans say enabled/disabled, priced plans show
    /// "<price> / <period>" (or the intro offer + regular price when the product has one).
    private func updateTexts() {
        for (card, plan) in zip(planCards, plans) {
            let product = product(for: plan)
            if plan.trial {
                let enabled = (product?.trialDays ?? 0) > 0
                card.configure(title: enabled ? L10n.paywallOptionTrialEnabled : L10n.paywallOptionTrialDisabled,
                               subtitle: nil, badge: plan.badgeText)
            } else if let product, let intro = product.introPrice {
                card.configure(title: L10n.paywallOptionIntro(intro, plan.periodName),
                               subtitle: L10n.paywallOptionIntroSubtitle(product.price, plan.periodName), badge: plan.badgeText)
            } else {
                card.configure(title: L10n.paywallOptionPrice(product?.price ?? "—", plan.periodName),
                               subtitle: nil, badge: plan.badgeText)
            }
        }

        guard let selectedPlan else { finePrint.text = " "; return }
        let selected = product(for: selectedPlan)
        let trialDays = selected?.trialDays ?? 0
        if let selected, trialDays > 0 {
            finePrint.text = L10n.paywallNoteTrial("\(trialDays)", selected.price, selectedPlan.periodName)
        } else if let selected, let intro = selected.introPrice {
            finePrint.text = "\(L10n.paywallOptionIntro(intro, selectedPlan.periodName)). \(L10n.paywallOptionIntroSubtitle(selected.price, selectedPlan.periodName))."
        } else if let selected {
            finePrint.text = L10n.paywallNoteNoTrial(selected.price, selectedPlan.periodName)
        } else {
            finePrint.text = " "
        }

        // Wording variants (remote `continue_button_version` / `title_trial_version`).
        if config.isTrialAwareContinue {
            continueButton.setTitle(trialDays > 0 ? L10n.paywallContinueTrial : L10n.paywallContinueSubscribe)
        }
        titleLabel.text = (config.isTrialAwareTitle && trialDays > 0) ? L10n.paywallTitleTrial("\(trialDays)") : L10n.paywallTitle
    }

    private func openWeb(_ string: String) {
        guard let url = URL(string: string), url.scheme?.hasPrefix("http") == true else { return }
        present(SFSafariViewController(url: url), animated: true)
    }
}

// MARK: - Plan card

final class PlanCardView: UIControl {
    var onTap: (() -> Void)?

    private let borderView = UIView()
    private let radio = UIView()
    private let check = UIImageView(image: Asset.Assets.App.icPaywallCheckWhite.image.withRenderingMode(.alwaysTemplate))
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let badge = GradientView(colors: AppColors.gradientBestOffer)
    private let badgeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.cornerRadius = 26
        borderView.layer.cornerRadius = 26
        borderView.layer.borderWidth = 1.5
        borderView.isUserInteractionEnabled = false
        addSubview(borderView)
        borderView.snp.makeConstraints { $0.edges.equalToSuperview() }
        radio.layer.cornerRadius = 12
        radio.layer.borderWidth = 1.5
        radio.isUserInteractionEnabled = false
        check.tintColor = .white
        check.contentMode = .scaleAspectFit
        radio.addSubview(check)
        check.snp.makeConstraints { $0.edges.equalToSuperview().inset(5) }

        titleLabel.font = AppFonts.medium(14)
        titleLabel.textColor = AppColors.textPrimary
        subtitleLabel.font = AppFonts.regular(11)
        subtitleLabel.textColor = AppColors.textSecondary
        subtitleLabel.isHidden = true
        let text = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        text.axis = .vertical
        text.spacing = 1
        text.isUserInteractionEnabled = false

        addSubview(radio)
        addSubview(text)
        radio.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        text.snp.makeConstraints { make in
            make.leading.equalTo(radio.snp.trailing).offset(9)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(11)
        }
        snp.makeConstraints { $0.height.greaterThanOrEqualTo(52) }

        badge.layer.cornerRadius = 10
        badge.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner, .layerMaxXMaxYCorner]
        badge.clipsToBounds = true
        badgeLabel.font = AppFonts.semibold(10)
        badgeLabel.textColor = .white
        badgeLabel.textAlignment = .center
        badge.addSubview(badgeLabel)
        badgeLabel.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)) }
        addSubview(badge)
        badge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(24)
            make.centerY.equalTo(snp.top)
            make.height.equalTo(20)
        }
        badge.isHidden = true
        clipsToBounds = false
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        setSelected(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onTap?() }

    func configure(title: String, subtitle: String?, badge text: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        badgeLabel.text = text
        badge.isHidden = text == nil
    }

    func setSelected(_ selected: Bool) {
        backgroundColor = selected ? AppColors.primarySoft : UIColor.white.withAlphaComponent(0.6)
        borderView.layer.borderColor = (selected ? AppColors.primary : AppColors.border).cgColor
        radio.backgroundColor = selected ? AppColors.primary : .clear
        radio.layer.borderColor = (selected ? AppColors.primary : AppColors.border).cgColor
        check.isHidden = !selected
        titleLabel.font = selected ? AppFonts.medium(14) : AppFonts.regular(14)
    }
}
