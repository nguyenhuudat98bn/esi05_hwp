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
    var ratePrompt: RatePromptConfig?

    enum CodingKeys: String, CodingKey {
        case hwpFontsBaseUrl = "hwp_fonts_base_url"
        case editRequiresPremium = "edit_requires_premium"
        case convertRequiresPremium = "convert_requires_premium"
        case giftBoxEnabled = "gift_box_enabled"
        case giftBoxCountdownSeconds = "gift_box_countdown_seconds"
        case ratePrompt = "rate_prompt"
    }

    static var current: AppRemoteConfigs {
        FirebaseRemoteConfigStore.shared.value("app_extra_configs", as: AppRemoteConfigs.self) ?? AppRemoteConfigs()
    }

    /// Decided 2026-09-03: Edit HWP is free (remote knob kept for A/B later).
    var isEditPremium: Bool { editRequiresPremium ?? false }
    var isConvertPremium: Bool { convertRequiresPremium ?? true }
    /// Missing key → disabled (code defaults are the safe side; DefaultConfigs.json carries the live values).
    var rate: RatePromptConfig { ratePrompt ?? RatePromptConfig() }
}

/// `app_extra_configs.rate_prompt` — gates for the system rating sheet (docs/flows/rate-app-prompt.md).
struct RatePromptConfig: Codable {
    var enabledRaw: Bool?
    var versionRaw: Int?
    var minSessionsRaw: Int?
    var minDaysSinceInstallRaw: Int?
    var minSuccessEventsRaw: Int?
    var maxPromptsTotalRaw: Int?
    var cooldownDaysRaw: Int?
    var adGapSecondsRaw: Int?
    var delaySecondsRaw: Double?
    var triggersRaw: [String]?

    enum CodingKeys: String, CodingKey {
        case enabledRaw = "enabled"
        case versionRaw = "version"
        case minSessionsRaw = "min_sessions"
        case minDaysSinceInstallRaw = "min_days_since_install"
        case minSuccessEventsRaw = "min_success_events"
        case maxPromptsTotalRaw = "max_prompts_total"
        case cooldownDaysRaw = "cooldown_days"
        case adGapSecondsRaw = "ad_gap_seconds"
        case delaySecondsRaw = "delay_seconds"
        case triggersRaw = "triggers"
    }

    var enabled: Bool { enabledRaw ?? false }
    /// Bump remotely to reset every client counter (ask again after a big release).
    var version: Int { versionRaw ?? 1 }
    var minSessions: Int { minSessionsRaw ?? 3 }
    var minDaysSinceInstall: Int { minDaysSinceInstallRaw ?? 1 }
    var minSuccessEvents: Int { minSuccessEventsRaw ?? 2 }
    /// Apple shows the sheet at most 3 times per 365 days; asking more only burns tracking.
    var maxPromptsTotal: Int { maxPromptsTotalRaw ?? 3 }
    var cooldownDays: Int { cooldownDaysRaw ?? 30 }
    var adGapSeconds: Int { adGapSecondsRaw ?? 10 }
    var delaySeconds: Double { delaySecondsRaw ?? 2 }
    var triggers: [String] {
        triggersRaw ?? [RatePromptTrigger.convertSuccess.rawValue, RatePromptTrigger.saveSuccess.rawValue]
    }
}
