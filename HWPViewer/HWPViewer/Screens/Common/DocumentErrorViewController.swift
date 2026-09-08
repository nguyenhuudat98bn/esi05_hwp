//
//  DocumentErrorViewController.swift
//  HWPViewer
//
//  Shared document error screen (Figma 19108-24632 "Lỗi"): X header, document-with-warning
//  illustration, "Oops! Something went wrong", "Back to Home" pill.
//
//  Used by two flows, which the design covers with the same frame:
//   - convert failed (G7): replaces the converting popup's caller in the stack;
//   - opening a broken file: replaces the viewer, so back does not land on it again.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class DocumentErrorViewController: AppBaseViewController {
    init(place: SPNAdPlace = .convert) {
        super.init(place: place, navigationConfigs: SPNNavigationConfiguration(
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

        // Illustration 100×100 (Figma 99.63) + message 224pt wide, 24 apart.
        let illustration = UIImageView(image: Asset.Assets.App.imgConvertError.image)
        illustration.contentMode = .scaleAspectFit
        let messageLabel = UILabel()
        messageLabel.text = L10n.convertErrorMessage
        messageLabel.font = AppFonts.regular(14)
        messageLabel.textColor = AppColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0

        let backButton = UIButton(type: .system)
        backButton.setTitle(L10n.convertErrorBackHome, for: .normal)
        backButton.titleLabel?.font = AppFonts.semibold(16)
        backButton.setTitleColor(AppColors.textOnPrimary, for: .normal)
        backButton.backgroundColor = AppColors.primary
        backButton.layer.cornerRadius = AppMetrics.buttonRadius

        let stack = UIStackView(arrangedSubviews: [illustration, messageLabel, backButton])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 24
        stack.setCustomSpacing(28, after: messageLabel)
        content.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            // Figma centers the column on the whole screen (top = 50% − 39.5), not on the area below the header.
            make.centerY.equalTo(view.snp.centerY).offset(-40)
            make.leading.greaterThanOrEqualToSuperview().inset(AppMetrics.screenPadding)
        }
        illustration.snp.makeConstraints { $0.size.equalTo(100) }
        messageLabel.snp.makeConstraints { $0.width.equalTo(224) }
        backButton.snp.makeConstraints { make in
            make.width.equalTo(252)
            make.height.equalTo(AppMetrics.buttonHeight)
        }

        backButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.navigationController?.popToRootViewController(animated: true) }
            .store(in: &cancellables)
    }
}
