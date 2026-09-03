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
    
    func fireReminder(title: String, message: String) {
        let bundle = Bundle.main.bundleIdentifier ?? "com.spn.hwpviewer.editor"
        let center = UNUserNotificationCenter.current()
        center.removeDeliveredNotifications(withIdentifiers: [bundle])
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = message
        content.sound = UNNotificationSound.default
        content.categoryIdentifier = bundle
        
        let fireDate = Date().addingTimeInterval(1)
        let trigger = UNTimeIntervalNotificationTrigger.init(timeInterval: fireDate.timeIntervalSinceNow, repeats: false)
        let request = UNNotificationRequest.init(identifier: "Detected", content: content, trigger: trigger)
        
        // Schedule the notification.
        center.add(request)
    }
}
