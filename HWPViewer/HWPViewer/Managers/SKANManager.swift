//
//  SKANManager.swift
//  HWPViewer
//
//  Created by Eragon on 25/8/25.
//

import SPNComponent
import Foundation
//import AdjustSdk
import StoreKit

enum SKANEvent {
    case install
    case nonInstallSession
    case firstOpen
    case subscription
}

final class SKANManager {

    static let shared = SKANManager()

    private var lastFineValue: Int?
    private var hasLockedWindow: Bool = false

    private init() {}

    func updateConversion(for event: SKANEvent) {
        guard #available(iOS 16.1, *) else {
            print("⚠️ SKAdNetwork 4.0 API requires iOS 16.1+")
            return
        }

        let conversion: (fine: Int, coarse: String, lock: Bool)

        switch event {
        case .install:
            conversion = (0, "low", false)
        case .nonInstallSession:
            conversion = (1, "low", false)
        case .firstOpen:
            conversion = (2, "medium", false)
        case .subscription:
            conversion = (3, "high", true)
        }

        // Tránh gửi lại giá trị đã gửi hoặc sau khi locked
        if let last = lastFineValue, conversion.fine <= last, !conversion.lock {
            print("⚠️ SKAN: fineValue \(conversion.fine) đã được gửi.")
            return
        }

        lastFineValue = conversion.fine
        hasLockedWindow = hasLockedWindow || conversion.lock

        // Dùng Adjust SDK để gửi giá trị conversion
//        Adjust.updateSkanConversionValue(
//            conversion.fine,
//            coarseValue: conversion.coarse,
//            lockWindow: NSNumber(value: conversion.lock)
//        ) { error in
//            if let error = error {
//                print("❌ Adjust SKAN update error: \(error.localizedDescription)")
//            } else {
//                print("✅ Adjust SKAN update sent. Fine: \(conversion.fine), Coarse: \(conversion.coarse), Lock: \(conversion.lock)")
//            }
//        }
    }

    /// Reset giá trị đã gửi (dùng khi debug)
    func resetForDebug() {
        lastFineValue = nil
        hasLockedWindow = false
    }
}
