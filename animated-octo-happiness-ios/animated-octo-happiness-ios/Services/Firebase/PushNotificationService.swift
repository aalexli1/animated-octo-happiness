import Foundation
import UIKit
import UserNotifications
// Import Firebase Messaging when package is added
// import FirebaseMessaging

@MainActor
class PushNotificationService: NSObject, ObservableObject {
    static let shared = PushNotificationService()
    
    @Published var isNotificationsEnabled = false
    @Published var fcmToken: String?
    
    private override init() {
        super.init()
        setupNotifications()
    }
    
    func setupNotifications() {
        // TODO: Uncomment when Firebase is added
        // Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: authOptions)
            
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                    self.isNotificationsEnabled = true
                }
            }
            
            return granted
        } catch {
            print("Error requesting notification permission: \(error)")
            return false
        }
    }
    
    func checkNotificationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        await MainActor.run {
            self.isNotificationsEnabled = settings.authorizationStatus == .authorized
        }
    }
    
    func subscribeTopic(_ topic: String) {
        // TODO: Uncomment when Firebase is added
        // Messaging.messaging().subscribe(toTopic: topic) { error in
        //     if let error = error {
        //         print("Error subscribing to topic \(topic): \(error)")
        //     } else {
        //         print("Successfully subscribed to topic: \(topic)")
        //     }
        // }
    }
    
    func unsubscribeTopic(_ topic: String) {
        // TODO: Uncomment when Firebase is added
        // Messaging.messaging().unsubscribe(fromTopic: topic) { error in
        //     if let error = error {
        //         print("Error unsubscribing from topic \(topic): \(error)")
        //     } else {
        //         print("Successfully unsubscribed from topic: \(topic)")
        //     }
        // }
    }
    
    func sendLocalNotification(title: String, body: String, identifier: String = UUID().uuidString) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending local notification: \(error)")
            }
        }
    }
    
    func handleRemoteNotification(_ userInfo: [AnyHashable: Any]) {
        // Process the notification payload
        if let treasureId = userInfo["treasureId"] as? String {
            // Handle treasure-related notification
            NotificationCenter.default.post(
                name: .treasureNotificationReceived,
                object: nil,
                userInfo: ["treasureId": treasureId]
            )
        }
        
        // TODO: Uncomment when Firebase is added
        // Messaging.messaging().appDidReceiveMessage(userInfo)
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        // Show notification even when app is in foreground
        return [.alert, .badge, .sound]
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        let userInfo = response.notification.request.content.userInfo
        handleRemoteNotification(userInfo)
    }
}

// MARK: - MessagingDelegate

// TODO: Uncomment when Firebase is added
// extension PushNotificationService: MessagingDelegate {
//     func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
//         print("FCM Token: \(fcmToken ?? "nil")")
//         self.fcmToken = fcmToken
//         
//         // Send token to your server if needed
//         if let token = fcmToken {
//             // Update user's FCM token in Firestore
//             Task {
//                 await updateUserFCMToken(token)
//             }
//         }
//     }
//     
//     private func updateUserFCMToken(_ token: String) async {
//         guard let userId = FirebaseAuthService.shared.currentUser?.uid else { return }
//         
//         do {
//             try await FirestoreService.shared.updateUserProfile(
//                 UserProfile(
//                     id: userId,
//                     fcmToken: token,
//                     lastTokenUpdate: Date()
//                 )
//             )
//         } catch {
//             print("Error updating FCM token: \(error)")
//         }
//     }
// }

// MARK: - Notification Names

extension Notification.Name {
    static let treasureNotificationReceived = Notification.Name("treasureNotificationReceived")
}

// MARK: - Push Notification Payload Models

struct TreasureNotificationPayload: Codable {
    let treasureId: String
    let title: String
    let body: String
    let imageUrl: String?
    let type: NotificationType
    
    enum NotificationType: String, Codable {
        case newTreasure = "new_treasure"
        case treasureFound = "treasure_found"
        case treasureNearby = "treasure_nearby"
        case treasureExpiring = "treasure_expiring"
    }
}