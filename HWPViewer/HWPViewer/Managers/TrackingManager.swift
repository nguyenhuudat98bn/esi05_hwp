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
extension AppEvents {
    static func logPurchaseEvent(product: SKProduct ,amount: Double, currency: String = "USD", additionalParams: [AppEvents.ParameterName: Any]? = nil) {
        guard SPNUtils.isProduction() else {
            return
        }
        guard currency.count == 3 else {
            return
        }
        
        let params: [AppEvents.ParameterName: Any] = [
            AppEvents.ParameterName.init("fb_content_id"): product.productIdentifier,
            AppEvents.ParameterName.init("fb_content_type"): "inapp",
            AppEvents.ParameterName.init("fb_currency"): currency,
            AppEvents.ParameterName.init("fb_num_items"): 1,
          ]
        
        let event = AppEvents.Name.init(rawValue: "fb_mobile_purchase")
        
        AppEvents.shared.logEvent(event, valueToSum: amount, parameters: params)
    }
}
