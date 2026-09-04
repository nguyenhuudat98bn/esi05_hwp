//
//  GradientCardView.swift
//  HWPViewer
//
//  Feature card (Figma Home/Tools): 156×88, title / subtitle / "Go" pill over either a full-card background image
//  or a vertical gradient with a big rotated art bottom-right.
//

import UIKit
import SnapKit
import Combine
import SPNComponent

final class GradientCardView: UIControl {
    private let gradientLayer = CAGradientLayer()
    private let backgroundView = UIImageView()
    private let artView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let goPill = UIView()

    init(title: String, subtitle: String?, background: UIImage? = nil, art: UIImage?, artRotation: CGFloat = -17, artSize: CGFloat = 52, colors: [UIColor], pillColor: UIColor) {
        super.init(frame: .zero)
        layer.cornerRadius = AppMetrics.cardRadius
        clipsToBounds = true
        if let background {
            // Designer-supplied card art: fills the card, no gradient / rotated art on top.
            backgroundView.image = background
            backgroundView.contentMode = .scaleAspectFill
            backgroundView.isUserInteractionEnabled = false
            addSubview(backgroundView)
            backgroundView.snp.makeConstraints { $0.edges.equalToSuperview() }
        } else {
            gradientLayer.colors = colors.map(\.cgColor)
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            layer.insertSublayer(gradientLayer, at: 0)
        }

        artView.image = background == nil ? art : nil
        artView.contentMode = .scaleAspectFit
        artView.tintColor = .white
        artView.isUserInteractionEnabled = false
        artView.transform = CGAffineTransform(rotationAngle: artRotation * .pi / 180)
        addSubview(artView)
        artView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(-2)
            make.size.equalTo(artSize)
        }

        titleLabel.text = title
        titleLabel.textColor = .white
        titleLabel.font = AppFonts.semibold(16)
        subtitleLabel.text = subtitle
        subtitleLabel.textColor = .white
        subtitleLabel.font = AppFonts.regular(10)
        subtitleLabel.isHidden = subtitle == nil

        goPill.backgroundColor = pillColor
        goPill.layer.cornerRadius = 12
        goPill.isUserInteractionEnabled = false
        let goLabel = UILabel()
        goLabel.text = L10n.homeCardGo
        goLabel.textColor = .white
        goLabel.font = AppFonts.semibold(14)
        let chevron = UIImageView(image: Asset.Assets.App.icArrowFilledRight.image.withRenderingMode(.alwaysTemplate))
        chevron.tintColor = .white
        chevron.contentMode = .scaleAspectFit
        goPill.addSubview(goLabel)
        goPill.addSubview(chevron)
        goLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview().inset(2)
        }
        chevron.snp.makeConstraints { make in
            make.leading.equalTo(goLabel.snp.trailing).offset(2)
            make.trailing.equalToSuperview().inset(8)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 8, height: 16))
        }

        addSubview(titleLabel)
        addSubview(subtitleLabel)
        addSubview(goPill)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.leading.equalToSuperview().inset(13)
            make.trailing.lessThanOrEqualToSuperview().inset(8)
        }
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.equalToSuperview().inset(12)
            make.trailing.lessThanOrEqualToSuperview().inset(8)
        }
        goPill.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(14)
            make.bottom.equalToSuperview().inset(10)
            make.height.equalTo(24)
        }
    }

    convenience init(tool: ToolKind) {
        self.init(title: tool.title, subtitle: tool.subtitle, background: tool.cardBackground, art: tool.art, artRotation: tool.artRotation, artSize: tool.artSize, colors: tool.gradient, pillColor: tool.pillColor)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    var tapPublisher: AnyPublisher<Void, Never> { spnPublisher(for: .touchUpInside) }
}
