//
//  AppRemoteConfigs.swift
//  HWPViewer
//
//  App-only remote config keys (`app_extra_configs`): font CDN, gift box, premium gating.
//

import Foundation

struct AppRemoteConfigs: Codable {
    var hwpFontsBaseUrl: String?
    var editRequiresPremium: Bool?
    var convertRequiresPremium: Bool?
    var giftBoxEnabled: Bool?
    var giftBoxCountdownSeconds: Int?

    enum CodingKeys: String, CodingKey {
        case hwpFontsBaseUrl = "hwp_fonts_base_url"
        case editRequiresPremium = "edit_requires_premium"
        case convertRequiresPremium = "convert_requires_premium"
        case giftBoxEnabled = "gift_box_enabled"
        case giftBoxCountdownSeconds = "gift_box_countdown_seconds"
    }

    static var current: AppRemoteConfigs {
        FirebaseRemoteConfigStore.shared.value("app_extra_configs", as: AppRemoteConfigs.self) ?? AppRemoteConfigs()
    }

    /// Decided 2026-09-03: Edit HWP is free (remote knob kept for A/B later).
    var isEditPremium: Bool { editRequiresPremium ?? false }
    var isConvertPremium: Bool { convertRequiresPremium ?? true }
}
