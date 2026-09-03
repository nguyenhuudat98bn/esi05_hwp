//
//  AppDelegate.swift
//  HWPViewer
//
//  Created by datnh on 01/4/25.
//

import UIKit
import StoreKit
import GoogleMobileAds
import FirebaseCore
import FirebaseMessaging
import FirebaseAnalytics
import FBSDKCoreKit
import FBAudienceNetwork
import VungleAdsSDK
import MTGSDK
import SPNComponent

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let iapObserver = StoreKitManager.shared
    private var onboarding: SPNOnboardingCoordinator?

    /// DEBUG only: launch with env `SPN_DISABLE_ADS=1` to run the flow without ads (UI smoke tests).
    static var adsDisabledForDebug: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.environment["SPN_DISABLE_ADS"] == "1"
        #else
        return false
        #endif
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        MobileAds.shared.start()
        ApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        FBAdSettings.setAdvertiserTrackingEnabled(true)
        VunglePrivacySettings.setGDPRStatus(true)
        VunglePrivacySettings.setGDPRMessageVersion("v1.0.0")
        VunglePrivacySettings.setCCPAStatus(true)
        MTGSDK.sharedInstance().consentStatus = true
        MTGSDK.sharedInstance().doNotTrackStatus = false

        configureSPNComponent()

        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
        SKPaymentQueue.default().add(iapObserver)
        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        SKPaymentQueue.default().remove(iapObserver)
    }

    // MARK: - UIScene (iOS 26 SDK requires the scene lifecycle; SceneDelegate calls back here)

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }

    /// Builds the root navigation stack for the window created by `SceneDelegate`.
    func startUI(in window: UIWindow) {
        self.window = window
        let navigationController = UINavigationController()
        navigationController.isNavigationBarHidden = true
        window.rootViewController = navigationController
        window.makeKeyAndVisible()

        onboarding = makeOnboardingCoordinator(navigationController: navigationController)
        #if DEBUG
        // SIMCTL_CHILD_SPN_DEBUG_SCREEN=language|intro|status|prepare opens one package screen directly (reskin / smoke test).
        if let debugScreen = ProcessInfo.processInfo.environment["SPN_DEBUG_SCREEN"], let vc = makeDebugScreen(debugScreen) {
            navigationController.setViewControllers([vc], animated: false)
        } else {
            onboarding?.start()
        }
        #else
        onboarding?.start()
        #endif
    }

    /// Forwarded from `SceneDelegate` (the app-delegate variants are not called under the scene lifecycle).
    func sceneDidBecomeActive() {
        AppEvents.shared.activateApp()
        onboarding?.lifecycleHandler.applicationDidBecomeActive()
    }

    func sceneDidEnterBackground() {
        onboarding?.lifecycleHandler.applicationDidEnterBackground()
    }

    /// File / URL opened while the scene is alive (or at launch via `connectionOptions`).
    func handleOpen(url: URL) {
        if url.isFileURL, FileKind(url: url)?.isHwp == true {
            IncomingFileHandler.shared.handle(url)
        } else {
            _ = ApplicationDelegate.shared.application(UIApplication.shared, open: url, sourceApplication: nil, annotation: nil)
        }
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        if url.isFileURL, FileKind(url: url)?.isHwp == true {
            IncomingFileHandler.shared.handle(url)
            return true
        }
        return ApplicationDelegate.shared.application(
            app,
            open: url,
            sourceApplication: options[UIApplication.OpenURLOptionsKey.sourceApplication] as? String,
            annotation: options[UIApplication.OpenURLOptionsKey.annotation]
        )
    }

    // MARK: - SPNComponent

    private func configureSPNComponent() {
        let store = FirebaseRemoteConfigStore.shared
        SPNComponent.configure(
            theme: SPNTheme(),
            ads: SPNAdsEnvironment(
                adSecret: AppSecrets.adSecret,
                isPremium: { SPNSession.shared.isPremium || AppDelegate.adsDisabledForDebug },
                analytics: TrackingManager.shared,
                appStoreURL: URL(string: appStoreUrl)
            ),
            defaultsStore: store.defaultsStore
        )
        SPNTheme.current = AppTheme.make()
    }

    private func makeOnboardingCoordinator(navigationController: UINavigationController) -> SPNOnboardingCoordinator {
        let store = FirebaseRemoteConfigStore.shared
        var launchHooks = SPNLaunchFlowHooks(
            fetchRemoteConfig: { done in
                store.fetch {
                    SPNRemoteConfig.reload(from: store)
                    AppTheme.refreshFromRemote()
                    done()
                }
            },
            remoteConfigStore: nil, // reload handled above so the theme can refresh in the same step
            onTrackingStatus: { status in
                FBAdSettings.setAdvertiserTrackingEnabled(status == .authorized)
            }
        )
        launchHooks.attDelay = 1.0
        #if DEBUG
        // Dev switches for UI smoke tests: SIMCTL_CHILD_SPN_SKIP_ATT=1 / SIMCTL_CHILD_SPN_DISABLE_ADS=1
        launchHooks.skipTracking = ProcessInfo.processInfo.environment["SPN_SKIP_ATT"] == "1"
        launchHooks.skipConsent = ProcessInfo.processInfo.environment["SPN_SKIP_CONSENT"] == "1"
        #endif

        let hooks = SPNOnboardingHooks(
            launch: launchHooks,
            makeHome: { MainTabBarController() },
            presentPaywall: { trigger, presenter, completion in
                PaywallPresenter.shared.present(trigger: trigger, from: presenter, completion: completion)
            }
        )
        return SPNOnboardingCoordinator(navigationController: navigationController, config: OnboardingConfigs.make(), hooks: hooks)
    }

    #if DEBUG
    private func makeDebugScreen(_ name: String) -> UIViewController? {
        let config = OnboardingConfigs.make()
        switch name {
        case "splash":
            // Never finishes: keeps the splash on screen for UI review.
            var hooks = SPNLaunchFlowHooks(fetchRemoteConfig: { _ in })
            hooks.skipTracking = true
            hooks.skipConsent = true
            return SPNSplashViewController(config: config.splash, hooks: hooks)
        case "language": return SPNLanguageViewController(config: config.language, source: .onboarding)
        case "language_selected":
            var language = config.language
            language.preselectCurrentLanguage = true
            return SPNLanguageViewController(config: language, source: .onboarding)
        case "language_settings": return SPNLanguageViewController(config: config.language, source: .settings)
        case "intro": return SPNIntroViewController(config: config.intro)
        case "status": return SPNStatusViewController(config: config.status ?? SPNStatusConfig())
        case "prepare": return SPNPrepareForAdsViewController(config: config.prepareAds)
        case "home": return MainTabBarController()
        case "tools", "settings":
            let tab = MainTabBarController()
            tab.loadViewIfNeeded()
            tab.selectedIndex = name == "tools" ? 1 : 2
            return tab
        case "import", "more", "rename", "delete", "offline":
            let tab = MainTabBarController()
            tab.loadViewIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                (tab.viewControllers?.first as? HomeViewController)?.debugPresent(name)
            }
            return tab
        case "search": return SearchViewController()
        case "viewer", "editor":
            guard let item = FileStore.shared.hwpFiles().first else { return MainTabBarController() }
            return HwpViewerViewController(item: item, startInEditMode: name == "editor")
        case "select_pdf": return SelectFileViewController(tool: .pdfToHwp)
        case "convert_result":
            guard let item = FileStore.shared.hwpFiles().first else { return MainTabBarController() }
            return ConvertResultViewController(outputURL: item.url, size: item.size)
        case "paywall": return PaywallViewController()
        default: return nil
        }
    }
    #endif

    // MARK: - Push

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        logger(userInfo)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger("Unable to register for remote notifications: \(error.localizedDescription)")
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        Messaging.messaging().appDidReceiveMessage(notification.request.content.userInfo)
        return [[.banner, .sound]]
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        Messaging.messaging().appDidReceiveMessage(response.notification.request.content.userInfo)
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        logger("Firebase registration token: \(String(describing: fcmToken))")
        NotificationCenter.default.post(name: Notification.Name("FCMToken"), object: nil, userInfo: ["token": fcmToken ?? ""])
    }
}
