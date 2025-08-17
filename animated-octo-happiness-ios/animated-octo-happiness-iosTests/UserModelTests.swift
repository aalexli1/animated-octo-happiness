//
//  UserModelTests.swift
//  animated-octo-happiness-iosTests
//
//  Created by Auto-Agent on 8/17/25.
//

import XCTest
import SwiftData
@testable import animated_octo_happiness_ios

final class UserModelTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            User.self,
            UserPreferences.self,
            Treasure.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = modelContainer.mainContext
    }
    
    override func tearDown() async throws {
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    func testUserInitialization() {
        let userId = "test-user-123"
        let email = "test@example.com"
        let displayName = "Test User"
        let photoURL = "https://example.com/photo.jpg"
        
        let user = User(
            id: userId,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            isAnonymous: false
        )
        
        XCTAssertEqual(user.id, userId)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
        XCTAssertEqual(user.photoURL, photoURL)
        XCTAssertFalse(user.isAnonymous)
        XCTAssertEqual(user.totalScore, 0)
        XCTAssertTrue(user.achievements.isEmpty)
        XCTAssertNotNil(user.createdAt)
    }
    
    func testAnonymousUserInitialization() {
        let userId = "anon-user-123"
        
        let user = User(
            id: userId,
            isAnonymous: true
        )
        
        XCTAssertEqual(user.id, userId)
        XCTAssertNil(user.email)
        XCTAssertNil(user.displayName)
        XCTAssertTrue(user.isAnonymous)
    }
    
    func testMigrateFromAnonymous() {
        let user = User(
            id: "anon-123",
            isAnonymous: true
        )
        
        XCTAssertTrue(user.isAnonymous)
        XCTAssertNil(user.email)
        
        let email = "migrated@example.com"
        let displayName = "Migrated User"
        
        user.migrateFromAnonymous(to: email, displayName: displayName)
        
        XCTAssertFalse(user.isAnonymous)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
    }
    
    func testMigrateFromAnonymousWithoutDisplayName() {
        let user = User(
            id: "anon-123",
            isAnonymous: true
        )
        
        let email = "migrated@example.com"
        
        user.migrateFromAnonymous(to: email)
        
        XCTAssertFalse(user.isAnonymous)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, "migrated")
    }
    
    func testUpdateProfile() {
        let user = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Original Name",
            photoURL: "original.jpg"
        )
        
        let newDisplayName = "Updated Name"
        let newPhotoURL = "updated.jpg"
        
        user.updateProfile(displayName: newDisplayName, photoURL: newPhotoURL)
        
        XCTAssertEqual(user.displayName, newDisplayName)
        XCTAssertEqual(user.photoURL, newPhotoURL)
    }
    
    func testPartialProfileUpdate() {
        let user = User(
            id: "user-123",
            email: "test@example.com",
            displayName: "Original Name",
            photoURL: "original.jpg"
        )
        
        let newDisplayName = "Updated Name"
        
        user.updateProfile(displayName: newDisplayName)
        
        XCTAssertEqual(user.displayName, newDisplayName)
        XCTAssertEqual(user.photoURL, "original.jpg")
    }
    
    func testRecordLogin() {
        let user = User(id: "user-123")
        
        XCTAssertNil(user.lastLoginAt)
        
        user.recordLogin()
        
        XCTAssertNotNil(user.lastLoginAt)
        XCTAssertTrue(user.lastLoginAt! <= Date())
    }
    
    func testAddAchievement() {
        let user = User(id: "user-123")
        
        XCTAssertTrue(user.achievements.isEmpty)
        
        user.addAchievement("First Treasure")
        XCTAssertEqual(user.achievements.count, 1)
        XCTAssertTrue(user.achievements.contains("First Treasure"))
        
        user.addAchievement("Explorer")
        XCTAssertEqual(user.achievements.count, 2)
        XCTAssertTrue(user.achievements.contains("Explorer"))
    }
    
    func testAddDuplicateAchievement() {
        let user = User(id: "user-123")
        
        user.addAchievement("First Treasure")
        user.addAchievement("First Treasure")
        
        XCTAssertEqual(user.achievements.count, 1)
    }
    
    func testIncrementScore() {
        let user = User(id: "user-123")
        
        XCTAssertEqual(user.totalScore, 0)
        
        user.incrementScore(by: 10)
        XCTAssertEqual(user.totalScore, 10)
        
        user.incrementScore(by: 25)
        XCTAssertEqual(user.totalScore, 35)
        
        user.incrementScore(by: -5)
        XCTAssertEqual(user.totalScore, 30)
    }
    
    func testUserPreferencesInitialization() {
        let preferences = UserPreferences()
        
        XCTAssertTrue(preferences.notificationsEnabled)
        XCTAssertTrue(preferences.locationSharingEnabled)
        XCTAssertTrue(preferences.soundEnabled)
        XCTAssertTrue(preferences.hapticFeedbackEnabled)
        XCTAssertEqual(preferences.theme, "system")
    }
    
    func testCustomUserPreferences() {
        let preferences = UserPreferences(
            notificationsEnabled: false,
            locationSharingEnabled: false,
            soundEnabled: false,
            hapticFeedbackEnabled: false,
            theme: "dark"
        )
        
        XCTAssertFalse(preferences.notificationsEnabled)
        XCTAssertFalse(preferences.locationSharingEnabled)
        XCTAssertFalse(preferences.soundEnabled)
        XCTAssertFalse(preferences.hapticFeedbackEnabled)
        XCTAssertEqual(preferences.theme, "dark")
    }
    
    func testUserWithPreferences() {
        let user = User(id: "user-123")
        let preferences = UserPreferences(theme: "dark")
        
        user.preferences = preferences
        
        XCTAssertNotNil(user.preferences)
        XCTAssertEqual(user.preferences?.theme, "dark")
    }
    
    func testUserPersistence() throws {
        let user = User(
            id: "persist-123",
            email: "persist@example.com",
            displayName: "Persist User"
        )
        
        modelContext.insert(user)
        try modelContext.save()
        
        let fetchDescriptor = FetchDescriptor<User>(
            predicate: #Predicate { $0.id == "persist-123" }
        )
        
        let fetchedUsers = try modelContext.fetch(fetchDescriptor)
        
        XCTAssertEqual(fetchedUsers.count, 1)
        XCTAssertEqual(fetchedUsers.first?.email, "persist@example.com")
        XCTAssertEqual(fetchedUsers.first?.displayName, "Persist User")
    }
}