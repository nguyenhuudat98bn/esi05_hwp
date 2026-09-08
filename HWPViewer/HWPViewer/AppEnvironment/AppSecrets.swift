//
//  AppSecrets.swift
//  HWPViewer
//
//  Per-app secrets. Replace these values when cloning the base (each app has its own ad-unit AES key/iv).
//

import Foundation
import SPNComponent

enum AppSecrets {
    /// AES-256-CBC key / iv used to decrypt ad unit ids delivered by remote config.
    static let adSecret = SPNAdSecret(
        key: "l3lpp8n1au0q1oom5cbu0zuh1mw98k8h",
        iv: "lfhka434w6w54y07"
    )
}
