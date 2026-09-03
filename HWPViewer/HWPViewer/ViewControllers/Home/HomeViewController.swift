//
//  HomeViewController.swift
//  HWPViewer
//
//  Created by datnh on 01/4/25.
//

import UIKit
import SnapKit
import Combine
import SPNComponent

final class HomeViewController: SPNBaseViewController {
    // MARK: - Controls
    private let contentView = UIView()

    // MARK: - Init
    init() {
        super.init(
            place: .home,
            navigationConfigs: SPNNavigationConfiguration(
                title: L10n.homeTitle,
                hasBackButton: false
            )
        )
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var hidesBottomBarByDefault: Bool { false }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupAdvertiser(on: .home)
        SPNSession.shared.isFirstTimeOnboard = false
    }

    private func setupViews() {
        containerStackView.addArrangedSubview(contentView)
        containerStackView.addArrangedSubview(nativeAdSlot)
        containerStackView.addArrangedSubview(footerView)
        footerView.snp.makeConstraints { $0.height.equalTo(view.safeAreaInsets.bottom) }
    }
}
