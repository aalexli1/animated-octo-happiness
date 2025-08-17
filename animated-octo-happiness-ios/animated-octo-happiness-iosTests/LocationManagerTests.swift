//
//  LocationManagerTests.swift
//  animated-octo-happiness-iosTests
//
//  Unit tests for LocationManager
//

import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

class LocationManagerTests: XCTestCase {
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager.stopUpdatingLocation()
        locationManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertNil(locationManager.currentLocation)
        XCTAssertNil(locationManager.heading)
        XCTAssertNil(locationManager.locationError)
        XCTAssertEqual(locationManager.authorizationStatus, .notDetermined)
    }
    
    func testDistanceToTreasureWithoutLocation() {
        let treasure = createTestTreasure()
        let distance = locationManager.distanceToTreasure(treasure)
        
        XCTAssertNil(distance)
    }
    
    func testDistanceToTreasureWithLocation() {
        locationManager.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let treasure = createTestTreasure(latitude: 37.7750, longitude: -122.4195)
        let distance = locationManager.distanceToTreasure(treasure)
        
        XCTAssertNotNil(distance)
        XCTAssertGreaterThan(distance!, 0)
        XCTAssertLessThan(distance!, 20)
    }
    
    func testBearingToTreasureWithoutLocation() {
        let treasure = createTestTreasure()
        let bearing = locationManager.bearingToTreasure(treasure)
        
        XCTAssertNil(bearing)
    }
    
    func testBearingToTreasureWithLocation() {
        locationManager.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let northTreasure = createTestTreasure(latitude: 37.7850, longitude: -122.4194)
        let northBearing = locationManager.bearingToTreasure(northTreasure)
        
        XCTAssertNotNil(northBearing)
        XCTAssertGreaterThanOrEqual(northBearing!, 0)
        XCTAssertLessThan(northBearing!, 360)
    }
    
    func testBearingCalculationDirections() {
        locationManager.currentLocation = CLLocation(latitude: 0, longitude: 0)
        
        let northTreasure = createTestTreasure(latitude: 1, longitude: 0)
        let northBearing = locationManager.bearingToTreasure(northTreasure)
        XCTAssertNotNil(northBearing)
        XCTAssertEqual(northBearing!, 0, accuracy: 1)
        
        let eastTreasure = createTestTreasure(latitude: 0, longitude: 1)
        let eastBearing = locationManager.bearingToTreasure(eastTreasure)
        XCTAssertNotNil(eastBearing)
        XCTAssertEqual(eastBearing!, 90, accuracy: 1)
        
        let southTreasure = createTestTreasure(latitude: -1, longitude: 0)
        let southBearing = locationManager.bearingToTreasure(southTreasure)
        XCTAssertNotNil(southBearing)
        XCTAssertEqual(southBearing!, 180, accuracy: 1)
        
        let westTreasure = createTestTreasure(latitude: 0, longitude: -1)
        let westBearing = locationManager.bearingToTreasure(westTreasure)
        XCTAssertNotNil(westBearing)
        XCTAssertEqual(westBearing!, 270, accuracy: 1)
    }
    
    func testGetNearbyTreasuresWithoutLocation() {
        let treasures = [
            createTestTreasure(latitude: 37.7749, longitude: -122.4194),
            createTestTreasure(latitude: 37.7750, longitude: -122.4195),
            createTestTreasure(latitude: 37.7751, longitude: -122.4196)
        ]
        
        let nearbyTreasures = locationManager.getNearbyTreasures(treasures)
        
        XCTAssertEqual(nearbyTreasures.count, 0)
    }
    
    func testGetNearbyTreasuresWithLocation() {
        locationManager.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let nearTreasure = createTestTreasure(latitude: 37.7750, longitude: -122.4195)
        let farTreasure = createTestTreasure(latitude: 40.7128, longitude: -74.0060)
        
        let treasures = [nearTreasure, farTreasure]
        let nearbyTreasures = locationManager.getNearbyTreasures(treasures, radius: 100)
        
        XCTAssertEqual(nearbyTreasures.count, 1)
        XCTAssertEqual(nearbyTreasures.first?.id, nearTreasure.id)
    }
    
    func testGetNearbyTreasuresWithCustomRadius() {
        locationManager.currentLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        
        let treasure50m = createTestTreasure(latitude: 37.7753, longitude: -122.4194)
        let treasure150m = createTestTreasure(latitude: 37.7762, longitude: -122.4194)
        let treasure500m = createTestTreasure(latitude: 37.7794, longitude: -122.4194)
        
        let treasures = [treasure50m, treasure150m, treasure500m]
        
        let nearby100m = locationManager.getNearbyTreasures(treasures, radius: 100)
        XCTAssertEqual(nearby100m.count, 1)
        
        let nearby200m = locationManager.getNearbyTreasures(treasures, radius: 200)
        XCTAssertEqual(nearby200m.count, 2)
        
        let nearby1000m = locationManager.getNearbyTreasures(treasures, radius: 1000)
        XCTAssertEqual(nearby1000m.count, 3)
    }
    
    func testLocationManagerDelegateDidUpdateLocations() {
        let testLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let locations = [testLocation]
        
        locationManager.locationManager(CLLocationManager(), didUpdateLocations: locations)
        
        XCTAssertNotNil(locationManager.currentLocation)
        XCTAssertEqual(locationManager.currentLocation?.coordinate.latitude, 37.7749)
        XCTAssertEqual(locationManager.currentLocation?.coordinate.longitude, -122.4194)
    }
    
    func testLocationManagerDelegateDidUpdateHeading() {
        let testHeading = CLHeading()
        
        locationManager.locationManager(CLLocationManager(), didUpdateHeading: testHeading)
        
        XCTAssertNotNil(locationManager.heading)
    }
    
    func testLocationManagerDelegateDidFailWithError() {
        let testError = NSError(domain: kCLErrorDomain, code: CLError.denied.rawValue, userInfo: nil)
        
        locationManager.locationManager(CLLocationManager(), didFailWithError: testError)
        
        XCTAssertNotNil(locationManager.locationError)
    }
    
    func testLocationManagerAuthorizationChangeToAuthorized() {
        let mockManager = CLLocationManager()
        
        locationManager.locationManagerDidChangeAuthorization(mockManager)
        
        XCTAssertEqual(locationManager.authorizationStatus, mockManager.authorizationStatus)
    }
    
    func testRequestLocationPermission() {
        locationManager.requestLocationPermission()
        XCTAssertNotNil(locationManager)
    }
    
    func testStartAndStopUpdatingLocation() {
        locationManager.startUpdatingLocation()
        XCTAssertNotNil(locationManager)
        
        locationManager.stopUpdatingLocation()
        XCTAssertNotNil(locationManager)
    }
    
    private func createTestTreasure(latitude: Double = 37.7749, longitude: Double = -122.4194) -> Treasure {
        Treasure(
            title: "Test Treasure",
            description: "Test Description",
            latitude: latitude,
            longitude: longitude
        )
    }
}