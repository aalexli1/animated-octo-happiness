//
//  TreasureModelTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
import CoreLocation
@testable import animated_octo_happiness_ios

final class TreasureModelTests: XCTestCase {
    
    func testTreasureInitialization() {
        let treasure = Treasure(
            title: "Test Treasure",
            description: "Test Description",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        XCTAssertNotNil(treasure.id)
        XCTAssertEqual(treasure.title, "Test Treasure")
        XCTAssertEqual(treasure.treasureDescription, "Test Description")
        XCTAssertEqual(treasure.latitude, 37.7749)
        XCTAssertEqual(treasure.longitude, -122.4194)
        XCTAssertFalse(treasure.isCollected)
        XCTAssertNil(treasure.notes)
        XCTAssertNil(treasure.imageData)
    }
    
    func testTreasureInitializationWithCoordinate() {
        let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let treasure = Treasure(
            title: "NYC Treasure",
            description: "Found in NYC",
            coordinate: coordinate,
            notes: "Special find"
        )
        
        XCTAssertEqual(treasure.latitude, coordinate.latitude)
        XCTAssertEqual(treasure.longitude, coordinate.longitude)
        XCTAssertEqual(treasure.coordinate.latitude, coordinate.latitude)
        XCTAssertEqual(treasure.coordinate.longitude, coordinate.longitude)
        XCTAssertEqual(treasure.notes, "Special find")
    }
    
    func testTitleValidation() {
        XCTAssertTrue(Treasure.isValidTitle("Valid Title"))
        XCTAssertTrue(Treasure.isValidTitle("A"))
        XCTAssertTrue(Treasure.isValidTitle(String(repeating: "a", count: 100)))
        
        XCTAssertFalse(Treasure.isValidTitle(""))
        XCTAssertFalse(Treasure.isValidTitle("   "))
        XCTAssertFalse(Treasure.isValidTitle(String(repeating: "a", count: 101)))
    }
    
    func testDescriptionValidation() {
        XCTAssertTrue(Treasure.isValidDescription("Valid Description"))
        XCTAssertTrue(Treasure.isValidDescription("A"))
        XCTAssertTrue(Treasure.isValidDescription(String(repeating: "a", count: 500)))
        
        XCTAssertFalse(Treasure.isValidDescription(""))
        XCTAssertFalse(Treasure.isValidDescription("   "))
        XCTAssertFalse(Treasure.isValidDescription(String(repeating: "a", count: 501)))
    }
    
    func testCoordinateValidation() {
        XCTAssertTrue(Treasure.isValidCoordinate(latitude: 0, longitude: 0))
        XCTAssertTrue(Treasure.isValidCoordinate(latitude: 90, longitude: 180))
        XCTAssertTrue(Treasure.isValidCoordinate(latitude: -90, longitude: -180))
        XCTAssertTrue(Treasure.isValidCoordinate(latitude: 45.5, longitude: -122.6))
        
        XCTAssertFalse(Treasure.isValidCoordinate(latitude: 91, longitude: 0))
        XCTAssertFalse(Treasure.isValidCoordinate(latitude: -91, longitude: 0))
        XCTAssertFalse(Treasure.isValidCoordinate(latitude: 0, longitude: 181))
        XCTAssertFalse(Treasure.isValidCoordinate(latitude: 0, longitude: -181))
    }
    
    func testPreviewData() {
        let preview = Treasure.preview
        XCTAssertNotNil(preview)
        XCTAssertEqual(preview.title, "Ancient Coin")
        
        let previewData = Treasure.previewData
        XCTAssertEqual(previewData.count, 3)
        XCTAssertTrue(previewData[0].isCollected)
        XCTAssertFalse(previewData[1].isCollected)
    }
    
    func testTreasureEncodingDecoding() throws {
        let originalTreasure = Treasure(
            title: "Encoded Treasure",
            description: "Test encoding/decoding",
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: Date(),
            isCollected: true,
            notes: "Some notes",
            imageData: Data("test image".utf8),
            emoji: "💰",
            createdBy: "TestUser"
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(originalTreasure)
        
        XCTAssertNotNil(encodedData)
        XCTAssertGreaterThan(encodedData.count, 0)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedTreasure = try decoder.decode(Treasure.self, from: encodedData)
        
        XCTAssertEqual(decodedTreasure.id, originalTreasure.id)
        XCTAssertEqual(decodedTreasure.title, originalTreasure.title)
        XCTAssertEqual(decodedTreasure.treasureDescription, originalTreasure.treasureDescription)
        XCTAssertEqual(decodedTreasure.latitude, originalTreasure.latitude)
        XCTAssertEqual(decodedTreasure.longitude, originalTreasure.longitude)
        XCTAssertEqual(decodedTreasure.isCollected, originalTreasure.isCollected)
        XCTAssertEqual(decodedTreasure.notes, originalTreasure.notes)
        XCTAssertEqual(decodedTreasure.imageData, originalTreasure.imageData)
        XCTAssertEqual(decodedTreasure.emoji, originalTreasure.emoji)
        XCTAssertEqual(decodedTreasure.createdBy, originalTreasure.createdBy)
    }
    
    func testTreasureEncodingWithNilOptionals() throws {
        let treasure = Treasure(
            title: "Simple Treasure",
            description: "No optional fields",
            latitude: 0.0,
            longitude: 0.0
        )
        
        let encoder = JSONEncoder()
        let encodedData = try encoder.encode(treasure)
        
        let decoder = JSONDecoder()
        let decodedTreasure = try decoder.decode(Treasure.self, from: encodedData)
        
        XCTAssertNil(decodedTreasure.notes)
        XCTAssertNil(decodedTreasure.imageData)
        XCTAssertEqual(decodedTreasure.emoji, "🎁")
        XCTAssertNil(decodedTreasure.createdBy)
    }
    
    func testTreasureArrayEncodingDecoding() throws {
        let treasures = [
            Treasure(
                title: "Treasure 1",
                description: "First",
                latitude: 37.7749,
                longitude: -122.4194
            ),
            Treasure(
                title: "Treasure 2",
                description: "Second",
                latitude: 40.7128,
                longitude: -74.0060,
                isCollected: true
            ),
            Treasure(
                title: "Treasure 3",
                description: "Third",
                latitude: 51.5074,
                longitude: -0.1278,
                notes: "London treasure"
            )
        ]
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(treasures)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decodedTreasures = try decoder.decode([Treasure].self, from: encodedData)
        
        XCTAssertEqual(decodedTreasures.count, treasures.count)
        
        for (index, decodedTreasure) in decodedTreasures.enumerated() {
            XCTAssertEqual(decodedTreasure.id, treasures[index].id)
            XCTAssertEqual(decodedTreasure.title, treasures[index].title)
            XCTAssertEqual(decodedTreasure.treasureDescription, treasures[index].treasureDescription)
            XCTAssertEqual(decodedTreasure.latitude, treasures[index].latitude)
            XCTAssertEqual(decodedTreasure.longitude, treasures[index].longitude)
            XCTAssertEqual(decodedTreasure.isCollected, treasures[index].isCollected)
            XCTAssertEqual(decodedTreasure.notes, treasures[index].notes)
        }
    }
    
    func testCoordinateComputation() {
        let treasure = Treasure(
            title: "Test",
            description: "Test",
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        XCTAssertEqual(treasure.coordinate.latitude, 37.7749)
        XCTAssertEqual(treasure.coordinate.longitude, -122.4194)
        
        let location = treasure.location
        XCTAssertEqual(location.coordinate.latitude, 37.7749)
        XCTAssertEqual(location.coordinate.longitude, -122.4194)
    }
}