//
//  FirebaseRemoteConfigStore.swift
//  HWPViewer
//
//  Firebase Remote Config adapter. The package owns the schema (`SPNRemoteConfig`); this file only
//  fetches values and exposes them as raw JSON `Data` per key. App-only keys (e.g. `iap_configs`) are decoded here.
//

import Foundation
import FirebaseRemoteConfig
import SPNComponent

final class FirebaseRemoteConfigStore: SPNRemoteConfigStore {
    static let shared = FirebaseRemoteConfigStore()

    private let remoteConfig: RemoteConfig
    /// Bundled `DefaultConfigs.json`, used before the first fetch and as fallback for missing keys.
    let defaultsStore: SPNJSONRemoteConfigStore?

    private init() {
        let settings = RemoteConfigSettings()
        settings.minimumFetchInterval = 0
        remoteConfig = RemoteConfig.remoteConfig()
        remoteConfig.configSettings = settings
        defaultsStore = SPNJSONRemoteConfigStore(resource: "DefaultConfigs")
        setDefaults()
    }

    /// Registers every key of `DefaultConfigs.json` as a Firebase default (JSON-encoded).
    private func setDefaults() {
        guard let url = Bundle.main.url(forResource: "DefaultConfigs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let dictionary = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        var defaults: [String: NSObject] = [:]
        for (key, value) in dictionary {
            guard JSONSerialization.isValidJSONObject(value),
                  let encoded = try? JSONSerialization.data(withJSONObject: value) else { continue }
            defaults[key] = encoded as NSData
        }
        remoteConfig.setDefaults(defaults)
    }

    // MARK: - SPNRemoteConfigStore

    func data(forKey key: String) -> Data? {
        let value = remoteConfig.configValue(forKey: key).dataValue
        return value.isEmpty ? nil : value
    }

    // MARK: - Fetch

    func fetch(_ completion: @escaping () -> Void) {
        remoteConfig.fetchAndActivate { _, error in
            if let error {
                logger("[RemoteConfig] fetch failed: \(error.localizedDescription)")
            } else {
                logger("[RemoteConfig] fetched")
            }
            DispatchQueue.main.async { completion() }
        }
    }

    /// Decodes an app-specific key.
    func value<T: Decodable>(_ key: String, as type: T.Type) -> T? {
        guard let data = data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}

// MARK: - App-only config models

// `IapConfigs` lives in IapConfigs.swift.
