//
//  AppConstants.swift
//  HWPViewer
//
//  App-level constants and thin aliases over SPNComponent so feature code reads naturally.
//

import UIKit
import SPNComponent

let appStoreUrl = "https://apps.apple.com/app/id0000000000" // TODO: real App Store id
let privacyUrl = "https://sites.google.com/view/supernova-privacy-policy" // TODO: confirm
let termOfUseUrl = "https://sites.google.com/view/supernova-terms-of-use" // TODO: confirm
let actionWhenPurchaseCompleted = Notification.Name("ActionWhenPurchaseCompleted")

/// Session state now lives in the package; keep the old name for feature code.
typealias ApplicationSession = SPNSession

/// Brand colors come from `SPNTheme.current` (set in `AppTheme`).
var mainColor: UIColor { SPNTheme.current.primary }
var mainTextColor: UIColor { SPNTheme.current.mainText }

enum AppColor {
    static let mainText = UIColor(hex: "181D27")
}
