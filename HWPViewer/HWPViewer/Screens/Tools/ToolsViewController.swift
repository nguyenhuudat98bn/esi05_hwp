//
//  ToolsViewController.swift
//  HWPViewer
//
//  Tools tab (Figma B8/G1): 2×2 gradient cards → Select File.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class ToolsViewController: AppBaseViewController {
    /// Crown in the navigation bar → paywall (same as Home); hidden once premium.
    private let premiumButton = UIButton(type: .system)

    init() {
        super.init(place: .tools, navigationConfigs: SPNNavigationConfiguration(
            title: L10n.toolsTitle, hasBackButton: false,
            titleFont: AppFonts.bold(22), titleColor: AppColors.textPrimary, backgroundColor: AppColors.background
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var hidesBottomBarByDefault: Bool { false }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.snp.updateConstraints { $0.height.equalTo(52) }
        premiumButton.setImage(Asset.Assets.App.icCrown.image.withRenderingMode(.alwaysOriginal), for: .normal)
        premiumButton.isHidden = isPremium
        navigationView.addSubview(premiumButton)
        premiumButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(40)
        }
        premiumButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.presentPaywall() }
            .store(in: &cancellables)

        let content = UIView()
        containerStackView.addArrangedSubview(content)
        containerStackView.addArrangedSubview(nativeAdSlot)

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 12
        grid.distribution = .fillEqually
        let pairs: [[ToolKind]] = [[.editHwp, .pdfToHwp], [.docToHwp, .print]]
        for pair in pairs {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 12
            row.distribution = .fillEqually
            for tool in pair {
                let card = GradientCardView(tool: tool)
                card.tapPublisher.receive(on: DispatchQueue.main)
                    .sink { [weak self] _ in self?.open(tool) }
                    .store(in: &cancellables)
                row.addArrangedSubview(card)
            }
            grid.addArrangedSubview(row)
        }
        content.addSubview(grid)
        grid.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.height.equalTo(12 + 2 * 88)
        }
        setupAdvertiser(on: .tools)
    }

    override func premiumStatusDidChange() {
        super.premiumStatusDidChange()
        premiumButton.isHidden = isPremium
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Remote `show_paywall_at` contains "tools" → paywall on the first visit of the session (percent/max-gated).
        PaywallPresenter.shared.presentIfAllowed(at: .tools, from: self)
    }

    private func open(_ tool: ToolKind) {
        navigationController?.pushViewController(SelectFileViewController(tool: tool), animated: true)
    }
}
