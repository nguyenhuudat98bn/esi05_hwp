//
//  OnboardingConfigs.swift
//  HWPViewer
//
//  Skin of the package onboarding screens for this app: assets, copy, colors.
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
        SPNSplashConfig(
            logo: Asset.Assets.Splash.logo.image,
            appName: L10n.applicationName,
            subtitle: L10n.loadDataSubTitle
        )
    }

    static func prepareAds() -> SPNPrepareAdsConfig {
        SPNPrepareAdsConfig(logo: Asset.Assets.Splash.logo.image)
    }

    static func language() -> SPNLanguageConfig {
        var config = SPNLanguageConfig()
        // Package defaults already match the base look; override icons/colors here when reskinning.
        config.cell.font = .systemFont(ofSize: 20, weight: .medium)
        return config
    }

    static func intro() -> SPNIntroConfig {
        var config = SPNIntroConfig(pages: [
            SPNIntroPage(image: Asset.Assets.Intro.imgIntro1.image, title: L10n.introduceStep1Title),
            SPNIntroPage(image: Asset.Assets.Intro.imgIntro2.image, title: L10n.introduceStep2Title),
            SPNIntroPage(image: Asset.Assets.Intro.imgIntro3.image, title: L10n.introduceStep3Title),
        ])
        config.adStyle = .onboard
        return config
    }
}
