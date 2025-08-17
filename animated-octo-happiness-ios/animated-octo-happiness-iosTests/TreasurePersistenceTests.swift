//
//  TreasurePersistenceTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
@testable import animated_octo_happiness_ios

@MainActor
final class TreasurePersistenceTests: XCTestCase {
    
    var store: TreasureStore!
    var testDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        testDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: testDirectory, withIntermediateDirectories: true)
        
        store = TreasureStore()
        store.treasures.removeAll()
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: testDirectory)
        store = nil
        try await super.tearDown()
    }
    
    func testPersistSingleTreasure() async throws {
        let treasure = TestFixtures.createTestTreasure(
            title: "Persistent Treasure",
            description: "Should persist",
            notes: "Important notes"
        )
        
        try await store.addTreasure(treasure)
        
        let newStore = TreasureStore()
        
        let foundTreasure = newStore.treasures.first { $0.id == treasure.id }
        XCTAssertNotNil(foundTreasure)
        XCTAssertEqual(foundTreasure?.title, "Persistent Treasure")
        XCTAssertEqual(foundTreasure?.treasureDescription, "Should persist")
        XCTAssertEqual(foundTreasure?.notes, "Important notes")
    }
    
    func testPersistMultipleTreasures() async throws {
        let treasures = TestFixtures.createTestTreasures(count: 5)
        
        for treasure in treasures {
            try await store.addTreasure(treasure)
        }
        
        let newStore = TreasureStore()
        
        XCTAssertEqual(newStore.treasures.count, 5)
        
        for originalTreasure in treasures {
            let foundTreasure = newStore.treasures.first { $0.id == originalTreasure.id }
            XCTAssertNotNil(foundTreasure)
            XCTAssertEqual(foundTreasure?.title, originalTreasure.title)
        }
    }
    
    func testPersistTreasureWithImage() async throws {
        let imageData = TestFixtures.createMockImageData()
        var treasure = TestFixtures.createTestTreasure(
            title: "Treasure with Image",
            imageData: imageData
        )
        treasure.imageData = imageData
        
        try await store.addTreasure(treasure)
        
        let loadedImageData = store.loadPhotoData(for: treasure)
        XCTAssertNotNil(loadedImageData)
        XCTAssertEqual(loadedImageData?.count, imageData.count)
    }
    
    func testPersistenceAfterUpdate() async throws {
        let treasure = TestFixtures.createTestTreasure()
        try await store.addTreasure(treasure)
        
        var updatedTreasure = treasure
        updatedTreasure.isCollected = true
        updatedTreasure.notes = "Updated after collection"
        
        try await store.updateTreasure(updatedTreasure)
        
        let newStore = TreasureStore()
        let foundTreasure = newStore.treasures.first { $0.id == treasure.id }
        
        XCTAssertNotNil(foundTreasure)
        XCTAssertTrue(foundTreasure!.isCollected)
        XCTAssertEqual(foundTreasure?.notes, "Updated after collection")
    }
    
    func testPersistenceAfterDelete() async throws {
        let treasure1 = TestFixtures.createTestTreasure(title: "Keep Me")
        let treasure2 = TestFixtures.createTestTreasure(title: "Delete Me")
        
        try await store.addTreasure(treasure1)
        try await store.addTreasure(treasure2)
        
        XCTAssertEqual(store.treasures.count, 2)
        
        try await store.deleteTreasure(treasure2)
        
        let newStore = TreasureStore()
        
        XCTAssertEqual(newStore.treasures.count, 1)
        XCTAssertNotNil(newStore.treasures.first { $0.id == treasure1.id })
        XCTAssertNil(newStore.treasures.first { $0.id == treasure2.id })
    }
    
    func testImagePersistenceAfterDelete() async throws {
        let imageData = TestFixtures.createMockImageData()
        var treasure = TestFixtures.createTestTreasure(imageData: imageData)
        treasure.imageData = imageData
        
        try await store.addTreasure(treasure)
        
        let loadedImageData = store.loadPhotoData(for: treasure)
        XCTAssertNotNil(loadedImageData)
        
        try await store.deleteTreasure(treasure)
        
        let deletedImageData = store.loadPhotoData(for: treasure)
        XCTAssertNil(deletedImageData)
    }
    
    func testPersistenceWithSpecialCharacters() async throws {
        let treasure = TestFixtures.createTestTreasure(
            title: "Special 🎉 Characters & Symbols",
            description: "Contains émojis 💎 and ümlàuts",
            notes: "Line 1\nLine 2\tTabbed\r\nWindows line break"
        )
        
        try await store.addTreasure(treasure)
        
        let newStore = TreasureStore()
        let foundTreasure = newStore.treasures.first { $0.id == treasure.id }
        
        XCTAssertNotNil(foundTreasure)
        XCTAssertEqual(foundTreasure?.title, treasure.title)
        XCTAssertEqual(foundTreasure?.treasureDescription, treasure.treasureDescription)
        XCTAssertEqual(foundTreasure?.notes, treasure.notes)
    }
    
    func testConcurrentPersistence() async throws {
        let treasures = TestFixtures.createTestTreasures(count: 10)
        
        await withTaskGroup(of: Void.self) { group in
            for treasure in treasures {
                group.addTask {
                    try? await self.store.addTreasure(treasure)
                }
            }
        }
        
        let newStore = TreasureStore()
        XCTAssertEqual(newStore.treasures.count, 10)
    }
    
    func testPersistenceWithLargeDataSet() async throws {
        let treasures = TestFixtures.createTestTreasures(count: 100)
        
        for treasure in treasures {
            try await store.addTreasure(treasure)
        }
        
        let newStore = TreasureStore()
        XCTAssertEqual(newStore.treasures.count, 100)
        
        for originalTreasure in treasures {
            let foundTreasure = newStore.treasures.first { $0.id == originalTreasure.id }
            XCTAssertNotNil(foundTreasure)
        }
    }
    
    func testDatePersistence() async throws {
        let specificDate = Date(timeIntervalSince1970: 1234567890)
        var treasure = TestFixtures.createTestTreasure()
        treasure.timestamp = specificDate
        
        try await store.addTreasure(treasure)
        
        let newStore = TreasureStore()
        let foundTreasure = newStore.treasures.first { $0.id == treasure.id }
        
        XCTAssertNotNil(foundTreasure)
        XCTAssertEqual(foundTreasure?.timestamp.timeIntervalSince1970, specificDate.timeIntervalSince1970, accuracy: 1)
    }
}