//
//  SegmentTabsView.swift
//  HWPViewer
//
//  "My File / Recent / Bookmark" underline tabs (Figma B1).
//

import UIKit
import SnapKit

final class SegmentTabsView: UIView {
    var onSelect: ((Int) -> Void)?
    private(set) var selectedIndex = 0

    private var buttons: [UIButton] = []
    private let indicator = UIView()
    private let stack = UIStackView()

    init(titles: [String]) {
        super.init(frame: .zero)
        stack.axis = .horizontal
        stack.spacing = 36
        stack.alignment = .center
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.top.bottom.equalToSuperview()
            make.trailing.lessThanOrEqualToSuperview()
        }
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = AppFonts.medium(15)
            button.tag = index
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
            buttons.append(button)
        }
        indicator.backgroundColor = AppColors.primary
        indicator.layer.cornerRadius = 1
        addSubview(indicator)
        select(0, animated: false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func tapped(_ sender: UIButton) {
        select(sender.tag, animated: true)
        onSelect?(sender.tag)
    }

    func select(_ index: Int, animated: Bool) {
        selectedIndex = index
        for (i, button) in buttons.enumerated() {
            button.setTitleColor(i == index ? AppColors.primary : AppColors.textSegmentInactive, for: .normal)
        }
        let target = buttons[index]
        indicator.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(2)
            make.leading.trailing.equalTo(target)
        }
        if animated {
            UIView.animate(withDuration: 0.22) { self.layoutIfNeeded() }
        }
    }
}
