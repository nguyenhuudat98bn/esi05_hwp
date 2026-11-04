//
//  SplitRangeRowView.swift
//  HWPViewer
//
//  One part row (design "Split 1 – By page ranges"): color dot, "Part n", first–last page fields,
//  remove. Read-only (no fields editable, no remove) for the Every N preview.
//

import UIKit
import SnapKit

final class SplitRangeRowView: UIView, UITextFieldDelegate {
    /// New (first, last) whenever a field changes; nil values while a field is empty.
    var onChange: ((Int?, Int?) -> Void)?
    var onRemove: (() -> Void)?

    private let fromField = SplitRangeRowView.pageField()
    private let toField = SplitRangeRowView.pageField()
    private let removeButton = UIButton(type: .system)

    init(index: Int, range: ClosedRange<Int>, editable: Bool) {
        super.init(frame: .zero)
        layer.cornerRadius = AppMetrics.cardRadius
        layer.borderWidth = 1
        layer.borderColor = AppColors.divider.cgColor
        snp.makeConstraints { $0.height.equalTo(52) }

        let dot = UIView()
        dot.backgroundColor = SplitPlan.color(part: index)
        dot.layer.cornerRadius = 5
        dot.snp.makeConstraints { $0.size.equalTo(10) }
        let title = MergeSplitUI.label(L10n.splitPart(index + 1), font: AppFonts.semibold(14))
        title.snp.makeConstraints { $0.width.equalTo(56) }
        let dash = MergeSplitUI.label("–", font: AppFonts.regular(13), color: UIColor(hex: "#535862"))
        fromField.text = "\(range.lowerBound)"
        toField.text = "\(range.upperBound)"
        fromField.accessibilityLabel = "\(L10n.splitPart(index + 1)) first page"
        toField.accessibilityLabel = "\(L10n.splitPart(index + 1)) last page"
        [fromField, toField].forEach { field in
            field.isEnabled = editable
            field.delegate = self
            field.addTarget(self, action: #selector(fieldChanged), for: .editingChanged)
        }
        removeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        removeButton.tintColor = AppColors.textSecondary
        removeButton.accessibilityLabel = "Remove \(L10n.splitPart(index + 1))"
        removeButton.isHidden = !editable
        removeButton.addTarget(self, action: #selector(removeTapped), for: .touchUpInside)
        removeButton.snp.makeConstraints { $0.size.equalTo(44) }

        let row = UIStackView(arrangedSubviews: [dot, title, fromField, dash, toField, UIView(), removeButton])
        row.alignment = .center
        row.spacing = 8
        row.setCustomSpacing(10, after: dot)
        addSubview(row)
        row.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 4)) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private static func pageField() -> UITextField {
        let field = UITextField()
        field.keyboardType = .numberPad
        field.textAlignment = .center
        field.font = AppFonts.regular(15)
        field.textColor = AppColors.textPrimary
        field.layer.cornerRadius = 8
        field.layer.borderWidth = 1
        field.layer.borderColor = AppColors.border.cgColor
        field.snp.makeConstraints { make in
            make.width.equalTo(44)
            make.height.equalTo(32)
        }
        return field
    }

    @objc private func fieldChanged() {
        onChange?(Int(fromField.text ?? ""), Int(toField.text ?? ""))
    }

    @objc private func removeTapped() {
        onRemove?()
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        string.allSatisfy(\.isNumber)
    }
}
