//
//  PersistenceManagerTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
import CoreLocation
@testable import animated_octo_happiness_ios

@MainActor
final class PersistenceManagerTests: XCTestCase {
    var persistenceManager: PersistenceManager!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            Treasure.self,
            User.self,
            UserPreferences.self,
            PlayerProfile.self,
            GameStatistics.self
        ])
        
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        
        modelContext = modelContainer.mainContext
        persistenceManager = PersistenceManager.shared
        persistenceManager.configure(with: modelContext)
        
        await Task.yield()
    }
    
    override func tearDown() async throws {
        persistenceManager = nil
        modelContext = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    func testDefaultProfileCreation() async throws {
        XCTAssertNotNil(persistenceManager.currentProfile)
        XCTAssertEqual(persistenceManager.allProfiles.count, 1)
        XCTAssertEqual(persistenceManager.currentProfile?.name, "Player 1")
    }
    
    func testCreateNewProfile() async throws {
        try await persistenceManager.createProfile(
            name: "Test Player",
            emoji: "🎮",
            color: "red"
        )
        
        XCTAssertEqual(persistenceManager.allProfiles.count, 2)
        XCTAssertEqual(persistenceManager.currentProfile?.name, "Test Player")
        XCTAssertEqual(persistenceManager.currentProfile?.avatarEmoji, "🎮")
        XCTAssertEqual(persistenceManager.currentProfile?.avatarColor, "red")
        XCTAssertTrue(persistenceManager.currentProfile?.isActive ?? false)
    }
    
    func testSwitchProfile() async throws {
        let originalProfile = persistenceManager.currentProfile
        
        try await persistenceManager.createProfile(
            name: "Player 2",
            emoji: "🎯",
            color: "blue"
        )
        
        let newProfile = persistenceManager.currentProfile
        XCTAssertNotEqual(originalProfile?.id, newProfile?.id)
        
        if let original = persistenceManager.allProfiles.first(where: { $0.id == originalProfile?.id }) {
            try await persistenceManager.switchProfile(to: original)
            XCTAssertEqual(persistenceManager.currentProfile?.id, original.id)
            XCTAssertTrue(original.isActive)
        }
    }
    
    func testDeleteProfile() async throws {
        try await persistenceManager.createProfile(
            name: "To Delete",
            emoji: "❌",
            color: "red"
        )
        
        let profileToDelete = persistenceManager.currentProfile!
        let profileCount = persistenceManager.allProfiles.count
        
        try await persistenceManager.deleteProfile(profileToDelete)
        
        XCTAssertEqual(persistenceManager.allProfiles.count, profileCount - 1)
        XCTAssertNotEqual(persistenceManager.currentProfile?.id, profileToDelete.id)
    }
    
    func testAddTreasure() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        try await persistenceManager.addTreasure(
            title: "Test Treasure",
            description: "Test Description",
            coordinate: coordinate,
            emoji: "💎",
            difficulty: 2,
            hints: ["Hint 1", "Hint 2"]
        )
        
        XCTAssertEqual(persistenceManager.treasures.count, 1)
        
        let treasure = persistenceManager.treasures.first!
        XCTAssertEqual(treasure.title, "Test Treasure")
        XCTAssertEqual(treasure.treasureDescription, "Test Description")
        XCTAssertEqual(treasure.difficulty, 2)
        XCTAssertEqual(treasure.hints.count, 2)
        XCTAssertTrue(treasure.isCustom)
    }
    
    func testCollectTreasure() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        try await persistenceManager.addTreasure(
            title: "Collectible",
            description: "To be collected",
            coordinate: coordinate
        )
        
        let treasure = persistenceManager.treasures.first!
        XCTAssertFalse(treasure.isCollected)
        
        try await persistenceManager.collectTreasure(treasure)
        
        XCTAssertTrue(treasure.isCollected)
        XCTAssertNotNil(treasure.collectedBy)
        XCTAssertNotNil(treasure.collectedAt)
        XCTAssertEqual(treasure.collectedBy, persistenceManager.currentProfile?.id.uuidString)
    }
    
    func testNearbyTreasures() async throws {
        let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        try await persistenceManager.addTreasure(
            title: "Nearby",
            description: "Very close",
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4195)
        )
        
        try await persistenceManager.addTreasure(
            title: "Far Away",
            description: "Too far",
            coordinate: CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        )
        
        let nearby = persistenceManager.nearbyTreasures(from: userLocation, radius: 1000)
        
        XCTAssertEqual(nearby.count, 1)
        XCTAssertEqual(nearby.first?.title, "Nearby")
    }
    
    func testStatisticsTracking() async throws {
        let profile = persistenceManager.currentProfile!
        let stats = profile.statistics!
        
        XCTAssertEqual(stats.totalTreasuresFound, 0)
        XCTAssertEqual(stats.totalTreasuresCreated, 0)
        
        try await persistenceManager.addTreasure(
            title: "Created",
            description: "By user",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        XCTAssertEqual(stats.totalTreasuresCreated, 1)
        XCTAssertEqual(stats.totalPoints, 5)
        
        let treasure = persistenceManager.treasures.first!
        try await persistenceManager.collectTreasure(treasure)
        
        XCTAssertEqual(stats.totalTreasuresFound, 1)
        XCTAssertEqual(stats.totalPoints, 15)
    }
    
    func testExportImport() async throws {
        try await persistenceManager.addTreasure(
            title: "Export Test",
            description: "To be exported",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            emoji: "📦"
        )
        
        let exportData = try await persistenceManager.exportTreasures()
        XCTAssertNotNil(exportData)
        XCTAssertGreaterThan(exportData.count, 0)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportedContent = try decoder.decode(TreasureExportData.self, from: exportData)
        
        XCTAssertEqual(exportedContent.treasures.count, 1)
        XCTAssertEqual(exportedContent.treasures.first?.title, "Export Test")
        XCTAssertEqual(exportedContent.profiles.count, persistenceManager.allProfiles.count)
    }
    
    func testAchievements() async throws {
        let profile = persistenceManager.currentProfile!
        let stats = profile.statistics!
        
        XCTAssertEqual(stats.achievementIds.count, 0)
        
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        try await persistenceManager.addTreasure(
            title: "First",
            description: "Achievement trigger",
            coordinate: coordinate
        )
        
        let treasure = persistenceManager.treasures.first!
        try await persistenceManager.collectTreasure(treasure)
        
        let newAchievements = stats.checkAchievements()
        XCTAssertTrue(newAchievements.contains("first_treasure"))
        XCTAssertTrue(stats.achievementIds.contains("first_treasure"))
    }
}