//
//  HwpFileRowCell.swift
//  HWPViewer
//
//  File row of the Merge / Split screens (Figma "File", 6978:107107): 62pt white row, HWP icon
//  33.5×40, name 16pt medium, "date · size" 12pt, and a trailing accessory — a checkbox (Select
//  Files), a red trash button (Merge Files) or nothing (Split "Select a file"). Rows are 12pt apart.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa

final class HwpFileRowCell: UITableViewCell {
    static let identifier = "HwpFileRowCell"
    /// 62pt row + 12pt gap.
    static let height: CGFloat = AppMetrics.cellHeight + AppMetrics.cellSpacing

    enum Accessory: Equatable {
        case none
        case checkbox(isOn: Bool)
        case delete
    }

    var onDelete: (() -> Void)?

    private let iconView = FileKindIconView()
    private let nameLabel = MergeSplitUI.label(font: AppFonts.medium(16))
    private let metaLabel = MergeSplitUI.label(font: AppFonts.regular(12), color: AppColors.textSecondary)
    private let checkbox = UIImageView()
    private let deleteButton = UIButton(type: .custom)
    private var cancellables = Set<AnyCancellable>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = AppColors.background
        contentView.backgroundColor = AppColors.background
        nameLabel.lineBreakMode = .byTruncatingMiddle
        checkbox.contentMode = .center
        deleteButton.setImage(Asset.Assets.App.icTrashRed.image, for: .normal)
        deleteButton.accessibilityLabel = L10n.fileActionDelete

        let text = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        text.axis = .vertical
        text.spacing = 4
        [iconView, text, checkbox, deleteButton].forEach(contentView.addSubview)
        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(AppMetrics.screenPadding)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 33.5, height: 40))
        }
        text.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.lessThanOrEqualTo(checkbox.snp.leading).offset(-12)
        }
        checkbox.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(AppMetrics.screenPadding)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        deleteButton.snp.makeConstraints { make in
            make.center.equalTo(checkbox)
            make.size.equalTo(44)
        }
        deleteButton.tapPublisher
            .sink { [weak self] _ in self?.onDelete?() }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        onDelete = nil
    }

    func configure(item: FileItem, accessory: Accessory) {
        iconView.kind = item.kind
        nameLabel.text = item.url.lastPathComponent
        metaLabel.text = item.metaText
        switch accessory {
        case .none:
            checkbox.isHidden = true
            deleteButton.isHidden = true
            accessibilityTraits = .button
        case .checkbox(let isOn):
            checkbox.isHidden = false
            deleteButton.isHidden = true
            checkbox.image = isOn ? Asset.Assets.App.icCheckboxOn.image : Asset.Assets.App.icCheckboxOff.image
            accessibilityTraits = isOn ? [.button, .selected] : .button
        case .delete:
            checkbox.isHidden = true
            checkbox.image = nil
            deleteButton.isHidden = false
            accessibilityTraits = .none
        }
        accessibilityLabel = "\(item.url.lastPathComponent), \(item.metaText)"
    }
}
