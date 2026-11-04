//
//  CameraPermissionPopupViewController.swift
//  HWPViewer
//
//  "Allow Camera Access" (Figma 7011:116578): white card 328pt / radius 16 on the dimmed screen —
//  68pt #D1E9FF circle with the camera glyph, title 18 semibold, message 14 #717680, three numbered
//  steps 16pt, "Open Settings" pill (opens the app's Settings page). Tap outside to close.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

final class CameraPermissionPopupViewController: UIViewController {
    private var cancellables = Set<AnyCancellable>()

    init() {
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        let dim = UIControl()
        dim.backgroundColor = AppColors.dim
        view.addSubview(dim)
        dim.snp.makeConstraints { $0.edges.equalToSuperview() }
        dim.controlEventPublisher(for: .touchUpInside)
            .sink { [weak self] _ in self?.dismiss(animated: true) }
            .store(in: &cancellables)

        let card = UIView()
        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = 16
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }

        let circle = UIView()
        circle.backgroundColor = AppColors.primaryLight
        circle.layer.cornerRadius = 34
        let icon = UIImageView(image: Asset.Assets.App.icPermissionCamera.image)
        circle.addSubview(icon)
        circle.snp.makeConstraints { $0.size.equalTo(68) }
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }

        let title = MergeSplitUI.label(L10n.ocrPermissionTitle, font: AppFonts.semibold(18), color: .black, lines: 0)
        let message = MergeSplitUI.label(L10n.ocrPermissionMessage, font: AppFonts.regular(14), color: AppColors.textSecondary, lines: 0)
        [title, message].forEach { $0.textAlignment = .center }
        let steps = UIStackView(arrangedSubviews: [L10n.ocrPermissionStep1, L10n.ocrPermissionStep2, L10n.ocrPermissionStep3]
            .enumerated().map { index, text in Self.step(index + 1, text) })
        steps.axis = .vertical
        steps.spacing = 8

        let header = UIStackView(arrangedSubviews: [circle, title, message])
        header.axis = .vertical
        header.alignment = .center
        header.spacing = 16
        header.setCustomSpacing(12, after: title)
        title.snp.makeConstraints { $0.width.equalTo(header) }
        message.snp.makeConstraints { $0.width.equalTo(header) }

        let openSettings = MergeSplitUI.primaryButton(L10n.ocrPermissionOpenSettings)
        openSettings.titleLabel?.font = AppFonts.semibold(16)
        openSettings.tapPublisher
            .sink { [weak self] _ in
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                self?.dismiss(animated: true)
            }
            .store(in: &cancellables)

        let stack = UIStackView(arrangedSubviews: [header, steps, openSettings])
        stack.axis = .vertical
        stack.spacing = 16
        stack.setCustomSpacing(32, after: steps)
        card.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(32)
            make.bottom.equalToSuperview().inset(24)
            make.leading.trailing.equalToSuperview().inset(15)
        }
        view.accessibilityViewIsModal = true
    }

    /// "1.  Tap on Open settings" — number column then text, 16pt regular black.
    private static func step(_ number: Int, _ text: String) -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        let paragraph = NSMutableParagraphStyle()
        paragraph.headIndent = 24
        paragraph.tabStops = [NSTextTab(textAlignment: .left, location: 24)]
        label.attributedText = NSAttributedString(string: "\(number).\t\(text)", attributes: [
            .font: AppFonts.regular(16), .foregroundColor: UIColor.black, .kern: 0.1, .paragraphStyle: paragraph,
        ])
        return label
    }
}
