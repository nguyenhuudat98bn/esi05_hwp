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

/// AdMob test devices. A newly created ad unit serves nothing for a while ("No ad to show"), which
/// looks identical to a broken integration — registering a device here makes AdMob return test ads
/// through the *real* unit ids, so the wiring can be verified immediately. The id is printed by the
/// SDK on launch ("To get test ads on this device, set: ...").
///
/// Only applied to non-App-Store builds. Leave empty to see real ads.
let adMobTestDeviceIDs: [String] = []

/// Session state now lives in the package; keep the old name for feature code.
typealias ApplicationSession = SPNSession

/// Brand colors come from `SPNTheme.current` (set in `AppTheme`).
var mainColor: UIColor { SPNTheme.current.primary }
var mainTextColor: UIColor { SPNTheme.current.mainText }

enum AppColor {
    static let mainText = UIColor(hex: "181D27")
}
