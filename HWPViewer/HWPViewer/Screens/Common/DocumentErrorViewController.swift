//
//  DocumentErrorViewController.swift
//  HWPViewer
//
//  Shared document error screen (Figma 19108-24632 "Lỗi"): X header, document-with-warning
//  illustration, "Oops! Something went wrong", "Back to Home" pill.
//
//  Used by three flows:
//   - convert failed (G7): replaces the converting popup's caller in the stack;
//   - opening a broken file: replaces the viewer, so back does not land on it again;
//   - OCR failed (Figma 6987:129718 "Lỗi"): torn-page art, "An unexpected error occurred.",
//     "Try Again", hairline under the header (`Content.ocr`).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class DocumentErrorViewController: AppBaseViewController {
    struct Content {
        let illustration: UIImage
        let message: String
        let actionTitle: String
        let showsDivider: Bool
        /// Vertical offset of the centred column from the screen centre.
        let centerOffset: CGFloat

        static var document: Content {
            Content(illustration: Asset.Assets.App.imgConvertError.image, message: L10n.convertErrorMessage,
                    actionTitle: L10n.convertErrorBackHome, showsDivider: false, centerOffset: -40)
        }

        static var ocr: Content {
            Content(illustration: Asset.Assets.App.imgOcrError.image, message: L10n.ocrErrorMessage,
                    actionTitle: L10n.ocrTryAgain, showsDivider: true, centerOffset: -46)
        }
    }

    private let content: Content
    /// Button action; nil → back to the file list ("Back to Home").
    var onAction: (() -> Void)?

    init(place: SPNAdPlace = .convert, content: Content = .document) {
        self.content = content
        super.init(place: place, navigationConfigs: SPNNavigationConfiguration(
            title: "", hasBackButton: true, backIcon: Asset.Assets.App.icEditorCloseX.image,
            tintColor: AppColors.textPrimary, backgroundColor: AppColors.background
        ))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        // No divider under the header — 19108-24632 has the X sitting on a plain background.
        navigationView.snp.updateConstraints { $0.height.equalTo(AppMetrics.navHeight) }

        if content.showsDivider { MergeSplitUI.addNavHairline(to: navigationView) }
        let container = UIView()
        containerStackView.addArrangedSubview(container)

        // Illustration 100×100 (Figma 99.63) + message 224pt wide, 24 apart.
        let illustration = UIImageView(image: content.illustration)
        illustration.contentMode = .scaleAspectFit
        let messageLabel = UILabel()
        messageLabel.text = content.message
        messageLabel.font = AppFonts.regular(14)
        messageLabel.textColor = AppColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let backButton = UIButton(type: .system)
        backButton.setTitle(content.actionTitle, for: .normal)
        backButton.titleLabel?.font = AppFonts.semibold(16)
        backButton.setTitleColor(AppColors.textOnPrimary, for: .normal)
        backButton.backgroundColor = AppColors.primary
        backButton.layer.cornerRadius = AppMetrics.buttonRadius

        let stack = UIStackView(arrangedSubviews: [illustration, messageLabel, backButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.setCustomSpacing(28, after: messageLabel)
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            // Figma centers the column on the whole screen (top = 50% − 39.5), not on the area below the header.
            make.centerY.equalTo(view.snp.centerY).offset(content.centerOffset)
            make.leading.greaterThanOrEqualToSuperview().inset(AppMetrics.screenPadding)
        }
        illustration.snp.makeConstraints { $0.size.equalTo(100) }
        messageLabel.snp.makeConstraints { $0.width.equalTo(224) }
        backButton.snp.makeConstraints { make in
            make.width.equalTo(252)
            make.height.equalTo(AppMetrics.buttonHeight)
        }

        backButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                if let onAction { onAction() } else { goToAllFiles() }
            }
            .store(in: &cancellables)
    }
}
