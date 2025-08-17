//
//  TreasureTests.swift
//  animated-octo-happiness-iosTests
//
//  Created by Claude on 8/17/25.
//

import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

final class TreasureTests: XCTestCase {
    
    func testTreasureInitialization() {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let treasure = Treasure(
            name: "Test Treasure",
            coordinate: coordinate,
            symbolName: "star.fill",
            hint: "Test hint"
        )
        
        XCTAssertEqual(treasure.name, "Test Treasure")
        XCTAssertEqual(treasure.coordinate.latitude, 37.7749)
        XCTAssertEqual(treasure.coordinate.longitude, -122.4194)
        XCTAssertEqual(treasure.symbolName, "star.fill")
        XCTAssertEqual(treasure.hint, "Test hint")
        XCTAssertFalse(treasure.isFound)
    }
    
    func testTreasureDefaultValues() {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let treasure = Treasure(name: "Test", coordinate: coordinate)
        
        XCTAssertEqual(treasure.symbolName, "star.fill")
        XCTAssertNil(treasure.hint)
        XCTAssertFalse(treasure.isFound)
    }
    
    func testTreasureEquality() {
        let coordinate = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        let treasure1 = Treasure(name: "Test", coordinate: coordinate)
        let treasure2 = treasure1
        let treasure3 = Treasure(name: "Different", coordinate: coordinate)
        
        XCTAssertEqual(treasure1, treasure2)
        XCTAssertNotEqual(treasure1, treasure3)
    }
    
    func testSampleTreasures() {
        let samples = Treasure.sampleTreasures
        
        XCTAssertEqual(samples.count, 3)
        XCTAssertEqual(samples[0].name, "Golden Star")
        XCTAssertEqual(samples[1].name, "Diamond Gem")
        XCTAssertEqual(samples[2].name, "Ancient Coin")
        
        for treasure in samples {
            XCTAssertFalse(treasure.isFound)
            XCTAssertNotNil(treasure.hint)
        }
    }
}