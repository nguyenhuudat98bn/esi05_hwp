//
//  SplitPageCell.swift
//  HWPViewer
//
//  One page thumbnail on the Split screen: the rendered page, its number, and either a part color
//  band (Page ranges / Every N) or a pick check (Pick pages). Thumbnails load lazily per cell.
//

import UIKit
import SnapKit

final class SplitPageCell: UICollectionViewCell {
    static let identifier = "SplitPageCell"

    private let pageView = UIImageView()
    private let band = UIView()
    private let numberLabel = MergeSplitUI.label(font: AppFonts.regular(11), color: UIColor(hex: "#414651"))
    private let check = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
    private let ring = UIView()
    private var loadingPage: Int?

    override init(frame: CGRect) {
        super.init(frame: frame)
        pageView.backgroundColor = .white
        pageView.contentMode = .scaleAspectFit
        pageView.layer.cornerRadius = 4
        pageView.layer.borderWidth = 1
        pageView.clipsToBounds = true
        band.layer.cornerRadius = 2
        numberLabel.textAlignment = .center
        check.tintColor = AppColors.primary
        check.backgroundColor = .white
        check.layer.cornerRadius = 10
        ring.layer.cornerRadius = 9
        ring.layer.borderWidth = 2
        ring.layer.borderColor = AppColors.border.cgColor
        ring.backgroundColor = .white

        [pageView, numberLabel].forEach(contentView.addSubview)
        [band, check, ring].forEach(pageView.addSubview)
        numberLabel.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(16)
        }
        pageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(numberLabel.snp.top).offset(-4)
        }
        band.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview().inset(6)
            make.height.equalTo(4)
        }
        check.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(5)
            make.size.equalTo(20)
        }
        ring.snp.makeConstraints { make in
            make.center.equalTo(check)
            make.size.equalTo(18)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func prepareForReuse() {
        super.prepareForReuse()
        pageView.image = nil
        loadingPage = nil
    }

    /// `partColor` != nil → band mode; `picked` != nil → pick mode.
    func configure(page: Int, partColor: UIColor?, picked: Bool?, renderer: HwpPageThumbnailRenderer?) {
        numberLabel.text = "\(page)"
        numberLabel.font = picked == true ? AppFonts.bold(11) : AppFonts.regular(11)
        band.isHidden = partColor == nil
        band.backgroundColor = partColor
        check.isHidden = picked != true
        ring.isHidden = picked != false
        pageView.layer.borderColor = (picked == true ? AppColors.primary : UIColor(hex: "#DADBDD")).cgColor
        pageView.layer.borderWidth = picked == true ? 2 : 1
        accessibilityLabel = "Page \(page)"
        accessibilityTraits = picked == true ? [.button, .selected] : .button

        guard let renderer, loadingPage != page else { return }
        loadingPage = page
        let width = bounds.width
        let scale = traitCollection.displayScale
        Task { @MainActor [weak self] in
            let image = await renderer.thumbnail(page: page, width: width, scale: scale)
            guard let self, loadingPage == page else { return }
            pageView.image = image
        }
    }
}
