//
//  LocationManagerTests.swift
//  animated-octo-happiness-iosTests
//
//  Unit tests for LocationManager
//

import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

@MainActor
class LocationManagerTests: XCTestCase {
    var locationManager: LocationManager!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
    }
    
    override func tearDown() {
        locationManager = nil
        super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertNil(locationManager.location)
        XCTAssertNil(locationManager.locationError)
        XCTAssertEqual(locationManager.authorizationStatus, CLLocationManager().authorizationStatus)
    }
    
    func testLocationAccuracySetting() {
        locationManager.setLocationAccuracy(kCLLocationAccuracyReduced)
        XCTAssertNotNil(locationManager)
    }
    
    func testLocationErrorEquality() {
        let error1 = LocationManager.LocationError.denied
        let error2 = LocationManager.LocationError.denied
        let error3 = LocationManager.LocationError.restricted
        
        XCTAssertEqual(error1, error2)
        XCTAssertNotEqual(error1, error3)
    }
    
    func testLocationErrorDescriptions() {
        XCTAssertNotNil(LocationManager.LocationError.denied.errorDescription)
        XCTAssertNotNil(LocationManager.LocationError.restricted.errorDescription)
        XCTAssertNotNil(LocationManager.LocationError.locationServicesDisabled.errorDescription)
        XCTAssertNotNil(LocationManager.LocationError.accuracyReduced.errorDescription)
        XCTAssertNotNil(LocationManager.LocationError.timeout.errorDescription)
        XCTAssertNotNil(LocationManager.LocationError.unknown("Test error").errorDescription)
    }
}