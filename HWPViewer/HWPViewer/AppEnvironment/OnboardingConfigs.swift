//
//  OnboardingConfigs.swift
//  HWPViewer
//
//  Skin of the package onboarding screens (Figma A1–A3): assets, copy, colors.
//  Behaviour knobs stay in remote config (`language_intro_configs`).
//

import UIKit
import SPNComponent

enum OnboardingConfigs {
    static func make() -> SPNOnboardingConfig {
        SPNOnboardingConfig(
            splash: splash(),
            prepareAds: prepareAds(),
            language: language(),
            status: SPNStatusConfig(),
            intro: intro()
        )
    }

    static func splash() -> SPNSplashConfig {
        var config = SPNSplashConfig(
            logo: Asset.Assets.Splash.logo.image,
            appName: L10n.applicationName,
            subtitle: L10n.loadDataSubTitle
        )
        config.backgroundColor = AppColors.primary
        config.titleColor = .white
        config.subtitleColor = UIColor.white.withAlphaComponent(0.85)
        config.progressTrackColor = UIColor.white.withAlphaComponent(0.3)
        config.progressFillColor = .white
        return config
    }

    static func prepareAds() -> SPNPrepareAdsConfig {
        SPNPrepareAdsConfig(logo: Asset.Assets.Splash.logo.image)
    }

    /// A2: title "Language", pill "Next" top-right, flag + name + radio, selected = blue bg / white text.
    static func language() -> SPNLanguageConfig {
        var config = SPNLanguageConfig()
        config.title = L10n.languageTitle
        config.applyButtonTitle = L10n.languageNext
        config.applyButtonType = .text
        config.applyTint = AppColors.primary
        config.titleFont = AppFonts.bold(22)
        config.titleColor = AppColors.textPrimary
        config.cell.font = AppFonts.medium(16)
        config.cell.height = 56
        config.cell.cornerRadius = 12
        config.cell.showFlags = true
        config.cell.backgroundColor = AppColors.surface
        config.cell.borderColor = AppColors.divider
        config.cell.selectedBackgroundColor = AppColors.primary
        config.cell.selectedBorderColor = AppColors.primary
        config.cell.selectedTextColor = .white
        config.cell.selectedIconTint = .white
        return config
    }

    /// A3: mockup on Intro_BG, 2-line title, dots, small pill "Next".
    static func intro() -> SPNIntroConfig {
        var config = SPNIntroConfig(pages: [
            SPNIntroPage(image: Asset.Assets.Intro.imgIntro1.image, title: L10n.introduceStep1Title),
            SPNIntroPage(image: Asset.Assets.Intro.imgIntro2.image, title: L10n.introduceStep2Title),
            SPNIntroPage(image: Asset.Assets.Intro.imgIntro3.image, title: L10n.introduceStep3Title),
        ])
        config.adStyle = .onboard
        config.nextButtonStyle = .small
        config.nextColor = AppColors.primary
        config.titleColor = AppColors.textPrimary
        config.titleFont = AppFonts.bold(20)
        config.pageControlNormalColor = AppColors.border
        config.imageContentMode = .scaleAspectFit
        return config
    }
}
