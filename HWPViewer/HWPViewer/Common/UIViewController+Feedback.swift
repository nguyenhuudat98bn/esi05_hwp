//
//  UIViewController+Feedback.swift
//  HWPViewer
//
//  Toasts + HUD used across screens.
//

import UIKit
import SnapKit
import SVProgressHUD
import SPNComponent

extension UIViewController {
    func showLoadingHUD(_ show: Bool) {
        if show {
            SVProgressHUD.setDefaultMaskType(.clear)
            SVProgressHUD.show()
        } else {
            SVProgressHUD.dismiss()
            SVProgressHUD.setDefaultMaskType(.none)
        }
    }

    /// Bottom toast (Figma 18387:124320): blue pill, 14pt white text, 16pt X that dismisses it early. Auto hides.
    func showToast(_ message: String, duration: TimeInterval = 2.5, bottomInset: CGFloat = 24) {
        guard let host = view.window ?? view else { return }
        host.subviews.filter { $0.tag == ToastView.tag }.forEach { $0.removeFromSuperview() }
        let toast = ToastView(message: message)
        host.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(24)
            make.bottom.equalTo(host.safeAreaLayoutGuide).inset(bottomInset)
        }
        let hide = { [weak toast] in
            guard let toast, toast.superview != nil else { return }
            UIView.animate(withDuration: 0.25, animations: { toast.alpha = 0 }) { _ in toast.removeFromSuperview() }
        }
        toast.onClose = hide
        toast.alpha = 0
        toast.transform = CGAffineTransform(translationX: 0, y: 12)
        UIView.animate(withDuration: 0.25) {
            toast.alpha = 1
            toast.transform = .identity
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: hide)
    }
}

final class ToastView: UIView {
    static let tag = 0x70A57
    var onClose: (() -> Void)?

    init(message: String) {
        super.init(frame: .zero)
        tag = Self.tag
        backgroundColor = AppColors.primary
        layer.cornerRadius = 17   // 8pt vertical padding + 18pt content → 34pt pill
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = AppFonts.medium(14)
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        let close = UIButton(type: .system)
        close.setImage(Asset.Assets.App.icToastCancel16.image.withRenderingMode(.alwaysTemplate), for: .normal)
        close.tintColor = .white
        close.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
        addSubview(label)
        addSubview(close)
        label.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.top.bottom.equalToSuperview().inset(8)
        }
        close.snp.makeConstraints { make in
            make.leading.equalTo(label.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }
    }

    @objc private func closeTapped() { onClose?() }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
