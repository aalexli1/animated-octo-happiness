import XCTest
import UserNotifications
@testable import animated_octo_happiness_ios

@MainActor
final class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    
    override func setUp() async throws {
        try await super.setUp()
        notificationManager = NotificationManager.shared
    }
    
    override func tearDown() async throws {
        notificationManager.removeAllPendingNotifications()
        try await super.tearDown()
    }
    
    func testNotificationManagerInitialization() {
        XCTAssertNotNil(notificationManager)
        XCTAssertNotNil(notificationManager.preferences)
    }
    
    func testAuthorizationStatusCheck() {
        notificationManager.checkAuthorizationStatus()
        
        let validStatuses: [UNAuthorizationStatus] = [
            .notDetermined,
            .denied,
            .authorized,
            .provisional,
            .ephemeral
        ]
        
        XCTAssertTrue(validStatuses.contains(notificationManager.authorizationStatus))
    }
    
    func testNotificationPreferencesDefaults() {
        let preferences = NotificationPreferences()
        
        XCTAssertTrue(preferences.achievementNotifications)
        XCTAssertTrue(preferences.treasureFoundNotifications)
        XCTAssertTrue(preferences.nearbyTreasureReminders)
        XCTAssertEqual(preferences.reminderInterval, 3600)
        XCTAssertFalse(preferences.quietHoursEnabled)
        XCTAssertTrue(preferences.soundEnabled)
        XCTAssertTrue(preferences.badgeEnabled)
    }
    
    func testQuietHoursCalculation() {
        let preferences = NotificationPreferences()
        preferences.quietHoursEnabled = true
        
        let calendar = Calendar.current
        let now = Date()
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: now)
        startComponents.hour = 22
        startComponents.minute = 0
        preferences.quietHoursStart = calendar.date(from: startComponents)!
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endComponents.hour = 8
        endComponents.minute = 0
        preferences.quietHoursEnd = calendar.date(from: endComponents)!
        
        let currentHour = calendar.component(.hour, from: now)
        let isQuietHours = (currentHour >= 22 || currentHour < 8)
        
        XCTAssertEqual(preferences.isWithinQuietHours(), isQuietHours)
    }
    
    func testAchievementNotificationScheduling() {
        notificationManager.preferences.achievementNotifications = true
        notificationManager.preferences.quietHoursEnabled = false
        
        notificationManager.scheduleAchievementNotification(
            achievement: "Test Achievement",
            description: "Test Description"
        )
        
        let expectation = XCTestExpectation(description: "Notification scheduled")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let achievementNotifications = requests.filter { 
                $0.identifier.starts(with: "achievement-")
            }
            
            if notificationManager.isAuthorized {
                XCTAssertGreaterThan(achievementNotifications.count, 0)
            } else {
                XCTAssertEqual(achievementNotifications.count, 0)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testTreasureFoundNotificationScheduling() {
        notificationManager.preferences.treasureFoundNotifications = true
        notificationManager.preferences.quietHoursEnabled = false
        
        notificationManager.scheduleTreasureFoundNotification(
            treasureName: "Test Treasure",
            emoji: "💎"
        )
        
        let expectation = XCTestExpectation(description: "Notification scheduled")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let treasureNotifications = requests.filter { 
                $0.identifier.starts(with: "treasure-found-")
            }
            
            if notificationManager.isAuthorized {
                XCTAssertGreaterThan(treasureNotifications.count, 0)
            } else {
                XCTAssertEqual(treasureNotifications.count, 0)
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testClearBadge() {
        notificationManager.clearBadge()
        
        XCTAssertEqual(UIApplication.shared.applicationIconBadgeNumber, 0)
    }
    
    func testRemoveAllPendingNotifications() {
        notificationManager.scheduleLocationBasedReminder(after: 3600)
        notificationManager.removeAllPendingNotifications()
        
        let expectation = XCTestExpectation(description: "Notifications cleared")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            XCTAssertEqual(requests.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNotificationCategoriesSetup() {
        let expectation = XCTestExpectation(description: "Categories retrieved")
        
        UNUserNotificationCenter.current().getNotificationCategories { categories in
            let categoryIdentifiers = categories.map { $0.identifier }
            
            XCTAssertTrue(categoryIdentifiers.contains("TREASURE_FOUND"))
            XCTAssertTrue(categoryIdentifiers.contains("ACHIEVEMENT_UNLOCKED"))
            XCTAssertTrue(categoryIdentifiers.contains("NEARBY_TREASURE"))
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testNotificationPreferencesRespected() {
        notificationManager.preferences.achievementNotifications = false
        
        notificationManager.scheduleAchievementNotification(
            achievement: "Test",
            description: "Test"
        )
        
        let expectation = XCTestExpectation(description: "No notification scheduled")
        
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let achievementNotifications = requests.filter { 
                $0.identifier.starts(with: "achievement-")
            }
            
            XCTAssertEqual(achievementNotifications.count, 0)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
}