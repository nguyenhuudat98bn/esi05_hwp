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

    /// Local notification used to confirm a purchase / restore.
    ///
    /// Nothing in the app ever asked for notification permission, so `center.add` was rejected
    /// silently and no banner ever appeared. Ask the first time we actually have something to say —
    /// at launch it would just pile onto the ATT and UMP prompts.
    func fireReminder(title: String, message: String) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
                    if let error { logger("[Reminder] authorization failed: \(error)") }
                    guard granted else { return }
                    Self.schedule(title: title, message: message, on: center)
                }
            case .authorized, .provisional, .ephemeral:
                Self.schedule(title: title, message: message, on: center)
            default:
                // Denied — the user turned notifications off; nothing to do.
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
