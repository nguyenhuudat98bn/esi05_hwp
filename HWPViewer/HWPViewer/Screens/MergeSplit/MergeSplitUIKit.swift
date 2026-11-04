//
//  MergeSplitUIKit.swift
//  HWPViewer
//
//  Small building blocks shared by the Merge / Split HWP screens (Claude Design canvas
//  "HWP Merge & Split – POC flows"): pill buttons, the bottom action bar, segmented pill, labels.
//

import UIKit
import SnapKit
import SPNComponent

enum MergeSplitUI {
    static func navigationConfig(title: String) -> SPNNavigationConfiguration {
        SPNNavigationConfiguration(
            title: title, hasBackButton: true,
            titleFont: AppFonts.medium(18), titleColor: AppColors.textPrimary, backgroundColor: AppColors.background
        )
    }

    /// 48pt pill: primary = blue / white text, secondary = gray / dark text.
    static func pillButton(_ title: String, primary: Bool = true) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = primary ? AppFonts.semibold(16) : AppFonts.medium(16)
        button.setTitleColor(primary ? .white : AppColors.textPrimary, for: .normal)
        button.setTitleColor(primary ? UIColor.white.withAlphaComponent(0.6) : AppColors.textTertiary, for: .disabled)
        button.backgroundColor = primary ? AppColors.primary : AppColors.surfaceMuted
        button.layer.cornerRadius = AppMetrics.buttonRadius
        button.snp.makeConstraints { $0.height.equalTo(AppMetrics.buttonHeight) }
        return button
    }

    static func label(_ text: String? = nil, font: UIFont, color: UIColor = AppColors.textPrimary, lines: Int = 1) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = font
        label.textColor = color
        label.numberOfLines = lines
        return label
    }

    /// Dashed "+ Add …" row.
    static func dashedAddButton(_ title: String) -> UIButton {
        let button = DashedButton(type: .system)
        button.setTitle("  \(title)", for: .normal)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.tintColor = AppColors.primary
        button.titleLabel?.font = AppFonts.semibold(15)
        button.snp.makeConstraints { $0.height.equalTo(46) }
        return button
    }

    /// White bottom bar with a hairline on top, holding `content`; pinned to the safe area.
    static func bottomBar(in view: UIView, content: UIView) -> UIView {
        let bar = UIView()
        bar.backgroundColor = AppColors.background
        let line = UIView()
        line.backgroundColor = AppColors.divider
        bar.addSubview(line)
        bar.addSubview(content)
        view.addSubview(bar)
        line.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(1)
        }
        content.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(12)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(12)
        }
        bar.snp.makeConstraints { $0.leading.trailing.bottom.equalToSuperview() }
        return bar
    }

    /// Gray pill segmented control with white selected thumb.
    static func segmented(_ items: [String]) -> UISegmentedControl {
        let control = UISegmentedControl(items: items)
        control.selectedSegmentIndex = 0
        control.backgroundColor = AppColors.surfaceMuted
        control.selectedSegmentTintColor = .white
        control.setTitleTextAttributes([.font: AppFonts.medium(14), .foregroundColor: UIColor(hex: "#414651")], for: .normal)
        control.setTitleTextAttributes([.font: AppFonts.semibold(14), .foregroundColor: AppColors.textPrimary], for: .selected)
        control.snp.makeConstraints { $0.height.equalTo(40) }
        return control
    }
}

/// Button with a 1.5pt dashed light-blue border (layer redrawn on resize).
final class DashedButton: UIButton {
    private let border = CAShapeLayer()

    override func layoutSubviews() {
        super.layoutSubviews()
        if border.superlayer == nil {
            border.strokeColor = UIColor(hex: "#9CCBFF").cgColor
            border.fillColor = UIColor.clear.cgColor
            border.lineWidth = 1.5
            border.lineDashPattern = [6, 4]
            layer.addSublayer(border)
        }
        border.frame = bounds
        border.path = UIBezierPath(roundedRect: bounds.insetBy(dx: 0.75, dy: 0.75), cornerRadius: 12).cgPath
    }
}
