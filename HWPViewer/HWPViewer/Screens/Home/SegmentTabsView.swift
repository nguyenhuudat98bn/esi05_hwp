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
        stack.distribution = .fillEqually
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview() }
        for (index, title) in titles.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = AppFonts.semibold(14)
            button.tag = index
            button.addTarget(self, action: #selector(tapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(button)
            buttons.append(button)
        }
        let line = UIView()
        line.backgroundColor = AppColors.divider
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }
        indicator.backgroundColor = AppColors.primary
        indicator.layer.cornerRadius = 1.5
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
            button.setTitleColor(i == index ? AppColors.primary : AppColors.textSecondary, for: .normal)
        }
        let target = buttons[index]
        indicator.snp.remakeConstraints { make in
            make.bottom.equalToSuperview()
            make.height.equalTo(3)
            make.centerX.equalTo(target)
            make.width.equalTo(target).multipliedBy(0.6)
        }
        if animated {
            UIView.animate(withDuration: 0.22) { self.layoutIfNeeded() }
        }
    }
}
