//
//  RenameDialog.swift
//  HWPViewer
//
//  Rename popup (Figma E2): text field, inline error ("This name already exists"), Cancel / OK.
//  OK is disabled while the name is empty or invalid.
//

import UIKit
import SnapKit
import Combine
import CombineCocoa
import SPNComponent

final class RenameDialog: UIViewController {
    /// Returns nil when valid, or an error message.
    var validator: ((String) -> String?)?
    var onConfirm: ((String) -> Void)?

    private let initialName: String
    private let titleText: String
    private let confirmTitle: String
    private let dimView = UIView()
    private let card = UIView()
    private let textField = UITextField()
    private let fieldContainer = UIView()
    private let errorLabel = UILabel()
    private let okButton = UIButton(type: .system)
    private var cancellables = Set<AnyCancellable>()
    private var cardBottomConstraint: Constraint?

    init(title: String = L10n.renameTitle, initialName: String, confirmTitle: String = L10n.popupOk) {
        self.initialName = initialName
        self.titleText = title
        self.confirmTitle = confirmTitle
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        dimView.backgroundColor = AppColors.dim
        view.addSubview(dimView)
        dimView.snp.makeConstraints { $0.edges.equalToSuperview() }

        card.backgroundColor = AppColors.surface
        card.layer.cornerRadius = 28
        view.addSubview(card)
        card.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(28)
            make.centerY.equalToSuperview().offset(-40)
        }

        let titleLabel = UILabel()
        titleLabel.text = titleText
        titleLabel.font = AppFonts.medium(20)
        titleLabel.textColor = AppColors.textPrimary
        titleLabel.textAlignment = .left

        fieldContainer.layer.cornerRadius = 12
        fieldContainer.layer.borderWidth = 1
        fieldContainer.backgroundColor = AppColors.surface
        textField.text = initialName
        textField.placeholder = L10n.renamePlaceholder
        textField.font = AppFonts.medium(14)
        textField.textColor = AppColors.textPrimary
        textField.clearButtonMode = .whileEditing
        textField.returnKeyType = .done
        textField.autocorrectionType = .no
        textField.delegate = self
        fieldContainer.addSubview(textField)
        textField.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 10)) }
        fieldContainer.snp.makeConstraints { $0.height.equalTo(48) }

        errorLabel.font = AppFonts.regular(12)
        errorLabel.textColor = AppColors.danger
        errorLabel.numberOfLines = 0
        errorLabel.isHidden = true

        let cancelButton = UIButton(type: .system)
        cancelButton.setTitle(L10n.popupCancel, for: .normal)
        cancelButton.titleLabel?.font = AppFonts.medium(16)
        cancelButton.setTitleColor(AppColors.textPrimary, for: .normal)
        cancelButton.backgroundColor = AppColors.surfaceMuted
        cancelButton.layer.cornerRadius = 22
        okButton.setTitle(confirmTitle, for: .normal)
        okButton.titleLabel?.font = AppFonts.medium(16)
        okButton.setTitleColor(.white, for: .normal)
        okButton.layer.cornerRadius = 22
        let buttons = UIStackView(arrangedSubviews: [cancelButton, okButton])
        buttons.axis = .horizontal
        buttons.spacing = 16
        buttons.distribution = .fillEqually
        buttons.snp.makeConstraints { $0.height.equalTo(44) }

        let stack = UIStackView(arrangedSubviews: [titleLabel, fieldContainer, errorLabel, buttons])
        stack.axis = .vertical
        stack.spacing = 8
        stack.setCustomSpacing(16, after: titleLabel)
        stack.setCustomSpacing(16, after: errorLabel)
        card.addSubview(stack)
        stack.snp.makeConstraints { $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 24, left: 16, bottom: 16, right: 16)) }

        cancelButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.dismissDialog(nil) }.store(in: &cancellables)
        okButton.tapPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.confirm() }.store(in: &cancellables)
        textField.textPublisher.receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.validate() }.store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in self?.adjustForKeyboard(note) }
            .store(in: &cancellables)

        validate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textField.becomeFirstResponder()
        // Select the name so typing replaces it (extension is not shown).
        textField.selectAll(nil)
    }

    private var currentName: String { (textField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines) }

    private func validate() {
        let name = currentName
        var error: String?
        if name.isEmpty {
            error = nil
        } else {
            error = validator?(name)
        }
        let enabled = !name.isEmpty && error == nil
        errorLabel.text = error
        errorLabel.isHidden = error == nil
        fieldContainer.layer.borderColor = (error != nil ? AppColors.danger : (name.isEmpty ? AppColors.border : AppColors.primary)).cgColor
        okButton.isEnabled = enabled
        okButton.backgroundColor = enabled ? AppColors.primary : AppColors.primary.withAlphaComponent(0.35)
    }

    private func confirm() {
        guard okButton.isEnabled else { return }
        let name = currentName
        dismissDialog { self.onConfirm?(name) }
    }

    private func dismissDialog(_ completion: (() -> Void)?) {
        textField.resignFirstResponder()
        dismiss(animated: true) { completion?() }
    }

    private func adjustForKeyboard(_ note: Notification) {
        guard let frame = (note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue else { return }
        let keyboardTop = view.bounds.height - frame.origin.y
        let overlap = max(0, keyboardTop - (view.bounds.height / 2 - 40 - card.bounds.height / 2) + 16)
        card.snp.updateConstraints { make in
            make.centerY.equalToSuperview().offset(-40 - overlap / 2)
        }
        UIView.animate(withDuration: 0.25) { self.view.layoutIfNeeded() }
    }
}

extension RenameDialog: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirm()
        return true
    }
}
