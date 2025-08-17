//
//  LocationManagerTests.swift
//  animated-octo-happiness-iosTests
//
//  Created by Claude on 8/17/25.
//

import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

final class LocationManagerTests: XCTestCase {
    
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        super.tearDown()
    }
    
    func testDistanceToTreasureWithNoLocation() {
        let treasure = Treasure(
            name: "Test Treasure",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        XCTAssertNil(locationManager.distanceToTreasure(treasure))
    }
    
    func testBearingCalculation() {
        locationManager.currentLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        let treasure = Treasure(
            name: "North Treasure",
            coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4194)
        )
        
        if let bearing = locationManager.bearingToTreasure(treasure) {
            XCTAssertEqual(bearing, 0, accuracy: 5)
        } else {
            XCTFail("Bearing calculation failed")
        }
    }
    
    func testGetNearbyTreasures() {
        locationManager.currentLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        let nearbyTreasure = Treasure(
            name: "Nearby",
            coordinate: CLLocationCoordinate2D(latitude: 37.7750, longitude: -122.4194)
        )
        
        let farTreasure = Treasure(
            name: "Far",
            coordinate: CLLocationCoordinate2D(latitude: 37.8000, longitude: -122.4000)
        )
        
        let treasures = [nearbyTreasure, farTreasure]
        let nearby = locationManager.getNearbyTreasures(treasures, radius: 50)
        
        XCTAssertEqual(nearby.count, 1)
        XCTAssertEqual(nearby.first?.name, "Nearby")
    }
    
    func testGetNearbyTreasuresWithNoLocation() {
        let treasure = Treasure(
            name: "Test",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        let nearby = locationManager.getNearbyTreasures([treasure])
        XCTAssertTrue(nearby.isEmpty)
    }
}