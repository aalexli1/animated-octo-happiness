//
//  TreasureStoreTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

@MainActor
final class TreasureStoreTests: XCTestCase {
    
    var store: TreasureStore!
    var testDocumentsDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let tempDirectory = FileManager.default.temporaryDirectory
        testDocumentsDirectory = tempDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDocumentsDirectory, withIntermediateDirectories: true)
        
        store = TreasureStore()
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testDocumentsDirectory)
        store = nil
        try await super.tearDown()
    }
    
    func testAddTreasure() async throws {
        let treasure = createTestTreasure()
        let initialCount = store.treasures.count
        
        try await store.addTreasure(treasure)
        
        XCTAssertEqual(store.treasures.count, initialCount + 1)
        XCTAssertTrue(store.treasures.contains { $0.id == treasure.id })
    }
    
    func testAddTreasureWithImageData() async throws {
        let imageData = Data("test image data".utf8)
        var treasure = createTestTreasure()
        treasure.imageData = imageData
        
        try await store.addTreasure(treasure)
        
        XCTAssertEqual(store.treasures.count, 1)
        let storedTreasure = store.treasures.first!
        
        let loadedPhotoData = store.loadPhotoData(for: storedTreasure)
        XCTAssertNotNil(loadedPhotoData)
    }
    
    func testUpdateTreasure() async throws {
        let treasure = createTestTreasure()
        try await store.addTreasure(treasure)
        
        var updatedTreasure = treasure
        updatedTreasure.isCollected = true
        updatedTreasure.notes = "Updated notes"
        
        try await store.updateTreasure(updatedTreasure)
        
        let storedTreasure = store.treasures.first { $0.id == treasure.id }
        XCTAssertNotNil(storedTreasure)
        XCTAssertTrue(storedTreasure!.isCollected)
        XCTAssertEqual(storedTreasure!.notes, "Updated notes")
    }
    
    func testUpdateNonExistentTreasure() async throws {
        let treasure = createTestTreasure()
        let initialCount = store.treasures.count
        
        try await store.updateTreasure(treasure)
        
        XCTAssertEqual(store.treasures.count, initialCount)
    }
    
    func testDeleteTreasure() async throws {
        let treasure = createTestTreasure()
        try await store.addTreasure(treasure)
        
        XCTAssertEqual(store.treasures.count, 1)
        
        try await store.deleteTreasure(treasure)
        
        XCTAssertEqual(store.treasures.count, 0)
        XCTAssertFalse(store.treasures.contains { $0.id == treasure.id })
    }
    
    func testDeleteTreasureWithPhoto() async throws {
        let imageData = Data("test image data".utf8)
        var treasure = createTestTreasure()
        treasure.imageData = imageData
        
        try await store.addTreasure(treasure)
        let loadedPhotoData = store.loadPhotoData(for: treasure)
        XCTAssertNotNil(loadedPhotoData)
        
        try await store.deleteTreasure(treasure)
        
        let deletedPhotoData = store.loadPhotoData(for: treasure)
        XCTAssertNil(deletedPhotoData)
    }
    
    func testMarkTreasureAsCollected() async throws {
        let treasure = createTestTreasure()
        try await store.addTreasure(treasure)
        
        var collectedTreasure = treasure
        collectedTreasure.isCollected = true
        
        try await store.updateTreasure(collectedTreasure)
        
        let storedTreasure = store.treasures.first { $0.id == treasure.id }
        XCTAssertNotNil(storedTreasure)
        XCTAssertTrue(storedTreasure!.isCollected)
    }
    
    func testNearbyTreasures() async throws {
        let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let nearbyTreasure1 = Treasure(
            title: "Nearby 1",
            description: "Close treasure",
            latitude: 37.7750,
            longitude: -122.4195
        )
        
        let nearbyTreasure2 = Treasure(
            title: "Nearby 2",
            description: "Another close treasure",
            latitude: 37.7748,
            longitude: -122.4193
        )
        
        let farTreasure = Treasure(
            title: "Far Away",
            description: "Distant treasure",
            latitude: 40.7128,
            longitude: -74.0060
        )
        
        try await store.addTreasure(nearbyTreasure1)
        try await store.addTreasure(nearbyTreasure2)
        try await store.addTreasure(farTreasure)
        
        let nearbyResults = store.nearbyTreasures(from: userLocation, radius: 100)
        
        XCTAssertEqual(nearbyResults.count, 2)
        XCTAssertTrue(nearbyResults.contains { $0.id == nearbyTreasure1.id })
        XCTAssertTrue(nearbyResults.contains { $0.id == nearbyTreasure2.id })
        XCTAssertFalse(nearbyResults.contains { $0.id == farTreasure.id })
    }
    
    func testUserCreatedTreasures() async throws {
        let user1 = "User1"
        let user2 = "User2"
        
        let treasure1 = Treasure(
            title: "Treasure 1",
            description: "Test",
            latitude: 37.7749,
            longitude: -122.4194,
            createdBy: user1
        )
        
        let treasure2 = Treasure(
            title: "Treasure 2",
            description: "Test",
            latitude: 37.7749,
            longitude: -122.4194,
            createdBy: user1
        )
        
        let treasure3 = Treasure(
            title: "Treasure 3",
            description: "Test",
            latitude: 37.7749,
            longitude: -122.4194,
            createdBy: user2
        )
        
        try await store.addTreasure(treasure1)
        try await store.addTreasure(treasure2)
        try await store.addTreasure(treasure3)
        
        let user1Treasures = store.userCreatedTreasures(by: user1)
        
        XCTAssertEqual(user1Treasures.count, 2)
        XCTAssertTrue(user1Treasures.allSatisfy { $0.createdBy == user1 })
    }
    
    func testFilteringByCollectedStatus() async throws {
        let treasure1 = createTestTreasure()
        var treasure2 = createTestTreasure()
        treasure2.isCollected = true
        var treasure3 = createTestTreasure()
        treasure3.isCollected = true
        
        try await store.addTreasure(treasure1)
        try await store.addTreasure(treasure2)
        try await store.addTreasure(treasure3)
        
        let uncollectedTreasures = store.treasures.filter { !$0.isCollected }
        let collectedTreasures = store.treasures.filter { $0.isCollected }
        
        XCTAssertEqual(uncollectedTreasures.count, 1)
        XCTAssertEqual(collectedTreasures.count, 2)
    }
    
    func testLoadPhotoDataNonExistent() {
        let treasure = createTestTreasure()
        let photoData = store.loadPhotoData(for: treasure)
        
        XCTAssertNil(photoData)
    }
    
    func testPersistenceAcrossInstances() async throws {
        let treasure1 = createTestTreasure()
        let treasure2 = createTestTreasure()
        
        try await store.addTreasure(treasure1)
        try await store.addTreasure(treasure2)
        
        let newStore = TreasureStore()
        
        XCTAssertEqual(newStore.treasures.count, 2)
        XCTAssertTrue(newStore.treasures.contains { $0.id == treasure1.id })
        XCTAssertTrue(newStore.treasures.contains { $0.id == treasure2.id })
    }
    
    private func createTestTreasure() -> Treasure {
        Treasure(
            title: "Test Treasure",
            description: "Test Description",
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: Date(),
            isCollected: false,
            notes: "Test notes",
            emoji: "💎"
        )
    }
}