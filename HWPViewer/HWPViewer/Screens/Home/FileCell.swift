//
//  FileCell.swift
//  HWPViewer
//
//  List row: file-type icon, name, "date · size", bookmark, more (Figma B1).
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class FileCell: UITableViewCell {
    static let identifier = "FileCell"

    var onBookmark: (() -> Void)?
    var onMore: (() -> Void)?

    private let card = UIView()
    private let iconView = FileKindIconView()
    private let nameLabel = UILabel()
    private let metaLabel = UILabel()
    private let bookmarkButton = UIButton(type: .system)
    private let moreButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = AppMetrics.cellRadius
        contentView.addSubview(card)
        card.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(6)
            make.leading.trailing.equalToSuperview()
        }

        nameLabel.font = AppFonts.medium(16)
        nameLabel.textColor = AppColors.textPrimary
        nameLabel.lineBreakMode = .byTruncatingMiddle
        metaLabel.font = AppFonts.regular(12)
        metaLabel.textColor = AppColors.textSecondary

        bookmarkButton.tintColor = AppColors.textTertiary
        moreButton.setImage(Asset.Assets.App.icMore2Line.image.withRenderingMode(.alwaysTemplate), for: .normal)
        moreButton.tintColor = AppColors.textSecondary

        let textStack = UIStackView(arrangedSubviews: [nameLabel, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 4

        card.addSubview(iconView)
        card.addSubview(textStack)
        card.addSubview(bookmarkButton)
        card.addSubview(moreButton)

        iconView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(AppMetrics.screenPadding)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 34, height: 40))
            make.top.equalToSuperview().inset(11)
        }
        textStack.snp.makeConstraints { make in
            make.leading.equalTo(iconView.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(bookmarkButton.snp.leading).offset(-8)
        }
        bookmarkButton.snp.makeConstraints { make in
            make.trailing.equalTo(moreButton.snp.leading).offset(-4)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }
        moreButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(36)
        }

        bookmarkButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onBookmark?() }.store(in: &cancellables)
        moreButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onMore?() }.store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func configure(_ item: FileItem, showsBookmark: Bool = true, showsMore: Bool = true) {
        iconView.kind = item.kind
        nameLabel.text = item.name
        metaLabel.text = item.metaText
        bookmarkButton.isHidden = !showsBookmark
        moreButton.isHidden = !showsMore
        let icon = item.isBookmarked ? Asset.Assets.App.icBookmarkFilled.image : Asset.Assets.App.icBookmarkOutline.image
        bookmarkButton.setImage(icon.withRenderingMode(.alwaysTemplate), for: .normal)
        bookmarkButton.tintColor = item.isBookmarked ? AppColors.accentOrange : AppColors.textTertiary
    }
}

/// Document icon: HWP / PDF artwork from Figma; DOC falls back to a tinted badge.
final class FileKindIconView: UIView {
    private let imageView = UIImageView()
    private let page = UIView()
    private let badge = UILabel()

    var kind: FileKind = .hwp {
        didSet { apply() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        imageView.snp.makeConstraints { $0.edges.equalToSuperview() }
        page.layer.cornerRadius = 6
        addSubview(page)
        page.snp.makeConstraints { $0.edges.equalToSuperview() }
        badge.font = AppFonts.bold(10)
        badge.textColor = .white
        badge.textAlignment = .center
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        page.addSubview(badge)
        badge.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().inset(6)
            make.height.equalTo(16)
            make.leading.trailing.equalToSuperview().inset(3)
        }
        apply()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func apply() {
        switch kind {
        case .hwp, .hwpx:
            imageView.image = Asset.Assets.App.imgHwpFile.image
            page.isHidden = true
        case .pdf:
            imageView.image = Asset.Assets.App.imgPdfFile.image
            page.isHidden = true
        case .doc, .docx:
            imageView.image = nil
            page.isHidden = false
            page.backgroundColor = AppColors.doc.withAlphaComponent(0.14)
            badge.backgroundColor = AppColors.doc
            badge.text = kind.rawValue.uppercased()
        }
    }
}
