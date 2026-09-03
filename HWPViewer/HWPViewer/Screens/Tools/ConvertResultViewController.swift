//
//  ConvertResultViewController.swift
//  HWPViewer
//
//  G5: green check, "Convert HWP Successfully", Name / Size / Path card, Back Home / Open.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class ConvertResultViewController: AppBaseViewController {
    private let outputURL: URL
    private let size: Int64

    init(outputURL: URL, size: Int64) {
        self.outputURL = outputURL
        self.size = size
        super.init(place: .convert, navigationConfigs: SPNNavigationConfiguration(title: "", hasBackButton: false, backgroundColor: AppColors.background))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.isHidden = true
        let content = UIView()
        containerStackView.addArrangedSubview(content)
        containerStackView.addArrangedSubview(nativeAdSlot)

        let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        check.tintColor = AppColors.success
        check.contentMode = .scaleAspectFit
        let title = UILabel()
        title.text = L10n.convertSuccessTitle
        title.font = AppFonts.bold(20)
        title.textColor = AppColors.textPrimary
        title.textAlignment = .center

        let card = UIView()
        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = AppMetrics.cardRadius
        let rows = UIStackView(arrangedSubviews: [
            infoRow(L10n.convertSuccessName, outputURL.lastPathComponent),
            infoRow(L10n.convertSuccessSize, ByteCountFormatter.string(fromByteCount: size, countStyle: .file)),
            infoRow(L10n.convertSuccessPath, "Documents/\(outputURL.lastPathComponent)"),
        ])
        rows.axis = .vertical
        rows.spacing = 12
        card.addSubview(rows)
        rows.snp.makeConstraints { $0.edges.equalToSuperview().inset(16) }

        let stack = UIStackView(arrangedSubviews: [check, title, card])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 16
        stack.setCustomSpacing(24, after: title)
        content.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(60)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }
        check.snp.makeConstraints { $0.height.equalTo(88) }

        let backButton = UIButton(type: .system)
        backButton.setTitle(L10n.convertSuccessBackHome, for: .normal)
        backButton.titleLabel?.font = AppFonts.semibold(15)
        backButton.setTitleColor(AppColors.primary, for: .normal)
        backButton.backgroundColor = AppColors.primarySoft
        backButton.layer.cornerRadius = AppMetrics.buttonRadius
        let openButton = UIButton(type: .system)
        openButton.setTitle(L10n.convertSuccessOpen, for: .normal)
        openButton.titleLabel?.font = AppFonts.semibold(15)
        openButton.setTitleColor(.white, for: .normal)
        openButton.backgroundColor = AppColors.primary
        openButton.layer.cornerRadius = AppMetrics.buttonRadius
        let buttons = UIStackView(arrangedSubviews: [backButton, openButton])
        buttons.axis = .horizontal
        buttons.spacing = 12
        buttons.distribution = .fillEqually
        view.addSubview(buttons)
        buttons.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            make.height.equalTo(AppMetrics.buttonHeight)
        }
        backButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.navigationController?.popToRootViewController(animated: true) }
            .store(in: &cancellables)
        openButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.openResult() }
            .store(in: &cancellables)
        setupAdvertiser(on: .convert)
    }

    private func infoRow(_ key: String, _ value: String) -> UIView {
        let keyLabel = UILabel()
        keyLabel.text = key
        keyLabel.font = AppFonts.regular(13)
        keyLabel.textColor = AppColors.textSecondary
        let valueLabel = UILabel()
        valueLabel.text = value
        valueLabel.font = AppFonts.medium(13)
        valueLabel.textColor = AppColors.textPrimary
        valueLabel.textAlignment = .right
        valueLabel.lineBreakMode = .byTruncatingMiddle
        let row = UIStackView(arrangedSubviews: [keyLabel, valueLabel])
        row.axis = .horizontal
        row.spacing = 12
        keyLabel.setContentHuggingPriority(.required, for: .horizontal)
        return row
    }

    private func openResult() {
        guard let item = FileStore.shared.item(at: outputURL) else { return }
        FileStore.shared.markOpened(item.url)
        let viewer = HwpViewerViewController(item: item, startInEditMode: false)
        var stack = navigationController?.viewControllers ?? []
        stack.removeAll { $0 === self }
        stack.append(viewer)
        navigationController?.setViewControllers(stack, animated: true)
    }
}
