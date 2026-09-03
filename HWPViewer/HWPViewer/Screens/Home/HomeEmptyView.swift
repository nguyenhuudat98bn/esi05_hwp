//
//  HomeEmptyView.swift
//  HWPViewer
//
//  Empty state (Figma B2 / C3): illustration, title, optional CTA.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class HomeEmptyView: UIView {
    var onAction: (() -> Void)?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let button = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()

    init(image: UIImage?, title: String, subtitle: String? = nil, actionTitle: String? = nil, actionIcon: UIImage? = nil, imageSize: CGSize = CGSize(width: 165, height: 140)) {
        super.init(frame: .zero)
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = AppColors.textTertiary

        titleLabel.text = title
        titleLabel.font = AppFonts.regular(14)
        titleLabel.textColor = AppColors.textDark.withAlphaComponent(0.5)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0

        subtitleLabel.text = subtitle
        subtitleLabel.font = AppFonts.regular(13)
        subtitleLabel.textColor = AppColors.textSecondary
        subtitleLabel.textAlignment = .center
        subtitleLabel.numberOfLines = 0
        subtitleLabel.isHidden = subtitle == nil

        button.setTitle(actionTitle, for: .normal)
        if let actionIcon {
            button.setImage(actionIcon.withRenderingMode(.alwaysTemplate), for: .normal)
            button.tintColor = .white
            button.imageEdgeInsets = UIEdgeInsets(top: 0, left: -8, bottom: 0, right: 0)
        }
        button.titleLabel?.font = AppFonts.semibold(16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = AppColors.primary
        button.layer.cornerRadius = 24
        button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 70, bottom: 0, right: 70)
        button.isHidden = actionTitle == nil
        button.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.onAction?() }.store(in: &cancellables)

        let stack = UIStackView(arrangedSubviews: [imageView, titleLabel, subtitleLabel, button])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 8
        stack.setCustomSpacing(12, after: imageView)
        stack.setCustomSpacing(24, after: subtitleLabel)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(32)
        }
        imageView.snp.makeConstraints { $0.size.equalTo(imageSize) }
        button.snp.makeConstraints { $0.height.equalTo(48) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func update(title: String, subtitle: String?, actionTitle: String?) {
        titleLabel.text = title
        subtitleLabel.text = subtitle
        subtitleLabel.isHidden = subtitle == nil
        button.setTitle(actionTitle, for: .normal)
        button.isHidden = actionTitle == nil
    }
}
