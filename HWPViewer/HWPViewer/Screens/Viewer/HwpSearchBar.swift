//
//  HwpSearchBar.swift
//  HWPViewer
//
//  In-document search overlay replacing the viewer header: close, field, "n" results, prev / next.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class HwpSearchBar: UIView {
    var onQueryChanged: ((String) -> Void)?
    var onPrev: (() -> Void)?
    var onNext: (() -> Void)?
    var onCancel: (() -> Void)?

    private let querySubject = PassthroughSubject<String, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let textField = UITextField()
    private let resultsLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = AppColors.surface

        let cancelButton = button(Asset.Assets.App.icAngleLeft.image) { [weak self] in self?.cancel() }
        let field = UIView()
        field.backgroundColor = AppColors.surfaceMuted
        field.layer.cornerRadius = 20
        let icon = UIImageView(image: Asset.Assets.App.icSearch.image.withRenderingMode(.alwaysTemplate))
        icon.tintColor = AppColors.textTertiary
        icon.contentMode = .scaleAspectFit
        textField.placeholder = L10n.viewerSearchPlaceholder
        textField.font = AppFonts.regular(14)
        textField.textColor = AppColors.textDark
        textField.returnKeyType = .search
        textField.autocorrectionType = .no
        textField.clearButtonMode = .whileEditing
        textField.delegate = self
        field.addSubview(icon)
        field.addSubview(textField)
        icon.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        textField.snp.makeConstraints { make in
            make.leading.equalTo(icon.snp.trailing).offset(8)
            make.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        resultsLabel.text = "0"
        resultsLabel.font = AppFonts.regular(14)
        resultsLabel.textColor = AppColors.textPrimary
        let prev = button(UIImage(systemName: "chevron.up")) { [weak self] in self?.onPrev?() }
        let next = button(UIImage(systemName: "chevron.down")) { [weak self] in self?.onNext?() }

        let stack = UIStackView(arrangedSubviews: [cancelButton, field, resultsLabel, prev, next])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.setCustomSpacing(10, after: field)
        addSubview(stack)
        stack.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(8)
            make.top.bottom.equalToSuperview()
        }
        field.snp.makeConstraints { $0.height.equalTo(40) }
        [cancelButton, prev, next].forEach { $0.snp.makeConstraints { $0.size.equalTo(36) } }

        let line = UIView()
        line.backgroundColor = AppColors.divider
        addSubview(line)
        line.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1)
        }

        textField.textPublisher.map { $0 ?? "" }
            .sink { [weak self] in self?.querySubject.send($0) }
            .store(in: &cancellables)
        querySubject
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] query in self?.onQueryChanged?(query) }
            .store(in: &cancellables)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func button(_ image: UIImage?, action: @escaping () -> Void) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(image?.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = AppColors.textPrimary
        button.tapPublisher.receive(on: DispatchQueue.main).sink { _ in action() }.store(in: &cancellables)
        return button
    }

    private func cancel() {
        reset()
        onCancel?()
    }

    func setResultCount(_ count: Int) { resultsLabel.text = "\(count)" }
    func showKeyboard() { textField.becomeFirstResponder() }

    func reset() {
        textField.text = nil
        textField.resignFirstResponder()
        resultsLabel.text = "0"
    }
}

extension HwpSearchBar: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
