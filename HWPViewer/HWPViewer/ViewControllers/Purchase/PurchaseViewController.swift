//
//  PurchaseViewController.swift
//  HWPViewer
//
//  Created by Eragon on 25/8/25.
//

import SPNComponent
import UIKit
import Combine
import CombineCocoa

enum BenefitsData: Equatable {
    case benefit1
    case benefit2
    case benefit3
    case benefit4
    case benefit5
    
    var title: String {
        switch self {
        case .benefit1:
            return L10n.purchaseBenefit1
        case .benefit2:
            return L10n.purchaseBenefit2
        case .benefit3:
            return L10n.purchaseBenefit3
        case .benefit4:
            return L10n.purchaseBenefit4
        case .benefit5:
            return L10n.purchaseBenefit5
        }
    }
    
    var icon: UIImage? {
        switch self {
        case .benefit1:
            return UIImage(resource: .icBenefitEdit)
        case .benefit2:
            return UIImage(resource: .icBenefitSign)
        case .benefit3:
            return UIImage(resource: .icBenefitConvert)
        case .benefit4:
            return UIImage(resource: .icBenefitAdvanced)
        case .benefit5:
            return UIImage(resource: .icBenefitRemoveAds)
        }
    }
}

protocol IAPVCEvent: AnyObject {
    func dismiss()
    func dismissWhenPurchased()
}

class PurchaseViewController: UIViewController {
    
    // MARK: - Controls
    private lazy var background: UIImageView = {
        let _imageView = UIImageView()
        _imageView.image = UIImage(resource: .bgPurchase)
        _imageView.contentMode = .scaleAspectFill
        return _imageView
    }()
    
    private lazy var navigationContainer: UIView = {
        let _view = UIView()
        _view.backgroundColor = .clear
        return _view
    }()
    
    private lazy var btnClose: UIButton = {
        let _button = UIButton(type: .system)
        _button.backgroundColor = .clear
        _button.setImage(UIImage(resource: .icClose).withRenderingMode(.alwaysOriginal), for: .normal)
        return _button
    }()
    
    private lazy var btnRestore: UIButton = {
        let _button = UIButton(type: .system)
        _button.backgroundColor = .clear
        _button.setTitle(L10n.purchaseButtonRestore, for: .normal)
        _button.setTitleColor(UIColor(0xFFFFFF), for: .normal)
        _button.titleLabel?.font = .systemFont(ofSize: 14, weight: .regular)
        return _button
    }()

    //MARK: - Properties
    var onDismissed: (() -> Void)? = nil
    weak var delegate: IAPVCEvent?
    private var cancellables = Set<AnyCancellable>()
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - Lifecycles
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        bindActions()
    }
}

// MARK: - Setup views
extension PurchaseViewController {
    private func setupViews() {
        view.backgroundColor = .white
        setupLayout()
    }
    
    private func setupLayout() {
        view.addSubview(background)
        background.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        view.addSubview(navigationContainer)
        navigationContainer.snp.makeConstraints { make in
            make.height.equalTo(64)
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }
        
        navigationContainer.addSubview(btnClose)
        btnClose.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.width.equalTo(64)
        }
        
        navigationContainer.addSubview(btnRestore)
        btnRestore.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.trailing.equalToSuperview().inset(24)
        }
    }
}

extension PurchaseViewController {
    private func bindActions() {
        btnClose.tapPublisher
            .debounce(for: .seconds(0.35), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.dismiss(animated: true) { [weak self] in
                    self?.delegate?.dismiss()
                }
            }
            .store(in: &cancellables)
    }
}
