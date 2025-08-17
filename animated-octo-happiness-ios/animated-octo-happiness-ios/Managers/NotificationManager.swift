import Foundation
import UserNotifications
import CoreLocation
import SwiftUI
import SwiftData

@MainActor
class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isAuthorized = false
    @Published var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published var preferences: NotificationPreferences = NotificationPreferences()
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var modelContext: ModelContext?
    
    override private init() {
        super.init()
        notificationCenter.delegate = self
        checkAuthorizationStatus()
        setupNotificationCategories()
    }
    
    func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.authorizationStatus = settings.authorizationStatus
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                self.isAuthorized = granted
                self.authorizationStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    private func setupNotificationCategories() {
        let treasureFoundCategory = UNNotificationCategory(
            identifier: "TREASURE_FOUND",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_TREASURE",
                    title: "View Treasure",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "DISMISS",
                    title: "Dismiss",
                    options: []
                )
            ],
            intentIdentifiers: []
        )
        
        let achievementCategory = UNNotificationCategory(
            identifier: "ACHIEVEMENT_UNLOCKED",
            actions: [
                UNNotificationAction(
                    identifier: "VIEW_ACHIEVEMENT",
                    title: "View Achievement",
                    options: .foreground
                )
            ],
            intentIdentifiers: []
        )
        
        let nearbyTreasureCategory = UNNotificationCategory(
            identifier: "NEARBY_TREASURE",
            actions: [
                UNNotificationAction(
                    identifier: "START_HUNT",
                    title: "Start Hunt",
                    options: .foreground
                ),
                UNNotificationAction(
                    identifier: "REMIND_LATER",
                    title: "Remind Later",
                    options: []
                )
            ],
            intentIdentifiers: []
        )
        
        notificationCenter.setNotificationCategories([
            treasureFoundCategory,
            achievementCategory,
            nearbyTreasureCategory
        ])
    }
    
    func scheduleAchievementNotification(achievement: String, description: String) {
        guard isAuthorized,
              preferences.achievementNotifications,
              !preferences.isWithinQuietHours() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Achievement Unlocked!"
        content.body = "\(achievement): \(description)"
        content.sound = preferences.soundEnabled ? .default : nil
        content.categoryIdentifier = "ACHIEVEMENT_UNLOCKED"
        content.badge = preferences.badgeEnabled ? NSNumber(value: 1) : nil
        
        let request = UNNotificationRequest(
            identifier: "achievement-\(achievement)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling achievement notification: \(error)")
            }
        }
    }
    
    func scheduleTreasureFoundNotification(treasureName: String, emoji: String) {
        guard isAuthorized,
              preferences.treasureFoundNotifications,
              !preferences.isWithinQuietHours() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Treasure Found! \(emoji)"
        content.body = "You discovered \(treasureName)!"
        content.sound = preferences.soundEnabled ? .default : nil
        content.categoryIdentifier = "TREASURE_FOUND"
        
        let request = UNNotificationRequest(
            identifier: "treasure-found-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling treasure found notification: \(error)")
            }
        }
    }
    
    func scheduleNearbyTreasureReminder(treasureCount: Int, location: CLLocation) {
        guard isAuthorized,
              preferences.nearbyTreasureReminders,
              !preferences.isWithinQuietHours() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Treasures Nearby!"
        content.body = treasureCount == 1 
            ? "There's a treasure waiting to be discovered nearby!" 
            : "There are \(treasureCount) treasures waiting to be discovered nearby!"
        content.sound = preferences.soundEnabled ? .default : nil
        content.categoryIdentifier = "NEARBY_TREASURE"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: 60,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "nearby-treasures-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling nearby treasure notification: \(error)")
            }
        }
    }
    
    func scheduleLocationBasedReminder(after interval: TimeInterval = 3600) {
        guard isAuthorized,
              preferences.nearbyTreasureReminders,
              !preferences.isWithinQuietHours() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Time for a Treasure Hunt!"
        content.body = "Check the map to see if there are any treasures nearby."
        content.sound = preferences.soundEnabled ? .default : nil
        content.categoryIdentifier = "NEARBY_TREASURE"
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: interval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "location-reminder-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling location reminder: \(error)")
            }
        }
    }
    
    func clearBadge() {
        Task {
            await MainActor.run {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    
    func removeAllPendingNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    func removePendingNotifications(withIdentifiers identifiers: [String]) {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
    }
}

extension NotificationManager: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        return [.banner, .sound, .badge]
    }
    
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let actionIdentifier = response.actionIdentifier
        let categoryIdentifier = response.notification.request.content.categoryIdentifier
        
        await MainActor.run {
            switch categoryIdentifier {
            case "TREASURE_FOUND":
                if actionIdentifier == "VIEW_TREASURE" {
                    NotificationCenter.default.post(
                        name: Notification.Name("ShowTreasureDetail"),
                        object: nil
                    )
                }
            case "ACHIEVEMENT_UNLOCKED":
                if actionIdentifier == "VIEW_ACHIEVEMENT" {
                    NotificationCenter.default.post(
                        name: Notification.Name("ShowAchievements"),
                        object: nil
                    )
                }
            case "NEARBY_TREASURE":
                if actionIdentifier == "START_HUNT" {
                    NotificationCenter.default.post(
                        name: Notification.Name("StartTreasureHunt"),
                        object: nil
                    )
                } else if actionIdentifier == "REMIND_LATER" {
                    scheduleLocationBasedReminder(after: 1800)
                }
            default:
                break
            }
        }
    }
}