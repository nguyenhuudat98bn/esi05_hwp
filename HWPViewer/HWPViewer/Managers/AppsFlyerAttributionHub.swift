//
//  AppsFlyerAttributionHub.swift
//  HWPViewer
//
//  S2S purchase attribution: the app maps an `appAccountToken` (UUID per install) to the device's
//  `appsflyer_id` on the IAP hub, and tags every StoreKit purchase with that token. Apple's server
//  notifications then reach the hub, which resolves the token back to the appsflyer_id and sends
//  af_subscribe / af_start_trial / af_renewal / af_refund / af_purchase to AppsFlyer itself.
//  Because of that, the client-side `SPNAppsFlyerManager.logPurchase` must stay off (double revenue).
//

import Foundation
import SPNComponent

/// UUID per install, re-issued whenever the appsflyer_id changes. UserDefaults on purpose: the token
/// must disappear with the app (Keychain would survive a reinstall and glue two installs together).
enum IAPAccountToken {
    private static let tokenKey = "iap_account_token"
    private static let afIdKey = "iap_account_af_id"

    static func current(afId: String) -> UUID {
        let defaults = UserDefaults.standard
        if let raw = defaults.string(forKey: tokenKey),
           let token = UUID(uuidString: raw),
           defaults.string(forKey: afIdKey) == afId {
            return token
        }
        let token = UUID()
        defaults.set(token.uuidString, forKey: tokenKey)
        defaults.set(afId, forKey: afIdKey)
        return token
    }
}

/// `POST /attributions/<slug>` on the IAP hub. Public endpoint, idempotent, safe to call on every
/// foreground and right before a purchase. Network errors are ignored: the hub retries delivery until
/// the mapping shows up, and a purchase must never be blocked by this call.
enum AttributionAPI {
    private static let endpoint = URL(string: "\(iapHubBaseUrl)/attributions/\(iapHubSlug)")!

    /// Current token for this install (AppsFlyer UID is available right after `setupSDK`).
    static var currentToken: UUID {
        IAPAccountToken.current(afId: SPNAppsFlyerManager.shared.appsFlyerUID)
    }

    /// Registers the token → appsflyer_id mapping and returns the token used.
    @discardableResult
    static func register() async -> UUID {
        let afId = SPNAppsFlyerManager.shared.appsFlyerUID
        let token = IAPAccountToken.current(afId: afId)
        var request = URLRequest(url: endpoint, timeoutInterval: 5)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "appAccountToken": token.uuidString,
            "appsflyerId": afId,
        ])
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            let status = (response as? HTTPURLResponse)?.statusCode ?? -1
            logger("[IAPHub] attribution \(status) token=\(token.uuidString) afId=\(afId)")
        } catch {
            logger("[IAPHub] attribution failed (ignored): \(error.localizedDescription)")
        }
        return token
    }

    /// Fire-and-forget variant for app foreground.
    static func registerInBackground() {
        Task.detached(priority: .utility) { await register() }
    }
}
