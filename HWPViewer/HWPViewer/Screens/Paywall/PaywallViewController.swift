//
//  PaywallViewController.swift
//  HWPViewer
//
//  Paywall (Figma H2): header art + hero, X / Restore, "Go Premium with HWP Pro", PRO/BASIC table,
//  fine print, two plan cards (monthly intro / yearly trial "Best Offer"), CONTINUE, Terms | Privacy.
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

    private var products: [Product] = []
    private var selectedPlan: PaywallPlan = .yearly

    // MARK: - Controls
    private let headerImage = UIImageView(image: Asset.Assets.App.imgPaywallHeaderBg.image)
    private let heroImage = UIImageView(image: Asset.Assets.App.imgPaywallHero.image)
    private let closeButton = UIButton(type: .system)
    private let restoreButton = UIButton(type: .system)
    private let finePrint = UILabel()
    private let monthlyCard = PlanCardView()
    private let yearlyCard = PlanCardView()
    private let continueButton = GradientButton(title: L10n.paywallContinue, colors: AppColors.gradientContinue)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupViews()
        bind()
        fetchSubject.send()
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

        let title = UILabel()
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

        let plans = UIStackView(arrangedSubviews: [monthlyCard, yearlyCard])
        plans.axis = .vertical
        plans.spacing = 16
        monthlyCard.onTap = { [weak self] in self?.select(.monthly) }
        yearlyCard.onTap = { [weak self] in self?.select(.yearly) }

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

        select(.yearly)
        updateTexts()
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
                guard let self else { return }
                buySubject.send(selectedPlan.identifier)
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
        monthlyCard.setSelected(plan == .monthly)
        yearlyCard.setSelected(plan == .yearly)
        updateTexts()
    }

    private func updateTexts() {
        let monthly = products.first { $0.plan == .monthly }
        let yearly = products.first { $0.plan == .yearly }

        if let monthly {
            let intro = monthly.introPrice ?? monthly.price
            monthlyCard.configure(title: L10n.paywallOptionFirstMonth(intro), subtitle: monthly.introPrice != nil ? L10n.paywallOptionFirstMonthSubtitle(monthly.price) : nil, badge: nil)
        } else {
            monthlyCard.configure(title: L10n.paywallOptionFirstMonth("—"), subtitle: nil, badge: nil)
        }
        let trialTitle = (yearly?.trialDays ?? 0) > 0 ? L10n.paywallOptionTrialEnabled : L10n.paywallOptionTrialDisabled
        yearlyCard.configure(title: trialTitle, subtitle: nil, badge: L10n.paywallOptionBestOffer)

        switch selectedPlan {
        case .yearly:
            if let yearly, yearly.trialDays > 0 {
                finePrint.text = L10n.paywallNoteTrial("\(yearly.trialDays)", yearly.price)
            } else if let yearly {
                finePrint.text = L10n.paywallNoteNoTrial(yearly.price)
            } else {
                finePrint.text = " "
            }
        case .monthly:
            if let monthly, let intro = monthly.introPrice {
                finePrint.text = "\(L10n.paywallOptionFirstMonth(intro)). \(L10n.paywallOptionFirstMonthSubtitle(monthly.price))."
            } else if let monthly {
                finePrint.text = L10n.paywallOptionFirstMonthSubtitle(monthly.price)
            } else {
                finePrint.text = " "
            }
        }
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

// MARK: - Gradient button

final class GradientButton: UIControl {
    private let gradient = CAGradientLayer()
    private let label = UILabel()

    init(title: String, colors: [UIColor]) {
        super.init(frame: .zero)
        layer.cornerRadius = 23
        clipsToBounds = true
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradient)
        label.text = title
        label.font = AppFonts.bold(16)
        label.textColor = .white
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        let arrow = UIImageView(image: Asset.Assets.App.icPaywallArrowRight.image.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = .white
        arrow.contentMode = .scaleAspectFit
        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
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
