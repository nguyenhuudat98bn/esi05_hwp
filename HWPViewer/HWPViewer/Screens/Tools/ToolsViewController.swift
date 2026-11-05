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
            .sink { [weak self] _ in self?.presentPaywall(at: .toolsCrown) }
            .store(in: &cancellables)

        // Scrolls when the cards do not fit (4"/4.7" phones, or once the native ad below takes its
        // height): a fixed grid would run under the ad slot / tab bar and cover the ad.
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false
        containerStackView.addArrangedSubview(scrollView)
        containerStackView.addArrangedSubview(nativeAdSlot)

        let grid = UIStackView()
        grid.axis = .vertical
        grid.spacing = 12
        grid.distribution = .fillEqually
        var pairs: [[ToolKind]] = [[.editHwp, .pdfToHwp], [.docToHwp, .print], [.mergeHwp, .splitHwp]]
        // OCR reads Korean only where Vision can (iOS 16+); elsewhere Hangul would come out as noise.
        if OcrTextRecognizer.supportsKorean { pairs.append([.ocr]) }
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
            // A row with a single card keeps the card half-width, on the left (Figma 7011:115388).
            if pair.count == 1 { row.addArrangedSubview(UIView()) }
            grid.addArrangedSubview(row)
        }
        scrollView.addSubview(grid)
        grid.snp.makeConstraints { make in
            make.top.equalTo(scrollView.contentLayoutGuide).inset(8)
            make.bottom.equalTo(scrollView.contentLayoutGuide).inset(16)
            make.leading.trailing.equalTo(scrollView.contentLayoutGuide).inset(AppMetrics.screenPadding)
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-2 * AppMetrics.screenPadding)
            make.height.equalTo(CGFloat(pairs.count - 1) * 12 + CGFloat(pairs.count) * 88)
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
        guard let navigationController else { return }
        switch tool {
        case .mergeHwp: MergeSplitFlow.startMerge(on: navigationController)
        case .splitHwp: MergeSplitFlow.startSplit(on: navigationController)
        case .ocr: OcrFlow.start(from: self)
        default: navigationController.pushViewController(SelectFileViewController(tool: tool), animated: true)
        }
    }
}
