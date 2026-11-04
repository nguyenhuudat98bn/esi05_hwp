//
//  MergeSplitUIKit.swift
//  HWPViewer
//
//  Building blocks shared by the Merge / Split HWP screens (Figma "Merge HWP" 6978:109459,
//  "Split HWP" 6978:110902): nav config with hairline, search pill, full-width primary button
//  (blue / gray disabled), the white bottom action bar, the nav select-all checkbox.
//

import UIKit
import SnapKit
import SPNComponent

/// Screens of a Tools flow (picker → work screen). The result screen drops them from the stack so
/// leaving the opened document returns to Tools instead of back into a finished flow.
protocol ToolFlowScreen: UIViewController {}

enum MergeSplitUI {
    /// Back chevron + 18pt medium title (Figma PageHeader_ViewMode).
    static func navigationConfig(title: String) -> SPNNavigationConfiguration {
        SPNNavigationConfiguration(
            title: title, hasBackButton: true, backIcon: Asset.Assets.App.icAngleLeft.image,
            titleFont: AppFonts.medium(18), titleColor: AppColors.textPrimary,
            tintColor: AppColors.textPrimary, backgroundColor: AppColors.background
        )
    }

    /// 1pt #ECECED line under the nav bar (Figma Header border-b).
    static func addNavHairline(to navigationView: UIView) {
        let line = UIView()
        line.backgroundColor = AppColors.divider
        navigationView.addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
    }

    /// 48pt full-width pill: #2E90FA when enabled, #CECFD2 when disabled, white 16pt medium title.
    static func primaryButton(_ title: String) -> PrimaryPillButton {
        let button = PrimaryPillButton(type: .custom)
        button.setTitle(title, for: .normal)
        return button
    }

    /// White bar pinned to the bottom (safe area), 1pt #F0F0F1 top hairline, 16pt padding.
    @discardableResult
    static func bottomBar(in view: UIView, content: UIView) -> UIView {
        let bar = UIView()
        bar.backgroundColor = AppColors.background
        let line = UIView()
        line.backgroundColor = AppColors.bottomBarBorder
        bar.addSubview(line)
        bar.addSubview(content)
        view.addSubview(bar)
        line.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        bar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
        }
        return bar
    }

    /// Height the bottom bar occupies above the safe area (16 + 48 + 16), for content insets.
    static let bottomBarHeight: CGFloat = 16 + AppMetrics.buttonHeight + 16

    static func label(_ text: String? = nil, font: UIFont, color: UIColor = AppColors.textPrimary, lines: Int = 1) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        return label
    }
}

/// Primary CTA of the Merge / Split screens; background follows `isEnabled`.
final class PrimaryPillButton: UIButton {
    override init(frame: CGRect) {
        super.init(frame: frame)
        titleLabel?.font = AppFonts.medium(16)
        setTitleColor(.white, for: .normal)
        setTitleColor(.white, for: .disabled)
        layer.cornerRadius = AppMetrics.buttonHeight / 2
        clipsToBounds = true
        snp.makeConstraints { $0.height.equalTo(AppMetrics.buttonHeight) }
        updateBackground()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var isEnabled: Bool {
        didSet { updateBackground() }
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    private func updateBackground() {
        backgroundColor = isEnabled ? AppColors.primary : AppColors.buttonDisabled
    }
}

/// Rounded #ECECED search pill (Figma 6978:107096): magnifier 24pt, 14pt field, "Search files...".
final class FileSearchField: UIView {
    let textField = UITextField()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.surfaceMuted
        layer.cornerRadius = 20
        let icon = UIImageView(image: Asset.Assets.App.icSearch.image.withRenderingMode(.alwaysTemplate))
        icon.tintColor = AppColors.textTertiary
        icon.contentMode = .scaleAspectFit
        textField.font = AppFonts.regular(14)
        textField.textColor = AppColors.textPrimary
        textField.attributedPlaceholder = NSAttributedString(
            string: L10n.searchPlaceholder,
            attributes: [.foregroundColor: AppColors.textTertiary, .font: AppFonts.regular(14)]
        )
        textField.returnKeyType = .search
        textField.clearButtonMode = .whileEditing
        textField.autocorrectionType = .no
        addSubview(icon)
        addSubview(textField)
        snp.makeConstraints { $0.height.equalTo(40) }
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        textField.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}

/// 24pt nav checkbox (select all): outline when off, blue filled when on.
final class SelectAllButton: UIButton {
    var isOn = false {
        didSet { apply() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        accessibilityLabel = "Select all"
        apply()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// Pins the button to the trailing edge of `navigationView`, centred on its title.
    func install(in navigationView: SPNNavigationView) {
        navigationView.addSubview(self)
        snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(6)
            make.centerY.equalTo(navigationView.titleLabel)
            make.size.equalTo(44)
        }
    }

    private func apply() {
        let image = isOn ? Asset.Assets.App.icSelectAllOn.image : Asset.Assets.App.icSelectAllOff.image
        setImage(image.withRenderingMode(.alwaysOriginal), for: .normal)
        accessibilityTraits = isOn ? [.button, .selected] : .button
    }
}
