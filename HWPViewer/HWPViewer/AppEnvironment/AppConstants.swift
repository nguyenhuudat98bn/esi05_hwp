//
//  AppConstants.swift
//  HWPViewer
//
//  App-level constants and thin aliases over SPNComponent so feature code reads naturally.
//

import UIKit
import SPNComponent

let appStoreUrl = ""
let privacyUrl = ""
let termOfUseUrl = ""
let actionWhenPurchaseCompleted = Notification.Name("ActionWhenPurchaseCompleted")

/// Session state now lives in the package; keep the old name for feature code.
typealias ApplicationSession = SPNSession

/// Brand colors come from `SPNTheme.current` (set in `AppTheme`).
var mainColor: UIColor { SPNTheme.current.primary }
var mainTextColor: UIColor { SPNTheme.current.mainText }

enum AppColor {
    static let mainText = UIColor(hex: "000D1A")
}
