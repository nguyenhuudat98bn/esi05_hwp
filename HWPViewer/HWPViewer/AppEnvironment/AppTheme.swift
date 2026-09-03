//
//  AppTheme.swift
//  HWPViewer
//
//  Brand tokens for this app. `primary` follows remote `appconfigs.main_color` when present.
//

import UIKit
import SPNComponent

enum AppTheme {
    static let fallbackPrimary = UIColor(0x2E90FA)

    /// Builds the theme from the current remote snapshot (defaults before the first fetch).
    static func make() -> SPNTheme {
        var theme = SPNTheme()
        theme.primary = UIColor.spnColor(hex: SPNRemoteConfig.current.appConfigs.mainColor, fallback: fallbackPrimary)
        theme.onPrimary = .white
        theme.background = .white
        theme.cardBackground = .white
        theme.mainText = UIColor(0x181D27)
        theme.secondaryText = UIColor(0x717680)
        theme.border = UIColor(0xCECFD2)
        theme.disabled = UIColor(0x9E9E9E)
        return theme
    }

    /// Re-applies remote `main_color` after a fetch so screens created later pick it up.
    static func refreshFromRemote() {
        SPNTheme.current.primary = UIColor.spnColor(hex: SPNRemoteConfig.current.appConfigs.mainColor, fallback: fallbackPrimary)
    }
}
