//
//  SplitPageCell.swift
//  HWPViewer
//
//  Page tile of the Split page grid (Figma "List image", 6978:109971 / selected 6978:110261):
//  page preview with a 0.96pt border (#CECFD2, selected #0BA5EC), radius 3.84, a white 82% band
//  over its bottom 30.72pt, a 19.2pt check square bottom-right, and the 2-digit page number under
//  it (13.44pt medium, #94979C / selected #0BA5EC). Thumbnails load lazily per cell.
//

import UIKit
import SnapKit

final class SplitPageCell: UICollectionViewCell {
    static let identifier = "SplitPageCell"
    /// Preview 99.84×115.2 + 3.84 gap + 17.28 number line (Figma, 360pt-wide frame).
    static let previewAspect: CGFloat = 115.2 / 99.84
    static let numberBlock: CGFloat = 3.84 + 17.28

    private let preview = PagePreviewView()
    private var pageView: UIImageView { preview.pageView }
    private let band = UIView()
    private let check = UIImageView()
    private let numberLabel = UILabel()
    private var loadingPage: Int?
    /// Thumbnail request of the page on screen; cancelled when the cell scrolls away, so fast
    /// scrolling does not leave a queue of renders for pages nobody looks at any more.
    private var thumbnailTask: Task<Void, Never>?

    override init(frame: CGRect) {
        super.init(frame: frame)
        preview.backgroundColor = .white
        preview.layer.cornerRadius = 3.84
        preview.layer.borderWidth = 0.96
        preview.clipsToBounds = true
        band.backgroundColor = UIColor.white.withAlphaComponent(0.82)
        numberLabel.font = AppFonts.medium(13.44)
        numberLabel.textAlignment = .center

        contentView.addSubview(preview)
        contentView.addSubview(numberLabel)
        [band, check].forEach(preview.addSubview)
        preview.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(preview.snp.width).multipliedBy(Self.previewAspect)
        }
        numberLabel.snp.makeConstraints { make in
            make.top.equalTo(preview.snp.bottom).offset(3.84)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(17.28)
        }
        band.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(30.72)
        }
        check.snp.makeConstraints { make in
            make.trailing.bottom.equalToSuperview().inset(5.76)
            make.size.equalTo(19.2)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        thumbnailTask?.cancel()
        thumbnailTask = nil
        pageView.image = nil
        loadingPage = nil
    }

    func configure(page: Int, selected: Bool, renderer: HwpPageThumbnailRenderer?) {
        numberLabel.text = String(format: "%02d", page)
        numberLabel.textColor = selected ? AppColors.primaryRing : AppColors.textTertiary
        preview.layer.borderColor = (selected ? AppColors.primaryRing : AppColors.border).cgColor
        check.image = selected ? Asset.Assets.App.icPageCheckOn.image : Asset.Assets.App.icPageCheckOff.image
        isAccessibilityElement = true
        accessibilityLabel = L10n.splitPageA11y(page)
        accessibilityTraits = selected ? [.button, .selected] : .button

        guard let renderer, loadingPage != page else { return }
        loadingPage = page
        let width = max(bounds.width, 80) * 1.2538
        let scale = traitCollection.displayScale
        thumbnailTask?.cancel()
        thumbnailTask = Task { @MainActor [weak self] in
            let image = await renderer.thumbnail(page: page, width: width, scale: scale)
            guard let self, !Task.isCancelled, loadingPage == page else { return }
            pageView.image = image
        }
    }
}

/// Tile background + page image. Figma frames the page zoomed past its margins: 125.38% × 140.61%
/// of the tile, offset −12.28% / −11.93% (laid out here, once the tile has its size).
private final class PagePreviewView: UIView {
    let pageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        pageView.contentMode = .scaleAspectFill
        pageView.clipsToBounds = true
        addSubview(pageView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        pageView.frame = CGRect(x: -0.1228 * bounds.width, y: -0.1193 * bounds.height,
                                width: 1.2538 * bounds.width, height: 1.4061 * bounds.height)
    }
}
