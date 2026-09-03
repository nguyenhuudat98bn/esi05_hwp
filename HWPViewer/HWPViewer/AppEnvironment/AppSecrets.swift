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
        key: "af8wrqb9j6wn2i8a9vgr1tbff1kjsiiw",
        iv: "t5woasjhcmhcu7ua"
    )
}
