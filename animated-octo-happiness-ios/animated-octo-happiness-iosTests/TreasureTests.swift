//
//  TreasureTests.swift
//  animated-octo-happiness-iosTests
//
//  Created by Alex on 8/17/25.
//

import XCTest
@testable import animated_octo_happiness_ios

class TreasureTests: XCTestCase {
    
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
        XCTAssertFalse(treasure.isCollected)
        XCTAssertEqual(treasure.latitude, 37.7749)
        XCTAssertEqual(treasure.longitude, -122.4194)
    }
    
    func testTreasureTypePoints() {
        XCTAssertEqual(TreasureType.gold.points, 100)
        XCTAssertEqual(TreasureType.silver.points, 50)
        XCTAssertEqual(TreasureType.bronze.points, 25)
        XCTAssertEqual(TreasureType.gem.points, 75)
        XCTAssertEqual(TreasureType.artifact.points, 150)
    }
    
    func testTreasureTypeColors() {
        XCTAssertEqual(TreasureType.gold.color, .systemYellow)
        XCTAssertEqual(TreasureType.silver.color, .systemGray)
        XCTAssertEqual(TreasureType.bronze.color, .systemBrown)
        XCTAssertEqual(TreasureType.gem.color, .systemPurple)
        XCTAssertEqual(TreasureType.artifact.color, .systemTeal)
    }
    
    func testARTreasureGeneration() {
        let manager = TreasureManager()
        let treasures = manager.generateTreasures(count: 10)
        
        XCTAssertEqual(treasures.count, 10)
        
        for treasure in treasures {
            XCTAssertNotNil(treasure.id)
            XCTAssertFalse(treasure.isDiscovered)
            XCTAssertTrue(treasure.position.x >= -3 && treasure.position.x <= 3)
            XCTAssertTrue(treasure.position.z >= -3 && treasure.position.z <= 3)
            XCTAssertEqual(treasure.position.y, 0.1)
        }
    }
}