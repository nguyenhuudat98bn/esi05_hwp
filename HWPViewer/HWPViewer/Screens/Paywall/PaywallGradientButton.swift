//
//  PaywallGradientButton.swift
//  HWPViewer
//
//  CONTINUE CTA of the paywall: horizontal gradient pill with a trailing arrow. Draws attention with a
//  soft breathing pulse plus a light "shine" sweeping across the gradient every couple of seconds.
//  Animations start when the button enters a window and stop when it leaves it.
//

import UIKit
import Combine
import SnapKit
import SPNComponent

final class GradientButton: UIControl {
    private let gradient = CAGradientLayer()
    private let shine = CAGradientLayer()
    private let label = UILabel()
    private var laidOutSize: CGSize = .zero

    func setTitle(_ title: String) { label.text = title }

    init(title: String, colors: [UIColor]) {
        super.init(frame: .zero)
        layer.cornerRadius = 23
        clipsToBounds = true
        gradient.colors = colors.map(\.cgColor)
        gradient.startPoint = CGPoint(x: 0, y: 0.5)
        gradient.endPoint = CGPoint(x: 1, y: 0.5)
        layer.addSublayer(gradient)

        // Narrow diagonal highlight band that slides from the left edge to the right edge.
        shine.colors = [UIColor.white.withAlphaComponent(0).cgColor,
                        UIColor.white.withAlphaComponent(0.45).cgColor,
                        UIColor.white.withAlphaComponent(0).cgColor]
        shine.locations = [0, 0.5, 1]
        shine.startPoint = CGPoint(x: 0, y: 0.5)
        shine.endPoint = CGPoint(x: 1, y: 0.5)
        shine.transform = CATransform3DMakeRotation(.pi / 8, 0, 0, 1)
        shine.opacity = 0
        layer.insertSublayer(shine, above: gradient)

        label.text = title
        label.font = AppFonts.bold(16)
        label.textColor = .white
        label.textAlignment = .center
        label.isUserInteractionEnabled = false
        addSubview(label)
        label.snp.makeConstraints { $0.center.equalToSuperview() }
        let arrow = UIImageView(image: Asset.Assets.App.icPaywallArrowRight.image.withRenderingMode(.alwaysTemplate))
        arrow.tintColor = .white
        arrow.contentMode = .scaleAspectFit
        addSubview(arrow)
        arrow.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradient.frame = bounds
        guard bounds.size != laidOutSize else { return }
        laidOutSize = bounds.size
        shine.bounds = CGRect(x: 0, y: 0, width: bounds.width * 0.45, height: bounds.height * 2)
        shine.position = CGPoint(x: -shine.bounds.width, y: bounds.midY)
        if window != nil { startCtaAttention() }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        window == nil ? stopCtaAttention() : startCtaAttention()
    }

    // MARK: - Attention

    /// Breathing pulse on the whole button + a shine sweep across the gradient (restarts from scratch).
    func startCtaAttention() {
        startPulseAndBounce(bounceScale: [1.0, 1.04, 0.98, 1.0], duration: 1.6)
        shine.removeAnimation(forKey: "sweep")
        guard bounds.width > 0 else { return }
        let travel = CABasicAnimation(keyPath: "position.x")
        travel.fromValue = -shine.bounds.width
        travel.toValue = bounds.width + shine.bounds.width
        travel.duration = 1.1
        travel.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        let fade = CAKeyframeAnimation(keyPath: "opacity")
        fade.values = [0, 1, 1, 0]
        fade.keyTimes = [0, 0.15, 0.85, 1]
        fade.duration = 1.1
        let group = CAAnimationGroup()
        group.animations = [travel, fade]
        group.duration = 2.6   // 1.1 s sweep, then rest
        group.repeatCount = .infinity
        shine.add(group, forKey: "sweep")
    }

    func stopCtaAttention() {
        stopPulseAndBounce()
        shine.removeAnimation(forKey: "sweep")
    }

    override var isHighlighted: Bool {
        didSet { alpha = isHighlighted ? 0.85 : 1 }
    }

    var tapPublisher: AnyPublisher<Void, Never> { spnPublisher(for: .touchUpInside) }
}
