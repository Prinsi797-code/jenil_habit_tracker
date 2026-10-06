//
//  BadgeManager.swift
//  DailyPlanner
//
//  Created by Hevin Technoweb on 30/07/26.
//

import SwiftUI
import Combine
import UserNotifications

@MainActor
final class BadgeManager: ObservableObject {
    @AppStorage("appBadgeEnabled") var isEnabled: Bool = false {
        didSet {
            if isEnabled {
                requestAuthorizationIfNeeded()
            } else {
                clearBadge()
            }
        }
    }
    
    /// Call this whenever the underlying count changes (e.g. incomplete habits today).
    func updateBadge(count: Int) {
        guard isEnabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            Task { @MainActor in
                guard settings.badgeSetting == .enabled else { return }
                UNUserNotificationCenter.current().setBadgeCount(max(count, 0))
            }
        }
    }
    
    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0)
    }
    
    private func requestAuthorizationIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                UNUserNotificationCenter.current().requestAuthorization(options: [.badge]) { granted, _ in
                    Task { @MainActor in
                        if !granted {
                            // Permission denied — reflect that in the toggle so it's not
                            // silently on with no effect.
                            self.isEnabled = false
                        }
                    }
                }
            case .denied:
                Task { @MainActor in
                    self.isEnabled = false
                }
            default:
                break // already authorized, or provisional/ephemeral — fine as-is
            }
        }
    }
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
        static let shared = NotificationManager()
        
        private override init() {
            super.init()
            UNUserNotificationCenter.current().delegate = self
        }
        
        func requestPermission(completion: @escaping (Bool) -> Void) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                completion(granted)
            }
        }
        
        func scheduleNotification(for taskTitle: String, identifier: String) {
            requestPermission { granted in
                guard granted else { return }
                
                let center = UNUserNotificationCenter.current()
                
                // Check if "drink water" (case-insensitive)
                if taskTitle.lowercased().contains("drink water") {
                    let hours = [9, 11, 13, 15, 17, 19, 21, 23]
                    for hour in hours {
                        let content = UNMutableNotificationContent()
                        content.title = "Reminder"
                        content.body = "It's time to \(taskTitle)!"
                        content.sound = .default
                        
                        var dateComponents = DateComponents()
                        dateComponents.hour = hour
                        dateComponents.minute = 0
                        
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                        let request = UNNotificationRequest(identifier: "\(identifier)_\(hour)", content: content, trigger: trigger)
                        
                        center.add(request)
                    }
                } else {
                    // Only one notification per day at 9AM
                    let content = UNMutableNotificationContent()
                    content.title = "Reminder"
                    content.body = "Don't forget to \(taskTitle) today!"
                    content.sound = .default
                    
                    var dateComponents = DateComponents()
                    dateComponents.hour = 9
                    dateComponents.minute = 0
                    
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                    let request = UNNotificationRequest(identifier: "\(identifier)_9", content: content, trigger: trigger)
                    
                    center.add(request)
                }
            }
        }
        
        func cancelNotification(for identifier: String) {
            let center = UNUserNotificationCenter.current()
            let hours = [9, 11, 13, 15, 17, 19, 21, 23]
            let identifiers = hours.map { "\(identifier)_\($0)" } + ["\(identifier)_9"]
            center.removePendingNotificationRequests(withIdentifiers: identifiers)
        }
        
        func testNotification() {
            requestPermission { granted in
                guard granted else { return }
                let content = UNMutableNotificationContent()
                content.title = "Test Notification"
                content.body = "This is a test notification!"
                content.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                let request = UNNotificationRequest(identifier: "TestNotification", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.banner, .sound])
        }
    }
