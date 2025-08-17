//
//  DistanceCalculationTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

final class DistanceCalculationTests: XCTestCase {
    
    func testDistanceBetweenSameLocation() {
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let distance = location1.distance(from: location2)
        
        XCTAssertEqual(distance, 0, accuracy: 0.1)
    }
    
    func testDistanceBetweenNearbyLocations() {
        let sanFrancisco = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let oakland = CLLocation(latitude: 37.8044, longitude: -122.2712)
        
        let distance = sanFrancisco.distance(from: oakland)
        
        XCTAssertGreaterThan(distance, 10000)
        XCTAssertLessThan(distance, 20000)
    }
    
    func testDistanceBetweenFarLocations() {
        let sanFrancisco = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let newYork = CLLocation(latitude: 40.7128, longitude: -74.0060)
        
        let distance = sanFrancisco.distance(from: newYork)
        
        XCTAssertGreaterThan(distance, 4000000)
        XCTAssertLessThan(distance, 5000000)
    }
    
    func testDistanceCalculationPrecision() {
        let location1 = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let location2 = CLLocation(latitude: 37.7750, longitude: -122.4195)
        
        let distance = location1.distance(from: location2)
        
        XCTAssertGreaterThan(distance, 10)
        XCTAssertLessThan(distance, 20)
    }
    
    func testTreasureDistanceCalculation() {
        let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let treasure1 = Treasure(
            title: "Near Treasure",
            description: "50m away",
            latitude: 37.7753,
            longitude: -122.4194
        )
        
        let treasure2 = Treasure(
            title: "Medium Treasure",
            description: "500m away",
            latitude: 37.7794,
            longitude: -122.4194
        )
        
        let treasure3 = Treasure(
            title: "Far Treasure",
            description: "5km away",
            latitude: 37.8194,
            longitude: -122.4194
        )
        
        let distance1 = userLocation.distance(from: treasure1.location)
        let distance2 = userLocation.distance(from: treasure2.location)
        let distance3 = userLocation.distance(from: treasure3.location)
        
        XCTAssertLessThan(distance1, 100)
        XCTAssertGreaterThan(distance2, 400)
        XCTAssertLessThan(distance2, 600)
        XCTAssertGreaterThan(distance3, 4000)
        XCTAssertLessThan(distance3, 6000)
    }
    
    func testDistanceArraySorting() {
        let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let treasures = [
            Treasure(title: "Far", description: "Far", latitude: 37.8194, longitude: -122.4194),
            Treasure(title: "Near", description: "Near", latitude: 37.7750, longitude: -122.4194),
            Treasure(title: "Medium", description: "Medium", latitude: 37.7794, longitude: -122.4194)
        ]
        
        let sortedTreasures = treasures.sorted { treasure1, treasure2 in
            let distance1 = userLocation.distance(from: treasure1.location)
            let distance2 = userLocation.distance(from: treasure2.location)
            return distance1 < distance2
        }
        
        XCTAssertEqual(sortedTreasures[0].title, "Near")
        XCTAssertEqual(sortedTreasures[1].title, "Medium")
        XCTAssertEqual(sortedTreasures[2].title, "Far")
    }
    
    func testDistanceFilteringWithRadius() {
        let userLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let radius: CLLocationDistance = 100
        
        let treasures = [
            Treasure(title: "Within 50m", description: "", latitude: 37.7753, longitude: -122.4194),
            Treasure(title: "Within 80m", description: "", latitude: 37.7756, longitude: -122.4194),
            Treasure(title: "Outside 150m", description: "", latitude: 37.7766, longitude: -122.4194),
            Treasure(title: "Outside 500m", description: "", latitude: 37.7794, longitude: -122.4194)
        ]
        
        let nearbyTreasures = treasures.filter { treasure in
            userLocation.distance(from: treasure.location) <= radius
        }
        
        XCTAssertEqual(nearbyTreasures.count, 2)
        XCTAssertTrue(nearbyTreasures.contains { $0.title == "Within 50m" })
        XCTAssertTrue(nearbyTreasures.contains { $0.title == "Within 80m" })
    }
    
    func testBearingCalculation() {
        let locationManager = LocationManager()
        locationManager.currentLocation = CLLocation(latitude: 0, longitude: 0)
        
        let northTreasure = Treasure(title: "North", description: "", latitude: 1, longitude: 0)
        let eastTreasure = Treasure(title: "East", description: "", latitude: 0, longitude: 1)
        let southTreasure = Treasure(title: "South", description: "", latitude: -1, longitude: 0)
        let westTreasure = Treasure(title: "West", description: "", latitude: 0, longitude: -1)
        let northeastTreasure = Treasure(title: "Northeast", description: "", latitude: 1, longitude: 1)
        
        let northBearing = locationManager.bearingToTreasure(northTreasure)
        let eastBearing = locationManager.bearingToTreasure(eastTreasure)
        let southBearing = locationManager.bearingToTreasure(southTreasure)
        let westBearing = locationManager.bearingToTreasure(westTreasure)
        let northeastBearing = locationManager.bearingToTreasure(northeastTreasure)
        
        XCTAssertEqual(northBearing!, 0, accuracy: 1)
        XCTAssertEqual(eastBearing!, 90, accuracy: 1)
        XCTAssertEqual(southBearing!, 180, accuracy: 1)
        XCTAssertEqual(westBearing!, 270, accuracy: 1)
        XCTAssertEqual(northeastBearing!, 45, accuracy: 1)
    }
    
    func testDistanceFormattingForDisplay() {
        let distances: [CLLocationDistance] = [5, 50, 500, 1000, 5000, 10000, 50000]
        let expectedFormats = ["5 m", "50 m", "500 m", "1.0 km", "5.0 km", "10.0 km", "50.0 km"]
        
        for (index, distance) in distances.enumerated() {
            let formatted = formatDistance(distance)
            XCTAssertEqual(formatted, expectedFormats[index])
        }
    }
    
    private func formatDistance(_ distance: CLLocationDistance) -> String {
        if distance < 1000 {
            return String(format: "%.0f m", distance)
        } else {
            return String(format: "%.1f km", distance / 1000)
        }
    }
}