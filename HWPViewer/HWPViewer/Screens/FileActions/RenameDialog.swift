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
    private let requiresChange: Bool
    /// Cleared as soon as the user types, so the auto-selection can never wipe out their input.
    private var canAutoSelectName = true
    /// Auto-selection only applies while the dialog is settling; after that the caret is the user's.
    private var autoSelectDeadline = Date.distantPast
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

    /// - Parameter requiresChange: `true` (rename) keeps OK disabled until the name actually differs;
    ///   `false` (convert output name) accepts the suggested name as-is.
    init(title: String = L10n.renameTitle, initialName: String, confirmTitle: String = L10n.popupOk, requiresChange: Bool = false) {
        self.initialName = initialName
        self.titleText = title
        self.confirmTitle = confirmTitle
        self.requiresChange = requiresChange
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
        okButton.setTitleColor(.white, for: .disabled)
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
            .sink { [weak self] _ in
                self?.canAutoSelectName = false
                self?.validate()
            }.store(in: &cancellables)

        // iOS 16 finishes placing its caret after `textFieldDidBeginEditing` returns *and* after
        // the runloop hop below, so the selection only survives once the keyboard is actually up.
        NotificationCenter.default.publisher(for: UIResponder.keyboardDidShowNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self, self.isAutoSelecting else { return }
                self.selectWholeName()
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: UIResponder.keyboardWillChangeFrameNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] note in self?.adjustForKeyboard(note) }
            .store(in: &cancellables)

        validate()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        autoSelectDeadline = Date().addingTimeInterval(1)
        textField.becomeFirstResponder()
        // Last pass once the keyboard's presentation animation is over — on iOS 16 nothing applied
        // before that point survives.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in self?.selectWholeName() }
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
        let enabled = !name.isEmpty && error == nil && !(requiresChange && name == initialName)
        errorLabel.text = error
        errorLabel.isHidden = error == nil
        fieldContainer.layer.borderColor = (error != nil ? AppColors.danger : (name.isEmpty ? AppColors.border : AppColors.primary)).cgColor
        okButton.isEnabled = enabled
        // Figma 18183:97170 — disabled OK is #CECFD2 with the label still white.
        okButton.backgroundColor = enabled ? AppColors.primary : AppColors.buttonDisabled
    }

    /// Selects the whole name so typing replaces it (the extension is not shown).
    ///
    /// Applied from several points because UIKit sets its own caret while the editing session
    /// starts and discards anything set before that finishes: the delegate callback, the moment the
    /// keyboard is up, once its animation has settled, and again whenever the selection collapses.
    /// `autoSelectDeadline` limits all of that to the first second, so a user placing their own
    /// caret afterwards is left alone.
    ///
    /// KNOWN GAP (ESI05-39): this holds on iOS 17+ but NOT on iOS 16, where UIKit collapses the
    /// selection back to a caret at the end no matter which of these points sets it. Verified on an
    /// iOS 16.4 simulator against `selectedTextRange`, `selectAll(_:)`, and both together.
    private func selectWholeName() {
        guard canAutoSelectName else { return }
        let field = textField
        field.selectedTextRange = field.textRange(from: field.beginningOfDocument,
                                                  to: field.endOfDocument)
        field.selectAll(nil)
    }

    private var isAutoSelecting: Bool {
        canAutoSelectName && Date() < autoSelectDeadline
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
    func textFieldDidBeginEditing(_ textField: UITextField) {
        selectWholeName()
    }

    func textFieldDidChangeSelection(_ textField: UITextField) {
        // Fired when UIKit collapses the selection it just took from us; put it back.
        guard isAutoSelecting, textField.selectedTextRange?.isEmpty ?? true,
              !(textField.text ?? "").isEmpty else { return }
        DispatchQueue.main.async { [weak self] in self?.selectWholeName() }
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        confirm()
        return true
    }
}
