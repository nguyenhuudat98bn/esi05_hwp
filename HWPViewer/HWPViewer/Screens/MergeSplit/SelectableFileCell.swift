//
//  SelectableFileCell.swift
//  HWPViewer
//
//  File row for multi-select (Merge 1): kind icon, name, meta, and a trailing badge — the pick
//  order (1, 2, 3…) on blue when selected, an empty ring otherwise. Selected rows get a soft blue
//  card. Also used read-only (no badge) for result lists.
//

import UIKit
import SnapKit

final class SelectableFileCell: UITableViewCell {
    static let identifier = "SelectableFileCell"

    private let card = UIView()
    private let iconView = FileKindIconView()
    private let nameLabel = MergeSplitUI.label(font: AppFonts.medium(16))
    private let metaLabel = MergeSplitUI.label(font: AppFonts.regular(12), color: AppColors.textSecondary)
    private let badge = MergeSplitUI.label(font: AppFonts.bold(14), color: .white)
    private let ring = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        card.layer.cornerRadius = AppMetrics.cardRadius
        card.layer.borderWidth = 1
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(4)
            make.leading.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
        }

        nameLabel.lineBreakMode = .byTruncatingMiddle
        let text = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        text.axis = .vertical
        text.spacing = 4

        badge.textAlignment = .center
        badge.backgroundColor = AppColors.primary
        badge.layer.cornerRadius = 13
        badge.clipsToBounds = true
        ring.layer.cornerRadius = 11
        ring.layer.borderWidth = 2
        ring.layer.borderColor = AppColors.border.cgColor

        [iconView, text, badge, ring].forEach(card.addSubview)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.width.equalTo(33.5)
            make.height.equalTo(40)
        }
        badge.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(14)
            make.centerY.equalToSuperview()
            make.size.equalTo(26)
        }
        ring.snp.makeConstraints { make in
            make.center.equalTo(badge)
            make.size.equalTo(22)
        }
        text.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(14)
            make.trailing.equalTo(badge.snp.leading).offset(-12)
            make.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    /// `order` = 1-based pick order, nil = not selected. `showsSelection: false` hides badge + ring.
    func configure(name: String, meta: String, kind: FileKind, order: Int?, showsSelection: Bool = true) {
        iconView.kind = kind
        nameLabel.text = name
        metaLabel.text = meta
        let selected = order != nil
        badge.text = order.map(String.init)
        badge.isHidden = !showsSelection || !selected
        ring.isHidden = !showsSelection || selected
        card.backgroundColor = selected ? AppColors.primarySoft : AppColors.surface
        card.layer.borderColor = (selected ? UIColor(hex: "#9CCBFF") : AppColors.divider).cgColor
        accessibilityTraits = selected ? [.button, .selected] : .button
    }
}
