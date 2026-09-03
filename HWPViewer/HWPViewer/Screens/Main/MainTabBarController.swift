//
//  MainTabBarController.swift
//  HWPViewer
//
//  Root after onboarding: Home (All File) / Tools / Settings with a floating pill tab bar (Figma B1).
//

import UIKit
import SnapKit
import Combine
import SPNComponent

final class MainTabBarController: UITabBarController {
    enum Tab: Int, CaseIterable {
        case home, tools, settings

        var title: String {
            switch self {
            case .home: return L10n.mainTabAllFile
            case .tools: return L10n.mainTabTools
            case .settings: return L10n.mainTabSettings
            }
        }

        var icon: UIImage? {
            switch self {
            case .home: return Asset.Assets.App.icTabHomeFilled.image
            case .tools: return Asset.Assets.App.icTabTools.image
            case .settings: return Asset.Assets.App.icTabSettingsFilled.image
            }
        }
    }

    let pillTabBar = PillTabBar(tabs: Tab.allCases)
    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()
        tabBar.isHidden = true
        delegate = self
        viewControllers = [
            HomeViewController(),
            ToolsViewController(),
            SettingsViewController(),
        ]
        view.addSubview(pillTabBar)
        pillTabBar.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.width.equalTo(AppMetrics.tabBarWidth)
            make.bottom.equalToSuperview().inset(8 + 34)
            make.height.equalTo(AppMetrics.tabBarHeight)
        }
        pillTabBar.onSelect = { [weak self] tab in
            self?.selectedIndex = tab.rawValue
        }
        pillTabBar.select(.home, animated: false)
        additionalSafeAreaInsets.bottom = AppMetrics.tabBarHeight + 8
    }

    override func viewSafeAreaInsetsDidChange() {
        super.viewSafeAreaInsetsDidChange()
        // Our own safe area already includes `additionalSafeAreaInsets`; pin to the window inset instead.
        let windowBottom = view.safeAreaInsets.bottom - additionalSafeAreaInsets.bottom
        pillTabBar.snp.updateConstraints { make in
            make.bottom.equalToSuperview().inset(max(windowBottom, 8) + 8)
        }
    }

    func setPillTabBarHidden(_ hidden: Bool, animated: Bool = true) {
        let block = { self.pillTabBar.alpha = hidden ? 0 : 1 }
        animated ? UIView.animate(withDuration: 0.2, animations: block) : block()
        pillTabBar.isUserInteractionEnabled = !hidden
    }

    override var selectedIndex: Int {
        didSet {
            if let tab = Tab(rawValue: selectedIndex) { pillTabBar.select(tab, animated: true) }
        }
    }
}

extension MainTabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if let tab = Tab(rawValue: selectedIndex) { pillTabBar.select(tab, animated: true) }
    }
}

// MARK: - PillTabBar

final class PillTabBar: UIView {
    var onSelect: ((MainTabBarController.Tab) -> Void)?

    private let tabs: [MainTabBarController.Tab]
    private var items: [PillTabItem] = []
    private let stack = UIStackView()

    init(tabs: [MainTabBarController.Tab]) {
        self.tabs = tabs
        super.init(frame: .zero)
        backgroundColor = AppColors.surface
        layer.cornerRadius = AppMetrics.tabBarHeight / 2
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 20
        layer.shadowOffset = CGSize(width: 0, height: 8)

        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 0
        addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)) }

        for tab in tabs {
            let item = PillTabItem(tab: tab)
            item.addTarget(self, action: #selector(itemTapped(_:)), for: .touchUpInside)
            stack.addArrangedSubview(item)
            items.append(item)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    @objc private func itemTapped(_ sender: PillTabItem) {
        select(sender.tab, animated: true)
        onSelect?(sender.tab)
    }

    func select(_ tab: MainTabBarController.Tab, animated: Bool) {
        let block = {
            self.items.forEach { $0.setSelected($0.tab == tab) }
            self.stack.layoutIfNeeded()
        }
        animated ? UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseOut], animations: block) : block()
    }
}

final class PillTabItem: UIControl {
    let tab: MainTabBarController.Tab
    private let iconView = UIImageView()
    private let label = UILabel()
    private let content = UIStackView()

    init(tab: MainTabBarController.Tab) {
        self.tab = tab
        super.init(frame: .zero)
        layer.cornerRadius = (AppMetrics.tabBarHeight - 8) / 2
        iconView.image = tab.icon?.withRenderingMode(.alwaysTemplate)
        iconView.contentMode = .scaleAspectFit
        iconView.snp.makeConstraints { $0.size.equalTo(24) }
        label.text = tab.title
        label.font = AppFonts.semibold(10)
        content.axis = .vertical
        content.spacing = 2
        content.alignment = .center
        content.isUserInteractionEnabled = false
        content.addArrangedSubview(iconView)
        content.addArrangedSubview(label)
        addSubview(content)
        content.snp.makeConstraints { $0.center.equalToSuperview() }
        setSelected(false)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    func setSelected(_ selected: Bool) {
        backgroundColor = selected ? AppColors.tabBarSelected : .clear
        iconView.tintColor = selected ? AppColors.tabActive : AppColors.textTabInactive
        label.textColor = selected ? AppColors.tabActive : AppColors.textTabInactive
    }
}
