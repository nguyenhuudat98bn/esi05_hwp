//
//  PurchaseProductCell.swift
//  HWPViewer
//
//  Created by Eragon on 26/8/25.
//

import SPNComponent
import UIKit
import SnapKit

class PurchaseProductCell: UITableViewCell {

    /// cell identifier
    static var identifier: String {
        return String(describing: self)
    }
    
    // MARK: - Controls
    private lazy var container: UIView = {
        let _view = UIView()
        _view.backgroundColor = .clear
        _view.clipsToBounds = true
        _view.cornerRadius = 28
        _view.borderWidth = 1.5
        return _view
    }()
    
    private lazy var mainStackView: UIStackView = {
        let _stackView = UIStackView()
        _stackView.backgroundColor = .clear
        _stackView.axis = .horizontal
        _stackView.spacing = 10
        _stackView.alignment = .center
        return _stackView
    }()
    
    private lazy var infoContainer: UIView = {
        let _view = UIView()
        _view.backgroundColor = .clear
        return _view
    }()
    
    private lazy var selectImageView: UIImageView = {
        let _imageView = UIImageView()
        return _imageView
    }()
    
    private lazy var nameLabel: UILabel = {
        let _label = UILabel()
        _label.textAlignment = .left
        _label.textColor = UIColor(0xFFFFFF)
        _label.font = UIFont.systemFont(ofSize: 13, weight: .medium)
        return _label
    }()
    
    private lazy var priceLabel: UILabel = {
        let _label = UILabel()
        _label.textAlignment = .left
        _label.textColor = UIColor(0xFFFFFF)
        _label.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
        return _label
    }()
    
    private lazy var separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(0xFFFFFF)
        return view
    }()
    
    private lazy var pricePerWeekLabel: UILabel = {
        let _label = UILabel()
        _label.textAlignment = .left
        _label.textColor = UIColor(0xFFFFFF)
        _label.font = UIFont.systemFont(ofSize: 12, weight: .regular)
        return _label
    }()
    
    private lazy var bestValueContainer: UIView = {
        let _view = UIView()
        _view.backgroundColor = .clear
        _view.cornerRadius = 12
        _view.clipsToBounds = true
        return _view
    }()
    
    private lazy var gradientImageView: UIImageView = {
        let _imageView = UIImageView(image: UIImage(resource: .bgBestValue))
        _imageView.contentMode = .scaleToFill
        return _imageView
    }()
    
    private lazy var bestValueLabel: UILabel = {
        let _label = UILabel()
        _label.textAlignment = .center
        _label.textColor = UIColor(0xFFFFFF)
        _label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        _label.text = "Best Value"
        return _label
    }()
    
    // MARK: - Initializer
    public override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
    }
    
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(15)
            make.bottom.equalToSuperview().inset(10)
            make.leading.trailing.equalToSuperview().inset(24)
            make.height.equalTo(56)
        }
        
        contentView.addSubview(bestValueContainer)
        bestValueContainer.snp.makeConstraints { make in
            make.centerY.equalTo(container.snp.top)
            make.trailing.equalTo(container.snp.trailing).inset(15)
            make.height.equalTo(24)
            make.width.greaterThanOrEqualTo(80)
        }
        
        bestValueContainer.addSubview(gradientImageView)
        gradientImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        bestValueContainer.addSubview(bestValueLabel)
        bestValueLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        
        container.addSubview(mainStackView)
        mainStackView.snp.makeConstraints { make in
            make.top.bottom.leading.equalToSuperview()
            make.trailing.equalToSuperview().inset(20)
        }
        
        [infoContainer, separatorView, pricePerWeekLabel].forEach {
            mainStackView.addArrangedSubview($0)
        }
        
        infoContainer.addSubview(selectImageView)
        selectImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.width.height.equalTo(24)
            make.centerY.equalToSuperview()
        }
        
        infoContainer.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(5)
            make.leading.equalTo(selectImageView.snp.trailing).offset(14)
        }
        
        infoContainer.addSubview(priceLabel)
        priceLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom)
            make.leading.equalTo(selectImageView.snp.trailing).offset(14)
            make.bottom.equalToSuperview().inset(5)
            make.height.equalTo(nameLabel.snp.height)
        }
        
        separatorView.snp.makeConstraints { make in
            make.width.equalTo(1)
            make.height.equalTo(30)
        }
    }
    
    func displayCell(_ product: Product, isSelected: Bool) {
        selectImageView.image = isSelected ? UIImage(resource: .icRadioSelected).withTintColor(mainColor) : UIImage(resource: .icRadioUnselected)
        nameLabel.text = product.name
        priceLabel.text = product.price
        pricePerWeekLabel.text = product.pricePerWeek
        container.backgroundColor = isSelected ? UIColor(0x738E9C99).withAlphaComponent(0.6) : .clear
        container.layer.borderColor = isSelected ? mainColor.cgColor : UIColor(0xFFFFFF).cgColor
        bestValueContainer.isHidden = !product.isBestValue
    }
}
