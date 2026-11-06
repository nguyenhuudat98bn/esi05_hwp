//
//  OcrCameraPermissionView.swift
//  HWPViewer
//
//  Shown in the scanner's preview area while camera access is not granted (ESI05-73): closing the
//  "Allow Camera Access" popup used to leave a black, dead preview. Same icon and wording as the
//  popup (7011:116498), light on the dark scanner, with "Open Settings". Close and Photos in the
//  bottom panel stay usable underneath.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

final class OcrCameraPermissionView: UIView {
    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black

        // Same badge as the popup: 40pt camera glyph in a 68pt light-blue circle.
        let circle = UIView()
        circle.backgroundColor = AppColors.primaryLight
        circle.layer.cornerRadius = 34
        let icon = UIImageView(image: Asset.Assets.App.icPermissionCamera.image)
        icon.contentMode = .scaleAspectFit
        circle.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(40)
        }
        let title = MergeSplitUI.label(L10n.ocrPermissionTitle, font: AppFonts.semibold(18), color: .white, lines: 0)
        title.textAlignment = .center
        let message = MergeSplitUI.label(L10n.ocrPermissionMessage, font: AppFonts.regular(14),
                                         color: UIColor.white.withAlphaComponent(0.7), lines: 0)
        message.textAlignment = .center
        let openSettings = MergeSplitUI.primaryButton(L10n.ocrPermissionOpenSettings)

        let stack = UIStackView(arrangedSubviews: [circle, title, message, openSettings])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.setCustomSpacing(16, after: circle)
        stack.setCustomSpacing(24, after: message)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        circle.snp.makeConstraints { $0.size.equalTo(68) }
        openSettings.snp.makeConstraints { make in
            make.height.equalTo(AppMetrics.buttonHeight)
            make.width.equalTo(stack)
        }
        openSettings.tapPublisher
            .sink { _ in
                if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
            }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
