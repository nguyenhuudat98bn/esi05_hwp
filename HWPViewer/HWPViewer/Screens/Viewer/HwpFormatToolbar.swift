//
//  HwpFormatToolbar.swift
//  HWPViewer
//
//  Editor toolbar (Figma F2/F8): Undo/Redo fixed left, the rest scrolls horizontally.
//  Items = 20pt icon + 10pt label; active = #D1E9FF bg + blue tint. Highlight / Text Color
//  expand an inline color strip (none, swatches, rainbow picker).
//

import UIKit
import SnapKit
import Combine
import HwpEditorKit
import SPNComponent

final class HwpFormatToolbar: UIView {
    enum Action {
        case undo, redo
        case fontSize(Double)
        case bold, italic, underline, strikethrough
        case textColor(String?)      // nil = default (black)
        case highlight(String?)      // nil = clear highlight
        case alignLeft, alignRight
        case pickColor(ColorTarget)
        case selectionHint
    }

    enum ColorTarget { case text, highlight }

    var onAction: ((Action) -> Void)?

    static let clearHighlight = "#FFFFFF"   // engine treats white shade as "no highlight"
    static let minFontSize: Double = 6
    static let maxFontSize: Double = 72

    // MARK: - Controls
    private let undoItem = ToolbarItem(icon: Asset.Assets.App.icTbUndo.image, title: L10n.toolbarUndo)
    private let redoItem = ToolbarItem(icon: Asset.Assets.App.icTbRedo.image, title: L10n.toolbarRedo)
    private let fontStepper = FontSizeStepper()
    private let boldItem = ToolbarItem(icon: Asset.Assets.App.icTbBold.image, title: L10n.toolbarBold)
    private let italicItem = ToolbarItem(icon: Asset.Assets.App.icTbItalic.image, title: L10n.toolbarItalic)
    private let underlineItem = ToolbarItem(icon: Asset.Assets.App.icTbUnderline.image, title: L10n.toolbarUnderline)
    private let strikeItem = ToolbarItem(icon: Asset.Assets.App.icTbStrikethrough.image, title: L10n.toolbarStrikethrough)
    private let textColorItem = ToolbarItem(icon: Asset.Assets.App.icTbTextColor.image, title: L10n.toolbarTextColor)
    private let highlightItem = ToolbarItem(icon: Asset.Assets.App.icTbHighlight.image, title: L10n.toolbarHighlight)
    private let alignRightItem = ToolbarItem(icon: Asset.Assets.App.icTbAlignRight.image, title: L10n.toolbarAlignRight)
    private let alignLeftItem = ToolbarItem(icon: Asset.Assets.App.icTbAlignRight.image.withHorizontallyFlippedOrientation(), title: L10n.toolbarAlignLeft)
    private let scrollView = UIScrollView()
    private let scrollStack = UIStackView()
    private let textColorStrip: ColorStripView
    private let highlightStrip: ColorStripView

    // MARK: - State
    private var hasSelection = false
    private var canAlign = false
    private var currentFontSize: Double = 12
    private var cancellables = Set<AnyCancellable>()

    override init(frame: CGRect) {
        textColorStrip = ColorStripView(colors: AppColors.textColorSwatches, clearIsDefault: true)
        highlightStrip = ColorStripView(colors: AppColors.highlightSwatches, clearIsDefault: false)
        super.init(frame: frame)
        backgroundColor = AppColors.toolbarBackground
        setupLayout()
        bind()
        textColorStrip.isHidden = true
        highlightStrip.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override var intrinsicContentSize: CGSize { CGSize(width: UIView.noIntrinsicMetric, height: 64) }

    private func setupLayout() {
        let bottomLine = UIView()
        bottomLine.backgroundColor = AppColors.divider
        addSubview(bottomLine)
        bottomLine.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        // Fixed left cluster: Undo, Redo, divider
        let fixed = UIStackView(arrangedSubviews: [undoItem, redoItem, divider()])
        fixed.axis = .horizontal
        fixed.spacing = 6
        fixed.alignment = .center
        addSubview(fixed)
        fixed.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(4)
        }

        scrollView.showsHorizontalScrollIndicator = false
        scrollView.alwaysBounceHorizontal = true
        addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.leading.equalTo(fixed.snp.trailing).offset(8)
            make.trailing.equalToSuperview()
            make.top.bottom.equalToSuperview().inset(4)
        }

        scrollStack.axis = .horizontal
        scrollStack.spacing = 8
        scrollStack.alignment = .center
        [fontStepper, boldItem, italicItem, underlineItem, strikeItem, textColorItem, textColorStrip,
         highlightItem, highlightStrip, alignRightItem, alignLeftItem].forEach { scrollStack.addArrangedSubview($0) }
        scrollView.addSubview(scrollStack)
        scrollStack.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 12))
            make.height.equalTo(scrollView.frameLayoutGuide)
        }
    }

    private func divider() -> UIView {
        let line = UIView()
        line.backgroundColor = AppColors.border
        line.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(25)
        }
        return line
    }

    private func bind() {
        undoItem.onTap = { [weak self] in self?.onAction?(.undo) }
        redoItem.onTap = { [weak self] in self?.onAction?(.redo) }
        fontStepper.onChange = { [weak self] delta in
            guard let self else { return }
            requireSelection {
                let next = min(Self.maxFontSize, max(Self.minFontSize, self.currentFontSize + delta))
                guard next != self.currentFontSize else { return }
                self.currentFontSize = next
                self.fontStepper.value = next
                self.onAction?(.fontSize(next))
            }
        }
        boldItem.onTap = { [weak self] in self?.requireSelection { self?.onAction?(.bold) } }
        italicItem.onTap = { [weak self] in self?.requireSelection { self?.onAction?(.italic) } }
        underlineItem.onTap = { [weak self] in self?.requireSelection { self?.onAction?(.underline) } }
        strikeItem.onTap = { [weak self] in self?.requireSelection { self?.onAction?(.strikethrough) } }
        textColorItem.onTap = { [weak self] in
            guard let self else { return }
            requireSelection { self.toggleStrip(.text) }
        }
        highlightItem.onTap = { [weak self] in
            guard let self else { return }
            requireSelection { self.toggleStrip(.highlight) }
        }
        alignRightItem.onTap = { [weak self] in self?.requireAlign { self?.onAction?(.alignRight) } }
        alignLeftItem.onTap = { [weak self] in self?.requireAlign { self?.onAction?(.alignLeft) } }

        textColorStrip.onSelect = { [weak self] hex in self?.onAction?(.textColor(hex)) }
        textColorStrip.onPicker = { [weak self] in self?.onAction?(.pickColor(.text)) }
        highlightStrip.onSelect = { [weak self] hex in self?.onAction?(.highlight(hex ?? Self.clearHighlight)) }
        highlightStrip.onPicker = { [weak self] in self?.onAction?(.pickColor(.highlight)) }
    }

    private func toggleStrip(_ target: ColorTarget) {
        let showText = target == .text ? textColorStrip.isHidden : false
        let showHighlight = target == .highlight ? highlightStrip.isHidden : false
        UIView.animate(withDuration: 0.2) {
            self.textColorStrip.isHidden = !showText
            self.highlightStrip.isHidden = !showHighlight
            self.textColorItem.isExpanded = showText
            self.highlightItem.isExpanded = showHighlight
            self.layoutIfNeeded()
        }
        if showText || showHighlight {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                let strip = showText ? self.textColorStrip : self.highlightStrip
                self.scrollView.scrollRectToVisible(strip.frame.insetBy(dx: -24, dy: 0), animated: true)
            }
        }
    }

    func collapseStrips() {
        textColorStrip.isHidden = true
        highlightStrip.isHidden = true
        textColorItem.isExpanded = false
        highlightItem.isExpanded = false
    }

    /// Reflects the current selection / caret state from the engine.
    func update(charProps: RhwpCharProperties?, hasSelection: Bool, canAlign: Bool, canUndo: Bool, canRedo: Bool, isApplying: Bool) {
        self.hasSelection = hasSelection
        self.canAlign = canAlign
        undoItem.isEnabled = canUndo
        redoItem.isEnabled = canRedo
        let formatItems = [boldItem, italicItem, underlineItem, strikeItem, textColorItem, highlightItem]
        formatItems.forEach { $0.isDimmed = !hasSelection }
        fontStepper.isDimmed = !hasSelection
        [alignLeftItem, alignRightItem].forEach { $0.isDimmed = !canAlign }

        boldItem.isActive = charProps?.bold ?? false
        italicItem.isActive = charProps?.italic ?? false
        underlineItem.isActive = charProps?.underline ?? false
        strikeItem.isActive = charProps?.strikethrough ?? false
        highlightItem.isActive = (charProps?.hasHighlight ?? false) || !highlightStrip.isHidden
        textColorItem.isActive = !textColorStrip.isHidden || (charProps?.textColor.map { !Self.isDefaultTextColor($0) } ?? false)

        guard !isApplying else { return }
        if let pt = charProps?.fontSizePt, pt > 0 {
            currentFontSize = pt
            fontStepper.value = pt
        }
        if hasSelection {
            highlightStrip.setSelected(charProps?.hasHighlight == true ? charProps?.shadeColor : nil)
            textColorStrip.setSelected(charProps?.textColor.flatMap { Self.isDefaultTextColor($0) ? nil : $0 })
        }
    }

    private static func isDefaultTextColor(_ hex: String) -> Bool {
        let value = hex.lowercased()
        return value == "#000000" || value == "#000" || value.isEmpty
    }

    private func requireSelection(_ action: () -> Void) {
        hasSelection ? action() : onAction?(.selectionHint)
    }

    private func requireAlign(_ action: () -> Void) {
        canAlign ? action() : onAction?(.selectionHint)
    }
}

// MARK: - Item

final class ToolbarItem: UIControl {
    var onTap: (() -> Void)?

    private let iconView = UIImageView()
    private let label = UILabel()

    var isActive = false { didSet { refresh() } }
    var isExpanded = false { didSet { refresh() } }
    var isDimmed = false { didSet { refresh() } }
    override var isEnabled: Bool { didSet { refresh() } }

    init(icon: UIImage, title: String) {
        super.init(frame: .zero)
        layer.cornerRadius = 4
        iconView.image = icon.withRenderingMode(.alwaysTemplate)
        iconView.contentMode = .scaleAspectFit
        label.text = title
        label.font = AppFonts.regular(10)
        label.textAlignment = .center
        label.numberOfLines = 2
        let stack = UIStackView(arrangedSubviews: [iconView, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 2
        stack.isUserInteractionEnabled = false
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 2, left: 8, bottom: 2, right: 8)) }
        iconView.snp.makeConstraints { $0.size.equalTo(20) }
        snp.makeConstraints { $0.width.greaterThanOrEqualTo(44) }
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped() { onTap?() }

    private func refresh() {
        let highlighted = isActive || isExpanded
        backgroundColor = highlighted ? AppColors.primaryLight : .clear
        let tint = highlighted ? AppColors.primary : AppColors.textToolbar
        iconView.tintColor = tint
        label.textColor = tint
        alpha = (!isEnabled || isDimmed) ? 0.35 : 1
    }

    override var isHighlighted: Bool {
        didSet { if isEnabled { alpha = isHighlighted ? 0.6 : (isDimmed ? 0.35 : 1) } }
    }
}

// MARK: - Font size stepper  [ − 12 + ]

final class FontSizeStepper: UIView {
    var onChange: ((Double) -> Void)?
    var value: Double = 12 { didSet { label.text = "\(Int(value.rounded()))" } }
    var isDimmed = false { didSet { alpha = isDimmed ? 0.35 : 1 } }

    private let label = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let minus = UIButton(type: .system)
        minus.setImage(Asset.Assets.App.icTbFontMinus.image.withRenderingMode(.alwaysTemplate), for: .normal)
        minus.tintColor = AppColors.textToolbar
        minus.addTarget(self, action: #selector(decrease), for: .touchUpInside)
        let plus = UIButton(type: .system)
        plus.setImage(Asset.Assets.App.icTbFontPlus.image.withRenderingMode(.alwaysTemplate), for: .normal)
        plus.tintColor = AppColors.textToolbar
        plus.addTarget(self, action: #selector(increase), for: .touchUpInside)
        label.text = "12"
        label.font = AppFonts.medium(14)
        label.textColor = AppColors.textToolbar
        label.textAlignment = .center
        let stack = UIStackView(arrangedSubviews: [minus, label, plus])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)) }
        minus.snp.makeConstraints { $0.size.equalTo(24) }
        plus.snp.makeConstraints { $0.size.equalTo(24) }
        label.snp.makeConstraints { $0.width.greaterThanOrEqualTo(20) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func decrease() { onChange?(-1) }
    @objc private func increase() { onChange?(1) }
}

// MARK: - Color strip  [ ⃠  ● ● ● ● ● ◐ ]

final class ColorStripView: UIView {
    var onSelect: ((String?) -> Void)?
    var onPicker: (() -> Void)?

    private let colors: [String]
    private var swatches: [SwatchButton] = []
    private let clearButton = SwatchButton(color: nil)
    private let pickerButton = UIButton(type: .custom)
    private let clearIsDefault: Bool

    init(colors: [String], clearIsDefault: Bool) {
        self.colors = colors
        self.clearIsDefault = clearIsDefault
        super.init(frame: .zero)
        let leading = UIView()
        leading.backgroundColor = AppColors.border
        leading.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(25)
        }
        clearButton.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        swatches = colors.map { hex in
            let button = SwatchButton(color: UIColor(hex: hex))
            button.hex = hex
            button.addTarget(self, action: #selector(swatchTapped(_:)), for: .touchUpInside)
            return button
        }
        pickerButton.setImage(Asset.Assets.App.icTbColorPickerGradient.image, for: .normal)
        pickerButton.imageView?.contentMode = .scaleAspectFit
        pickerButton.addTarget(self, action: #selector(pickerTapped), for: .touchUpInside)
        pickerButton.snp.makeConstraints { $0.size.equalTo(28) }
        let stack = UIStackView(arrangedSubviews: [leading, clearButton] + swatches + [pickerButton])
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)) }
        setSelected(nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setSelected(_ hex: String?) {
        let target = hex?.lowercased()
        clearButton.isSelectedSwatch = target == nil
        for swatch in swatches {
            swatch.isSelectedSwatch = swatch.hex?.lowercased() == target
        }
    }

    @objc private func clearTapped() {
        setSelected(nil)
        onSelect?(nil)
    }

    @objc private func swatchTapped(_ sender: SwatchButton) {
        setSelected(sender.hex)
        onSelect?(sender.hex)
    }

    @objc private func pickerTapped() { onPicker?() }
}

final class SwatchButton: UIControl {
    var hex: String?
    var isSelectedSwatch = false { didSet { refresh() } }

    private let circle = UIView()
    private let ring = UIView()
    private let slash = UIImageView(image: Asset.Assets.App.icTbColorNoneSlash.image.withRenderingMode(.alwaysTemplate))

    init(color: UIColor?) {
        super.init(frame: .zero)
        snp.makeConstraints { $0.size.equalTo(28) }
        ring.layer.cornerRadius = 12
        ring.layer.borderWidth = 2
        ring.layer.borderColor = AppColors.primaryRing.cgColor
        ring.isUserInteractionEnabled = false
        addSubview(ring)
        ring.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(24)
        }
        circle.layer.cornerRadius = 8
        circle.backgroundColor = color
        circle.isUserInteractionEnabled = false
        circle.layer.borderWidth = color == nil ? 0 : 0.5
        circle.layer.borderColor = UIColor.black.withAlphaComponent(0.1).cgColor
        addSubview(circle)
        circle.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(16)
        }
        slash.tintColor = AppColors.textToolbar
        slash.contentMode = .scaleAspectFit
        slash.isHidden = color != nil
        addSubview(slash)
        slash.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(17)
        }
        refresh()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func refresh() {
        ring.isHidden = !isSelectedSwatch
    }
}
