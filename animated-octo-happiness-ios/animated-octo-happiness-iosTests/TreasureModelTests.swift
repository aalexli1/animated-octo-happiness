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
}