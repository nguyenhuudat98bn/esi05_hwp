//
//  ReminderManager.swift
//  HWPViewer
//
//  Created by datnh on 01/4/25.
//

import SPNComponent
import Foundation
import UserNotifications

class ReminderManager {
    static let shared = ReminderManager()

    /// One id for every reminder: a new one replaces the previous instead of stacking.
    private static let requestID = "Detected"

    /// Asks for notification permission once, up front.
    ///
    /// Called when the paywall opens: the answer is then already in by the time a purchase
    /// succeeds, so the confirmation banner can fire immediately instead of the permission dialog
    /// landing on top of the purchase flow. At app launch this would only pile onto the ATT and
    /// UMP prompts, which is why it lives here and not in the AppDelegate.
    func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            center.requestAuthorization(options: [.alert, .sound, .badge]) { _, error in
                if let error { logger("[Reminder] authorization failed: \(error)") }
            }
        }
    }

    /// Local notification confirming a purchase / restore. Silently does nothing when the user
    /// never granted permission (see `requestAuthorizationIfNeeded`).
    func fireReminder(title: String, message: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                Self.schedule(title: title, message: message, on: center)
            default:
                break
            }
        }
    }

    private static func schedule(title: String, message: String, on center: UNUserNotificationCenter) {
        center.removeDeliveredNotifications(withIdentifiers: [requestID])
        center.removePendingNotificationRequests(withIdentifiers: [requestID])

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = .default
        content.categoryIdentifier = Bundle.main.bundleIdentifier ?? "com.spn.hwpviewer.editor"

        // Smallest delay the API accepts; the app is in the foreground here and `willPresent`
        // (AppDelegate) asks for a banner so it shows over the app too.
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: requestID, content: content, trigger: trigger)
        center.add(request) { error in
            if let error { logger("[Reminder] schedule failed: \(error)") }
        }
    }
}
