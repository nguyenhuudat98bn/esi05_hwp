//
//  AppConstants.swift
//  HWPViewer
//
//  App-level constants and thin aliases over SPNComponent so feature code reads naturally.
//

import UIKit
import SPNComponent

let appStoreUrl = "https://apps.apple.com/us/app/hwp-viewer-hangul-reader/id6808507107"
let privacyUrl = "https://sites.google.com/view/hwpviewer-hangulreader-privacy"
let termOfUseUrl = "https://sites.google.com/view/hwpviewer-hangulreader-terms"
let actionWhenPurchaseCompleted = Notification.Name("ActionWhenPurchaseCompleted")

/// Session state now lives in the package; keep the old name for feature code.
typealias ApplicationSession = SPNSession

/// Brand colors come from `SPNTheme.current` (set in `AppTheme`).
var mainColor: UIColor { SPNTheme.current.primary }
var mainTextColor: UIColor { SPNTheme.current.mainText }

enum AppColor {
    static let mainText = UIColor(hex: "181D27")
}
