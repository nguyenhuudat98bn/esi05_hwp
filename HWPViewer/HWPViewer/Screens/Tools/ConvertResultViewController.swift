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
        super.init(place: .convert, navigationConfigs: SPNNavigationConfiguration(
            title: "", hasBackButton: true, backIcon: Asset.Assets.App.icEditorCloseX.image,
            tintColor: AppColors.textPrimary, backgroundColor: AppColors.background
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationView.snp.updateConstraints { $0.height.equalTo(AppMetrics.navHeight) }
        let navLine = UIView()
        navLine.backgroundColor = AppColors.divider
        navigationView.addSubview(navLine)
        navLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        let content = UIView()
        containerStackView.addArrangedSubview(content)
        containerStackView.addArrangedSubview(nativeAdSlot)

        let check = SuccessBadgeView()
        let title = UILabel()
        title.text = L10n.convertSuccessTitle
        title.font = AppFonts.bold(20)
        title.textColor = AppColors.textPrimary
        title.textAlignment = .center

        let card = UIView()
        card.backgroundColor = AppColors.cardGray
        card.layer.cornerRadius = 16
        let icon = FileKindIconView()
        icon.kind = FileKind(url: outputURL) ?? .hwp
        let rows = UIStackView(arrangedSubviews: [
            infoRow(L10n.convertSuccessName, outputURL.lastPathComponent),
            infoRow(L10n.convertSuccessSize, ByteCountFormatter.string(fromByteCount: size, countStyle: .file)),
            infoRow(L10n.convertSuccessPath, "Documents/\(outputURL.lastPathComponent)"),
        ])
        rows.axis = .vertical
        rows.spacing = 4
        card.addSubview(icon)
        card.addSubview(rows)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 34, height: 40))
        }
        rows.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(12)
        }

        let stack = UIStackView(arrangedSubviews: [check, title, card])
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 24
        stack.setCustomSpacing(8, after: check)
        content.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(18)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }
        check.snp.makeConstraints { $0.height.equalTo(200) }

        let backButton = UIButton(type: .system)
        backButton.setTitle(L10n.convertSuccessBackHome, for: .normal)
        backButton.titleLabel?.font = AppFonts.semibold(15)
        backButton.setTitleColor(AppColors.textPrimary, for: .normal)
        backButton.backgroundColor = AppColors.surfaceMuted
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
        buttons.spacing = 16
        content.addSubview(buttons)
        buttons.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.top.equalTo(stack.snp.bottom).offset(24)
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

    /// "**Name:** value" on one line (Figma G5).
    private func infoRow(_ key: String, _ value: String) -> UIView {
        let label = UILabel()
        let text = NSMutableAttributedString(string: "\(key): ", attributes: [.font: AppFonts.semibold(12), .foregroundColor: AppColors.textPrimary])
        text.append(NSAttributedString(string: value, attributes: [.font: AppFonts.regular(12), .foregroundColor: AppColors.textPrimary]))
        label.attributedText = text
        label.numberOfLines = 2
        label.lineBreakMode = .byTruncatingMiddle
        return label
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

/// Green check in a circle with a dotted ring (Figma G5 "Success" illustration, drawn in code).
final class SuccessBadgeView: UIView {
    private let ring = CAShapeLayer()
    private let dots = CAShapeLayer()
    private let circle = UIView()
    private let check = UIImageView(image: UIImage(systemName: "checkmark", withConfiguration: UIImage.SymbolConfiguration(pointSize: 44, weight: .bold)))

    override init(frame: CGRect) {
        super.init(frame: frame)
        let green = AppColors.success
        ring.fillColor = UIColor.clear.cgColor
        ring.strokeColor = green.withAlphaComponent(0.6).cgColor
        ring.lineWidth = 1.5
        layer.addSublayer(ring)
        dots.fillColor = green.withAlphaComponent(0.5).cgColor
        layer.addSublayer(dots)
        circle.backgroundColor = green
        addSubview(circle)
        check.tintColor = .white
        check.contentMode = .center
        circle.addSubview(check)
        circle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(96)
        }
        check.snp.makeConstraints { $0.center.equalToSuperview() }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        circle.layer.cornerRadius = 48
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        ring.path = UIBezierPath(arcCenter: center, radius: 62, startAngle: 0, endAngle: .pi * 2, clockwise: true).cgPath
        let path = UIBezierPath()
        for i in 0..<12 {
            let angle = CGFloat(i) / 12 * .pi * 2
            let r: CGFloat = i % 3 == 0 ? 84 : 78
            let p = CGPoint(x: center.x + cos(angle) * r, y: center.y + sin(angle) * r)
            path.append(UIBezierPath(ovalIn: CGRect(x: p.x - 2.5, y: p.y - 2.5, width: 5, height: 5)))
        }
        dots.path = path.cgPath
    }
}
