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

    /// A1: soft blue-white background, rounded app icon, app name, blue progress.
    static func splash() -> SPNSplashConfig {
        var config = SPNSplashConfig(
            logo: Asset.Assets.Splash.logo.image,
            appName: L10n.applicationName,
            subtitle: nil
        )
        config.backgroundColor = UIColor(hex: "#EEF3FC")
        config.backgroundImage = Asset.Assets.Splash.splashBg.image
        config.titleColor = AppColors.textPrimary
        config.titleFont = AppFonts.semibold(18)
        config.progressTrackColor = UIColor(hex: "#F0F0F1")
        config.progressFillColor = AppColors.primary
        config.logoSize = 80
        config.logoCenterYOffset = -80
        return config
    }

    static func prepareAds() -> SPNPrepareAdsConfig {
        SPNPrepareAdsConfig(logo: Asset.Assets.Splash.logo.image)
    }

    /// A2: title "Language", pill "Next" top-right, round flag + name + radio on a gray card;
    /// selected = blue card with white text.
    static func language() -> SPNLanguageConfig {
        var config = SPNLanguageConfig()
        config.title = L10n.languageTitle
        config.applyButtonTitle = L10n.languageNext
        // Behaviour comes from remote `language_intro_configs`: `apply_button_type` (2 = "Next" text pill),
        // `apply_language_color`, `is_show_pointer_hand`, `is_enable_auto_skip_language`, `time_skip_language`…
        // Only the asset is app-side: Lottie hand pointer played as-is instead of the bundled image.
        if let url = Bundle.main.url(forResource: "hand_pointer_click", withExtension: "json") {
            config.handPointer = .lottie(url, size: 96)
        }
        config.applyDisabledTint = AppColors.textTertiary
        config.applyFont = AppFonts.semibold(16)
        config.titleFont = AppFonts.bold(22)
        config.titleColor = AppColors.textPrimary
        config.cell.font = AppFonts.medium(16)
        config.cell.height = 60
        config.cell.spacing = 16
        config.cell.horizontalInset = 16
        config.cell.cornerRadius = 12
        config.cell.borderWidth = 0
        config.cell.showFlags = true
        config.cell.flagSize = 26
        config.cell.backgroundColor = UIColor(hex: "#F5F5F5")
        config.cell.borderColor = .clear
        config.cell.textColor = AppColors.textPrimary
        config.cell.selectedBackgroundColor = AppColors.primary
        config.cell.selectedBorderColor = AppColors.primary
        config.cell.selectedTextColor = .white
        config.cell.selectedIcon = SPNOnboardingAssets.radioOn
        config.cell.selectedIconTint = .white
        config.cell.deselectedIcon = SPNOnboardingAssets.radioOff
        return config
    }

    /// A3: mockup on Intro_BG (Korean art when the app runs in Korean), 2-line title, dots, "Next" button.
    static func intro() -> SPNIntroConfig {
        let isKorean = SPNSession.shared.currentLanguageCode.hasPrefix("ko")
        let images: [UIImage] = isKorean
            ? [Asset.Assets.Intro.imgIntroKr1.image, Asset.Assets.Intro.imgIntroKr2.image, Asset.Assets.Intro.imgIntroKr3.image]
            : [Asset.Assets.Intro.imgIntro1.image, Asset.Assets.Intro.imgIntro2.image, Asset.Assets.Intro.imgIntro3.image]
        var config = SPNIntroConfig(pages: [
            SPNIntroPage(image: images[0], title: L10n.introduceStep1Title),
            SPNIntroPage(image: images[1], title: L10n.introduceStep2Title),
            SPNIntroPage(image: images[2], title: L10n.introduceStep3Title),
        ])
        config.adStyle = .onboard
        // Behaviour from remote `language_intro_configs`: `is_next_button_large` (last page with ad stays small),
        // `next_intro_color`, `is_show_pointer_hand`, `is_enable_auto_skip_intro_to_last_page`, `is_enable_intro_guidle`.
        config.nextButtonStyle = .auto
        // Same Lottie hand pointer as the Language screen, played as-is on the first page's Next button.
        if let url = Bundle.main.url(forResource: "hand_pointer_click", withExtension: "json") {
            config.handPointer = .lottie(url, size: 96)
        }
        config.titleColor = AppColors.textPrimary
        config.titleFont = AppFonts.bold(24)
        config.pageControlNormalColor = AppColors.border
        config.imageContentMode = .scaleAspectFill
        return config
    }
}
