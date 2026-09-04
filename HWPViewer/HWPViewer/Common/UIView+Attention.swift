//
//  UIView+Attention.swift
//  HWPViewer
//
//  "Look here" animation for primary CTAs (Home Import File / FAB +): a gentle pulse on the view plus a
//  halo ring that expands and fades behind it. Survives app background/foreground and view re-attachment.
//

import UIKit
import SPNComponent

extension UIView {
    /// Starts (or restarts) the pulse + halo. `cornerRadius` shapes the halo; `color` defaults to the view's background.
    func startAttention(cornerRadius: CGFloat, color: UIColor? = nil) {
        let animator = attentionAnimator ?? AttentionAnimator(view: self)
        attentionAnimator = animator
        animator.cornerRadius = cornerRadius
        animator.color = color ?? backgroundColor ?? AppColors.primary
        animator.start()
    }

    func stopAttention() {
        attentionAnimator?.stop()
        attentionAnimator = nil
    }

    private static var attentionKey: UInt8 = 0
    private var attentionAnimator: AttentionAnimator? {
        get { objc_getAssociatedObject(self, &Self.attentionKey) as? AttentionAnimator }
        set { objc_setAssociatedObject(self, &Self.attentionKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }
}

/// Owns the halo layer and re-applies the animations after the app comes back to the foreground
/// (Core Animation drops running animations on background).
private final class AttentionAnimator {
    private weak var view: UIView?
    private let halo = CALayer()
    private var observer: NSObjectProtocol?
    var cornerRadius: CGFloat = 24
    var color: UIColor = AppColors.primary

    init(view: UIView) {
        self.view = view
        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.start() }
    }

    deinit {
        if let observer { NotificationCenter.default.removeObserver(observer) }
        halo.removeFromSuperlayer()
    }

    func start() {
        guard let view, view.window != nil, !view.isHidden else { return }
        view.layoutIfNeeded()
        // Already running on the same geometry (layoutSubviews calls this often) → leave it alone.
        if halo.animation(forKey: "attention") != nil, halo.superlayer === view.layer, halo.frame == view.bounds { return }
        halo.frame = view.bounds
        halo.cornerRadius = cornerRadius
        halo.backgroundColor = color.cgColor
        halo.opacity = 0
        if halo.superlayer !== view.layer { view.layer.insertSublayer(halo, at: 0) }
        view.layer.masksToBounds = false

        view.startPulseAndBounce(bounceScale: [1.0, 1.06, 0.98, 1.0], duration: 1.6)

        halo.removeAnimation(forKey: "attention")
        let scale = CABasicAnimation(keyPath: "transform.scale")
        scale.fromValue = 1.0
        scale.toValue = 1.28
        let fade = CABasicAnimation(keyPath: "opacity")
        fade.fromValue = 0.45
        fade.toValue = 0.0
        let group = CAAnimationGroup()
        group.animations = [scale, fade]
        group.duration = 1.6
        group.repeatCount = .infinity
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        halo.add(group, forKey: "attention")
    }

    func stop() {
        view?.stopPulseAndBounce()
        halo.removeAnimation(forKey: "attention")
        halo.removeFromSuperlayer()
    }
}
