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
        bookmarkButton.setImage(FileItem.bookmarkIcon(filled: item.isBookmarked), for: .normal)
        bookmarkButton.tintColor = AppColors.textTertiary
    }
}

/// Document icon composed from the Figma vector parts: tinted body + folded corner + white glyph.
final class FileKindIconView: UIView {
    private let body = UIImageView(image: Asset.Assets.App.icFileBody.image.withRenderingMode(.alwaysTemplate))
    private let fold = UIImageView(image: Asset.Assets.App.icFileFold.image)
    private let glyph = UIImageView()
    /// DOC/DOCX glyph: four white bars drawn in code (Figma 18423:129614 has no exported asset).
    private let lines = UIStackView()

    var kind: FileKind = .hwp {
        didSet { apply() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        body.contentMode = .scaleAspectFit
        fold.contentMode = .scaleAspectFit
        glyph.contentMode = .scaleAspectFit
        addSubview(body)
        addSubview(fold)
        addSubview(glyph)
        addSubview(lines)
        body.snp.makeConstraints { $0.edges.equalToSuperview() }
        // Body is 33.5×40; fold is 10.7 square in the top-right corner; glyph ≈ 60% of the width, centred, slightly low.
        fold.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview()
            make.width.equalTo(self.snp.width).multipliedBy(10.72 / 33.53)
            make.height.equalTo(fold.snp.width)
        }
        glyph.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(2)
            make.width.equalTo(self.snp.width).multipliedBy(0.62)
            make.height.equalTo(glyph.snp.width)
        }
        // 4 bars, 18×1.5 each with a 4pt gap, 12pt down from the top of the 33.53×39.92 icon.
        lines.axis = .vertical
        lines.spacing = 4
        lines.alignment = .fill
        for _ in 0..<4 {
            let bar = UIView()
            bar.backgroundColor = .white
            bar.layer.cornerRadius = 0.75
            bar.snp.makeConstraints { $0.height.equalTo(1.5) }
            lines.addArrangedSubview(bar)
        }
        lines.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(self.snp.bottom).multipliedBy(12.0 / 39.92)
            make.width.equalTo(self.snp.width).multipliedBy(18.0 / 33.53)
        }
        apply()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func apply() {
        switch kind {
        case .hwp, .hwpx:
            body.tintColor = AppColors.hwp
            glyph.image = Asset.Assets.App.icFileGlyphHwp.image
            lines.isHidden = true
        case .pdf:
            body.tintColor = AppColors.pdf
            glyph.image = Asset.Assets.App.icFileGlyphPdf.image
            lines.isHidden = true
        case .doc, .docx:
            body.tintColor = AppColors.doc
            glyph.image = nil
            lines.isHidden = false
        }
    }
}
