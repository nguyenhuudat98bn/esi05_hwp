//
//  AppAlertViewController.swift
//  HWPViewer
//
//  Custom popup (Figma D1 "You're Offline", F7 "Save Changes?", E3 "Delete File?" 19108-24877):
//  white card, icon, title, message, two pill buttons.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

struct AppAlertAction {
    enum Style { case primary, secondary, destructive }
    let title: String
    let style: Style
    let handler: (() -> Void)?

    init(title: String, style: Style = .primary, handler: (() -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }
}

final class AppAlertViewController: UIViewController {
    private let icon: UIImage?
    private let iconTint: UIColor?
    private let iconHeight: CGFloat
    /// When set, the icon sits centered inside a 60pt circle of this color (Figma "Delete File?" popup).
    private let iconCircleColor: UIColor?
    private let titleText: String
    private let messageText: String?
    private let actions: [AppAlertAction]
    private var cancellables = Set<AnyCancellable>()

    private let card = UIView()
    private let dimView = UIView()

    init(icon: UIImage?, iconTint: UIColor? = nil, iconHeight: CGFloat = 64, iconCircleColor: UIColor? = nil, title: String, message: String?, actions: [AppAlertAction]) {
        self.icon = icon
        self.iconTint = iconTint
        self.iconHeight = iconHeight
        self.iconCircleColor = iconCircleColor
        self.titleText = title
        self.messageText = message
        self.actions = actions
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dimView.backgroundColor = AppColors.dim
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = AppMetrics.popupRadius
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }

        let iconView = UIImageView(image: icon)
        iconView.contentMode = .scaleAspectFit
        iconView.tintColor = iconTint ?? AppColors.primary
        iconView.isHidden = icon == nil

        // Header slot: either the bare icon, or the icon centered in a tinted circle.
        let iconSlot: UIView
        if let iconCircleColor {
            let circle = UIView()
            circle.backgroundColor = iconCircleColor
            circle.layer.cornerRadius = AppMetrics.popupIconCircle / 2
            circle.addSubview(iconView)
            iconView.snp.makeConstraints { make in
                make.center.equalToSuperview()
                make.size.equalTo(iconHeight)
            }
            let holder = UIView()
            holder.addSubview(circle)
            circle.snp.makeConstraints { make in
                make.top.bottom.centerX.equalToSuperview()
                make.size.equalTo(AppMetrics.popupIconCircle)
            }
            iconSlot = holder
        } else {
            iconSlot = iconView
        }

        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = AppFonts.semibold(18)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        let messageLabel = UILabel()
        messageLabel.text = messageText
        messageLabel.font = AppFonts.regular(14)
        messageLabel.textColor = AppColors.textSecondary
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
        messageLabel.isHidden = (messageText ?? "").isEmpty

        let buttons = actions.enumerated().map { index, action -> UIButton in
            let button = UIButton(type: .system)
            button.setTitle(action.title, for: .normal)
            button.titleLabel?.font = AppFonts.semibold(15)
            button.layer.cornerRadius = 24
            button.titleLabel?.font = AppFonts.semibold(16)
            switch action.style {
            case .primary:
                button.backgroundColor = AppColors.primary
                button.setTitleColor(.white, for: .normal)
            case .destructive:
                button.backgroundColor = AppColors.danger
                button.setTitleColor(.white, for: .normal)
            case .secondary:
                button.backgroundColor = AppColors.surfaceMuted
                button.setTitleColor(AppColors.textPrimary, for: .normal)
            }
            button.snp.makeConstraints { $0.height.equalTo(48) }
            button.tapPublisher
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in self?.finish(with: index) }
                .store(in: &cancellables)
            return button
        }
        let buttonStack = UIStackView(arrangedSubviews: buttons)
        buttonStack.axis = .horizontal
        buttonStack.spacing = 12
        buttonStack.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [iconSlot, titleLabel, messageLabel, buttonStack])
        stack.axis = .vertical
        stack.spacing = 12
        stack.alignment = .fill
        stack.setCustomSpacing(32, after: messageLabel)
        stack.setCustomSpacing(16, after: iconSlot)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 32, left: 15, bottom: 24, right: 15)) }
        if iconCircleColor == nil {
            iconView.snp.makeConstraints { $0.height.equalTo(iconHeight) }
        }

        let closeButton = UIButton(type: .system)
        closeButton.setImage(Asset.Assets.App.icCancelX.image.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = AppColors.textSecondary
        card.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(10)
            make.size.equalTo(28)
        }
        closeButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.dismiss(animated: true) }
            .store(in: &cancellables)
    }

    private func finish(with index: Int) {
        let action = actions[index]
        dismiss(animated: true) { action.handler?() }
    }
}

// MARK: - Presets

enum OfflinePopup {
    @MainActor
    static func present(from presenter: UIViewController, retry: @escaping () -> Void) {
        let alert = AppAlertViewController(
            icon: Asset.Assets.App.imgOffline.image,
            iconHeight: 80,
            title: L10n.popupOfflineTitle,
            message: L10n.popupOfflineMessage,
            actions: [
                AppAlertAction(title: L10n.popupLater, style: .secondary),
                AppAlertAction(title: L10n.popupTryAgain, style: .primary, handler: retry),
            ]
        )
        presenter.present(alert, animated: true)
    }
}

enum DeleteConfirmPopup {
    @MainActor
    static func present(from presenter: UIViewController, fileName: String, confirm: @escaping () -> Void) {
        // Figma 19108-24877: 36pt material delete glyph in a 60pt #FFEBEB circle, Cancel / Delete pills.
        let alert = AppAlertViewController(
            icon: Asset.Assets.App.icMoreDelete.image.withRenderingMode(.alwaysTemplate),
            iconTint: AppColors.danger,
            iconHeight: 36,
            iconCircleColor: AppColors.dangerSoft,
            title: L10n.popupDeleteTitle,
            message: L10n.popupDeleteMessage,
            actions: [
                AppAlertAction(title: L10n.popupCancel, style: .secondary),
                AppAlertAction(title: L10n.popupDelete, style: .destructive, handler: confirm),
            ]
        )
        presenter.present(alert, animated: true)
    }
}

enum SaveChangesPopup {
    @MainActor
    static func present(from presenter: UIViewController, cancel: @escaping () -> Void, save: @escaping () -> Void) {
        let alert = AppAlertViewController(
            icon: Asset.Assets.App.imgSaveChangesFolder.image,
            iconHeight: 120,
            title: L10n.popupSaveChangesTitle,
            message: L10n.popupSaveChangesMessage,
            actions: [
                AppAlertAction(title: L10n.popupCancel, style: .secondary, handler: cancel),
                AppAlertAction(title: L10n.popupSave, style: .primary, handler: save),
            ]
        )
        presenter.present(alert, animated: true)
    }
}

enum ErrorPopup {
    @MainActor
    static func present(from presenter: UIViewController, message: String, onDismiss: (() -> Void)? = nil) {
        let alert = AppAlertViewController(
            icon: UIImage(systemName: "exclamationmark.triangle.fill"),
            iconTint: AppColors.accentOrange,
            title: L10n.popupErrorTitle,
            message: message,
            actions: [AppAlertAction(title: L10n.popupOk, style: .primary, handler: onDismiss)]
        )
        presenter.present(alert, animated: true)
    }
}
