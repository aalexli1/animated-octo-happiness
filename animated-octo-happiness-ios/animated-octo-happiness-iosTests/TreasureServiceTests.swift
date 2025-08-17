//
//  TreasureServiceTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
import CoreLocation
@testable import animated_octo_happiness_ios

@MainActor
final class TreasureServiceTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var treasureService: TreasureService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([Treasure.self])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: true
        )
        modelContainer = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )
        modelContext = modelContainer.mainContext
        treasureService = TreasureService(modelContext: modelContext)
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        treasureService = nil
        try await super.tearDown()
    }
    
    func testCreateTreasure() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let treasure = try treasureService.createTreasure(
            title: "Test Treasure",
            description: "Test Description",
            coordinate: coordinate,
            notes: "Test Notes"
        )
        
        XCTAssertNotNil(treasure)
        XCTAssertEqual(treasure.title, "Test Treasure")
        XCTAssertEqual(treasure.treasureDescription, "Test Description")
        XCTAssertEqual(treasure.latitude, coordinate.latitude)
        XCTAssertEqual(treasure.longitude, coordinate.longitude)
        XCTAssertEqual(treasure.notes, "Test Notes")
        
        let fetchedTreasures = try treasureService.fetchAllTreasures()
        XCTAssertEqual(fetchedTreasures.count, 1)
        XCTAssertEqual(fetchedTreasures.first?.id, treasure.id)
    }
    
    func testCreateTreasureWithInvalidTitle() async {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            _ = try treasureService.createTreasure(
                title: "",
                description: "Valid Description",
                coordinate: coordinate
            )
            XCTFail("Should have thrown invalidTitle error")
        } catch {
            XCTAssertTrue(error is TreasureServiceError)
            if case TreasureServiceError.invalidTitle = error {
            } else {
                XCTFail("Wrong error type thrown")
            }
        }
    }
    
    func testCreateTreasureWithInvalidDescription() async {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        do {
            _ = try treasureService.createTreasure(
                title: "Valid Title",
                description: "",
                coordinate: coordinate
            )
            XCTFail("Should have thrown invalidDescription error")
        } catch {
            XCTAssertTrue(error is TreasureServiceError)
            if case TreasureServiceError.invalidDescription = error {
            } else {
                XCTFail("Wrong error type thrown")
            }
        }
    }
    
    func testCreateTreasureWithInvalidCoordinates() async {
        let coordinate = CLLocationCoordinate2D(latitude: 91, longitude: -122.4194)
        
        do {
            _ = try treasureService.createTreasure(
                title: "Valid Title",
                description: "Valid Description",
                coordinate: coordinate
            )
            XCTFail("Should have thrown invalidCoordinates error")
        } catch {
            XCTAssertTrue(error is TreasureServiceError)
            if case TreasureServiceError.invalidCoordinates = error {
            } else {
                XCTFail("Wrong error type thrown")
            }
        }
    }
    
    func testFetchTreasureById() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let treasure = try treasureService.createTreasure(
            title: "Test Treasure",
            description: "Test Description",
            coordinate: coordinate
        )
        
        let fetchedTreasure = try treasureService.fetchTreasure(by: treasure.id)
        XCTAssertNotNil(fetchedTreasure)
        XCTAssertEqual(fetchedTreasure?.id, treasure.id)
        
        let nonExistentTreasure = try treasureService.fetchTreasure(by: UUID())
        XCTAssertNil(nonExistentTreasure)
    }
    
    func testFetchCollectedAndUncollectedTreasures() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let treasure1 = try treasureService.createTreasure(
            title: "Collected Treasure",
            description: "Description",
            coordinate: coordinate
        )
        treasure1.isCollected = true
        try modelContext.save()
        
        _ = try treasureService.createTreasure(
            title: "Uncollected Treasure",
            description: "Description",
            coordinate: coordinate
        )
        
        let collectedTreasures = try treasureService.fetchCollectedTreasures()
        XCTAssertEqual(collectedTreasures.count, 1)
        XCTAssertEqual(collectedTreasures.first?.title, "Collected Treasure")
        
        let uncollectedTreasures = try treasureService.fetchUncollectedTreasures()
        XCTAssertEqual(uncollectedTreasures.count, 1)
        XCTAssertEqual(uncollectedTreasures.first?.title, "Uncollected Treasure")
    }
    
    func testUpdateTreasure() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let treasure = try treasureService.createTreasure(
            title: "Original Title",
            description: "Original Description",
            coordinate: coordinate
        )
        
        let newCoordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        try treasureService.updateTreasure(
            treasure,
            title: "Updated Title",
            description: "Updated Description",
            coordinate: newCoordinate,
            isCollected: true,
            notes: "Updated Notes"
        )
        
        XCTAssertEqual(treasure.title, "Updated Title")
        XCTAssertEqual(treasure.treasureDescription, "Updated Description")
        XCTAssertEqual(treasure.latitude, newCoordinate.latitude)
        XCTAssertEqual(treasure.longitude, newCoordinate.longitude)
        XCTAssertTrue(treasure.isCollected)
        XCTAssertEqual(treasure.notes, "Updated Notes")
    }
    
    func testMarkAsCollected() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let treasure = try treasureService.createTreasure(
            title: "Test Treasure",
            description: "Test Description",
            coordinate: coordinate
        )
        
        XCTAssertFalse(treasure.isCollected)
        
        try treasureService.markAsCollected(treasure)
        
        XCTAssertTrue(treasure.isCollected)
    }
    
    func testDeleteTreasure() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let treasure = try treasureService.createTreasure(
            title: "Test Treasure",
            description: "Test Description",
            coordinate: coordinate
        )
        
        var treasures = try treasureService.fetchAllTreasures()
        XCTAssertEqual(treasures.count, 1)
        
        try treasureService.deleteTreasure(treasure)
        
        treasures = try treasureService.fetchAllTreasures()
        XCTAssertEqual(treasures.count, 0)
    }
    
    func testDeleteAllTreasures() async throws {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        for i in 1...5 {
            _ = try treasureService.createTreasure(
                title: "Treasure \(i)",
                description: "Description \(i)",
                coordinate: coordinate
            )
        }
        
        var treasures = try treasureService.fetchAllTreasures()
        XCTAssertEqual(treasures.count, 5)
        
        try treasureService.deleteAllTreasures()
        
        treasures = try treasureService.fetchAllTreasures()
        XCTAssertEqual(treasures.count, 0)
    }
    
    func testTreasuresNearLocation() async throws {
        let coordinate1 = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let coordinate2 = CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4192)
        let coordinate3 = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        
        _ = try treasureService.createTreasure(
            title: "Near Treasure 1",
            description: "Description",
            coordinate: coordinate1
        )
        
        _ = try treasureService.createTreasure(
            title: "Near Treasure 2",
            description: "Description",
            coordinate: coordinate2
        )
        
        _ = try treasureService.createTreasure(
            title: "Far Treasure",
            description: "Description",
            coordinate: coordinate3
        )
        
        let nearbyTreasures = try treasureService.treasuresNearLocation(
            coordinate: coordinate1,
            radiusInMeters: 1000
        )
        
        XCTAssertEqual(nearbyTreasures.count, 2)
        XCTAssertTrue(nearbyTreasures.contains { $0.title == "Near Treasure 1" })
        XCTAssertTrue(nearbyTreasures.contains { $0.title == "Near Treasure 2" })
        XCTAssertFalse(nearbyTreasures.contains { $0.title == "Far Treasure" })
    }
}