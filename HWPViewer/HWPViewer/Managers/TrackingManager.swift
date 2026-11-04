//
//  TrackingManager.swift
//  HWPViewer
//
//  Created by datnh on 01/4/25.
//

import SPNComponent
import Foundation
import FirebaseAnalytics

enum EventTracking: String {
    case fetchRemoteConfigsSuccess = "fetch_remote_configs_success"
    case fetchAppOpenAdvertiserSuccess = "fetch_app_open_advertiser_success"
    case fetchInterstitialAdvertiserSuccess = "fetch_interstitial_advertiser_success"
    case firstOpen1Splash = "first_open_1_splash"
    case firstOpen1SplashAdClicked = "first_open_1_splash_ad_clicked"
    case firstOpen1SplashToBackground = "first_open_1_splash_to_background"
    case firstOpen1SplashToForeground = "first_open_1_splash_to_foreground"
    case firstOpen1SplashToLanguage = "first_open_1_splash_to_language"
    case firstOpen2LanguageAdClicked = "first_open_2_language_ad_clicked"
    case firstOpen2LanguageToBackground = "first_open_2_language_to_background"
    case firstOpen2LanguageToForeground = "first_open_2_language_to_foreground"
    case firstOpen2LanguageToIntro = "first_open_2_language_to_intro"
    case firstOpen3IntroAdClicked = "first_open_3_intro_ad_clicked"
    case firstOpen3IntroToBackground = "first_open_3_intro_to_background"
    case firstOpen3IntroToForeground = "first_open_3_intro_to_foreground"
    case firstOpen4OpenHome = "first_open_4_open_home"
    case ratePromptSkipped = "rate_prompt_skipped"
    case ratePromptRequested = "rate_prompt_requested"
    case rateManualTapped = "rate_manual_tapped"
    
    var isFirstTimeEvent: Bool {
        switch self {
        case .firstOpen1Splash,
                .firstOpen1SplashAdClicked,
                .firstOpen1SplashToBackground,
                .firstOpen1SplashToForeground,
                .firstOpen1SplashToLanguage,
                .firstOpen2LanguageAdClicked,
                .firstOpen2LanguageToBackground,
                .firstOpen2LanguageToForeground,
                .firstOpen2LanguageToIntro,
                .firstOpen3IntroAdClicked,
                .firstOpen3IntroToBackground,
                .firstOpen3IntroToForeground,
                .firstOpen4OpenHome:
            return true
        default:
            return false
        }
    }
}

class TrackingManager: SPNAnalyticsLogging {
    static let shared = TrackingManager()

    /// SPNComponent sink: package screens log their funnel events through here.
    func logEvent(_ name: String, parameters: [String: Any]?) {
        logger("------------- TrackingManager(SPN): \(name), parameters:\(parameters ?? [:])")
        Analytics.logEvent(name, parameters: parameters)
    }
    
    func logCustomEvent(_ event: EventTracking, parameters: [String: Any]? = nil) {
        if event.isFirstTimeEvent {
            let eventSaved = UserDefaults.standard.string(forKey: event.rawValue)
            if eventSaved == nil {
                logger("------------- TrackingManager: \(event.rawValue), parameters:\(parameters ?? [:])")
                Analytics.logEvent(event.rawValue, parameters: parameters)
                UserDefaults.standard.set(event.rawValue, forKey: event.rawValue)
            }
        } else {
            logger("------------- TrackingManager: \(event.rawValue), parameters:\(parameters ?? [:])")
            Analytics.logEvent(event.rawValue, parameters: parameters)
        }
    }
}

import FacebookCore
import StoreKit

extension AppEvents {
    /// `fb_mobile_purchase` for a purchase made in the app (production builds only). Value is the
    /// product's regular price, as before the StoreKit 2 move — also for a free-trial start.
    static func logPurchaseEvent(product: StoreKit.Product, transactionID: UInt64) {
        guard SPNUtils.isProduction() else { return }
        let currency = product.priceFormatStyle.currencyCode
        guard currency.count == 3 else { return }
        let price = NSDecimalNumber(decimal: product.price)
        let params: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName("fb_content_id"): product.id,
            AppEvents.ParameterName("fb_content_type"): "inapp",
            AppEvents.ParameterName("fb_currency"): currency,
            AppEvents.ParameterName("fb_num_items"): 1,
            AppEvents.ParameterName("fb_order_id"): String(transactionID),
        ]
        AppEvents.shared.logEvent(AppEvents.Name("fb_mobile_purchase"),
                                  valueToSum: Double(price.stringValue) ?? price.doubleValue,
                                  parameters: params)
    }
}
