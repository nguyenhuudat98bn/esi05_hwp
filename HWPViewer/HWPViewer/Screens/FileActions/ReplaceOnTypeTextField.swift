//
//  ReplaceOnTypeTextField.swift
//  HWPViewer
//
//  Text field that can stand in for "whole text selected" where UIKit will not keep a selection:
//  on iOS 16 the rename field's select-all is collapsed back to a caret whatever we do (ESI05-39).
//  `showsWholeTextSelected()` paints the text like a selection, and the first input — a typed
//  character, the start of a Korean / Vietnamese composition, or Delete — replaces the whole text,
//  as it would with a real selection. Moving the caret by hand ends it.
//

import UIKit

final class ReplaceOnTypeTextField: UITextField {
    private(set) var replacesOnFirstInput = false
    /// Set while this class changes text / selection itself, so it does not count as the user's move.
    private var isAdjusting = false

    /// Paints the whole text as selected and arms replace-on-first-input.
    func showsWholeTextSelected() {
        guard let text, !text.isEmpty else { return }
        isAdjusting = true
        var attributes = defaultTextAttributes
        attributes[.backgroundColor] = tintColor.withAlphaComponent(0.25)
        attributedText = NSAttributedString(string: text, attributes: attributes)
        selectedTextRange = textRange(from: endOfDocument, to: endOfDocument)
        isAdjusting = false
        replacesOnFirstInput = true
    }

    /// The user placed the caret somewhere: keep the text, drop the painted selection.
    func selectionDidChangeByUser() {
        guard replacesOnFirstInput, !isAdjusting else { return }
        disarm(clearingText: false)
    }

    override func insertText(_ text: String) {
        if replacesOnFirstInput { disarm(clearingText: true) }
        super.insertText(text)
    }

    override func setMarkedText(_ markedText: String?, selectedRange: NSRange) {
        if replacesOnFirstInput { disarm(clearingText: true) }
        super.setMarkedText(markedText, selectedRange: selectedRange)
    }

    override func deleteBackward() {
        if replacesOnFirstInput {
            disarm(clearingText: true)
            sendActions(for: .editingChanged)
            return
        }
        super.deleteBackward()
    }

    override func paste(_ sender: Any?) {
        if replacesOnFirstInput { disarm(clearingText: true) }
        super.paste(sender)
    }

    private func disarm(clearingText: Bool) {
        replacesOnFirstInput = false
        isAdjusting = true
        let caret = selectedTextRange
        attributedText = NSAttributedString(string: clearingText ? "" : (text ?? ""), attributes: defaultTextAttributes)
        typingAttributes = defaultTextAttributes
        if !clearingText, let caret { selectedTextRange = caret } // keep where the user put it
        isAdjusting = false
    }
}
