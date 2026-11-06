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

    /// White bar at the bottom (button above the safe area), 1pt #F0F0F1 top hairline, 16pt padding.
    /// It is the last row of the screen's stack, so the native ad placed before it sits right above
    /// the bar and the content above shrinks for both — nothing overlaps (a floating bar covered
    /// the bottom of lists and would have covered the ad).
    @discardableResult
    static func bottomBar(in stack: UIStackView, of view: UIView, content: UIView) -> UIView {
        let bar = UIView()
        bar.backgroundColor = AppColors.background
        let line = UIView()
        line.backgroundColor = AppColors.bottomBarBorder
        bar.addSubview(line)
        bar.addSubview(content)
        stack.addArrangedSubview(bar)
        line.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(16)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
        }
        return bar
    }

    /// "No data" (Figma "Merge file/no data" 6978:108423): open-box illustration 165×140, 12pt gap,
    /// 14pt hint in #1C2A33 at 50%, centred in whatever area the view is pinned to. Long translations
    /// wrap onto a second line instead of running off the screen.
    static func emptyState(text: String) -> UIView {
        let container = UIView()
        let image = UIImageView(image: Asset.Assets.App.imgEmptyMergeFiles.image)
        image.contentMode = .scaleAspectFit
        let label = label(text, font: AppFonts.regular(14), color: AppColors.textDark.withAlphaComponent(0.5), lines: 2)
        label.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [image, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        image.snp.makeConstraints { $0.size.equalTo(CGSize(width: 165, height: 140)) }
        container.addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.greaterThanOrEqualToSuperview().inset(24)
        }
        return container
    }

    /// Figma places the illustration + hint 20pt above the middle of the *screen*, whatever sits
    /// below the list (bottom bar, ad). Call once `empty` is in the hierarchy; it still stays inside
    /// its own area, so it never runs under the ad or the bottom bar on a short screen.
    static func centerEmptyState(_ empty: UIView, onScreenOf view: UIView) {
        guard let stack = empty.subviews.first else { return }
        stack.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.trailing.greaterThanOrEqualToSuperview().inset(24)
            make.centerY.equalTo(view).offset(-20).priority(.high)
            make.top.greaterThanOrEqualToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview().inset(16)
        }
    }

    /// 52pt blue round "+" (Figma "Floating button" 6978:108525): #2E90FA, 24pt glyph.
    static func addButton(accessibilityLabel: String) -> UIButton {
        let button = UIButton(type: .custom)
        button.backgroundColor = AppColors.primary
        button.layer.cornerRadius = 25.25
        button.setImage(Asset.Assets.App.icFabAdd.image, for: .normal)
        button.accessibilityLabel = accessibilityLabel
        return button
    }

    /// The "+" sits 16pt from the right and 128pt above the safe area (48pt above where the bottom
    /// bar is), and always 48pt above the end of `list`, so a native ad under the list pushes it up
    /// instead of being covered.
    static func pinAddButton(_ button: UIButton, in view: UIView, above list: UIView) {
        button.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.size.equalTo(52)
            make.bottom.lessThanOrEqualTo(list).inset(48)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(48 + bottomBarHeight)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(48 + bottomBarHeight).priority(.low)
        }
    }

    /// Height the bottom bar occupies above the safe area (16 + 48 + 16).
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
        textField.clearButtonMode = .always // ESI05-69: keep X while the keyboard is closed
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
        accessibilityLabel = L10n.splitSelectAllA11y
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
