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
        let treasure = Treasure(type: .gold, position: [1, 0, 1])
        
        XCTAssertNotNil(treasure.id)
        XCTAssertEqual(treasure.type, .gold)
        XCTAssertFalse(treasure.isDiscovered)
        XCTAssertEqual(treasure.position, [1, 0, 1])
        XCTAssertEqual(treasure.discoveryRadius, 0.5)
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
    
    func testTreasureManagerGeneration() {
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