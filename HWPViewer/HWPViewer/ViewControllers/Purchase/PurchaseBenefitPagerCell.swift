//
//  PurchaseBenefitPagerCell.swift
//  HWPViewer
//
//  Created by Eragon on 26/8/25.
//

import SPNComponent
import Foundation
import UIKit
import SnapKit
import FSPagerView

class PurchaseBenefitPagerCell: FSPagerViewCell {
    
    /// cell identifier
    static var identifier: String {
        return String(describing: self)
    }
    
    // MARK: - Controls
    private lazy var container: UIView = {
        let _view = UIView()
        _view.backgroundColor = .clear
        _view.clipsToBounds = true
        return _view
    }()
    
    private lazy var contentImageView: UIImageView = {
        let _imageView = UIImageView()
        _imageView.backgroundColor = .clear
        _imageView.contentMode = .scaleAspectFit
        return _imageView
    }()
    
    private lazy var titleLabel: UILabel = {
        let _label = UILabel()
        _label.textAlignment = .center
        _label.textColor = UIColor(0xFFFFFF)
        _label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return _label
    }()
    
    //MARK: - Properties
    
    //MARK: - Lifecycles
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    //MARK: - Funtions
    private func setupViews() {
        self.backgroundColor = .clear
        contentView.backgroundColor = .clear
        contentView.layer.shadowOpacity = 0
        contentView.addFilledSubview(container)
        
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.centerX.equalToSuperview().offset(15)
        }
        
        container.addSubview(contentImageView)
        contentImageView.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(titleLabel.snp.leading).offset(-5)
        }
        
    }
    
    func configure(with data: BenefitsData) {
        titleLabel.text = data.title
        contentImageView.image = data.icon
    }
}
