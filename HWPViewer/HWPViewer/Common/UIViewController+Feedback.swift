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

    /// Bottom toast (Figma "Press and hold to select text" style): dark pill, auto hides.
    func showToast(_ message: String, duration: TimeInterval = 2.0, bottomInset: CGFloat = 96) {
        guard let host = view.window ?? view else { return }
        host.subviews.filter { $0.tag == ToastView.tag }.forEach { $0.removeFromSuperview() }
        let toast = ToastView(message: message)
        host.addSubview(toast)
        toast.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.leading.greaterThanOrEqualToSuperview().inset(24)
            make.bottom.equalTo(host.safeAreaLayoutGuide).inset(bottomInset)
        }
        toast.alpha = 0
        UIView.animate(withDuration: 0.2) { toast.alpha = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            UIView.animate(withDuration: 0.25, animations: { toast.alpha = 0 }) { _ in toast.removeFromSuperview() }
        }
    }
}

final class ToastView: UIView {
    static let tag = 0x70A57

    init(message: String) {
        super.init(frame: .zero)
        tag = Self.tag
        backgroundColor = AppColors.primary
        layer.cornerRadius = 20
        let label = UILabel()
        label.text = message
        label.textColor = .white
        label.font = AppFonts.medium(14)
        label.numberOfLines = 0
        label.textAlignment = .center
        addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 10, left: 18, bottom: 10, right: 18))
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
}
