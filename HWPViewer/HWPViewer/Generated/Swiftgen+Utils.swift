//
//  Swiftgen+Utils.swift
//  HWPViewer
//
//  SwiftGen lookup hook: resolves app strings in the language the user picked (SPNSession), not the OS locale.
//

import Foundation
import SPNComponent

func NSCustomLocalizedString(_ key: String, _ table: String, _ value: String) -> String {
    return key.localized
}
