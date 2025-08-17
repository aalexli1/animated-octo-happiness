//
//  TreasureFormViewModelTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

final class TreasureFormViewModelTests: XCTestCase {
    
    func testInitialization() {
        let viewModel = TreasureFormViewModel()
        
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.description, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertEqual(viewModel.latitude, "")
        XCTAssertEqual(viewModel.longitude, "")
        XCTAssertFalse(viewModel.isCollected)
        XCTAssertNil(viewModel.imageData)
        XCTAssertNil(viewModel.titleError)
        XCTAssertNil(viewModel.descriptionError)
        XCTAssertNil(viewModel.coordinateError)
    }
    
    func testInitializationWithTreasure() {
        let treasure = Treasure(
            title: "Test Treasure",
            description: "Test Description",
            latitude: 37.7749,
            longitude: -122.4194,
            isCollected: true,
            notes: "Test Notes"
        )
        
        let viewModel = TreasureFormViewModel(treasure: treasure)
        
        XCTAssertEqual(viewModel.title, "Test Treasure")
        XCTAssertEqual(viewModel.description, "Test Description")
        XCTAssertEqual(viewModel.notes, "Test Notes")
        XCTAssertEqual(viewModel.latitude, "37.7749")
        XCTAssertEqual(viewModel.longitude, "-122.4194")
        XCTAssertTrue(viewModel.isCollected)
    }
    
    func testSetCurrentLocation() {
        let viewModel = TreasureFormViewModel()
        let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        
        viewModel.setCurrentLocation(coordinate)
        
        XCTAssertEqual(viewModel.latitude, "40.712800")
        XCTAssertEqual(viewModel.longitude, "-74.006000")
        XCTAssertNil(viewModel.coordinateError)
    }
    
    func testTitleValidation() {
        let viewModel = TreasureFormViewModel()
        
        viewModel.title = ""
        XCTAssertFalse(viewModel.validateTitle())
        XCTAssertEqual(viewModel.titleError, "Title is required")
        
        viewModel.title = "   "
        XCTAssertFalse(viewModel.validateTitle())
        XCTAssertEqual(viewModel.titleError, "Title is required")
        
        viewModel.title = String(repeating: "a", count: 101)
        XCTAssertFalse(viewModel.validateTitle())
        XCTAssertEqual(viewModel.titleError, "Title must be 100 characters or less")
        
        viewModel.title = "Valid Title"
        XCTAssertTrue(viewModel.validateTitle())
        XCTAssertNil(viewModel.titleError)
    }
    
    func testDescriptionValidation() {
        let viewModel = TreasureFormViewModel()
        
        viewModel.description = ""
        XCTAssertFalse(viewModel.validateDescription())
        XCTAssertEqual(viewModel.descriptionError, "Description is required")
        
        viewModel.description = "   "
        XCTAssertFalse(viewModel.validateDescription())
        XCTAssertEqual(viewModel.descriptionError, "Description is required")
        
        viewModel.description = String(repeating: "a", count: 501)
        XCTAssertFalse(viewModel.validateDescription())
        XCTAssertEqual(viewModel.descriptionError, "Description must be 500 characters or less")
        
        viewModel.description = "Valid Description"
        XCTAssertTrue(viewModel.validateDescription())
        XCTAssertNil(viewModel.descriptionError)
    }
    
    func testCoordinateValidation() {
        let viewModel = TreasureFormViewModel()
        
        viewModel.latitude = "abc"
        viewModel.longitude = "123"
        XCTAssertFalse(viewModel.validateCoordinates())
        XCTAssertEqual(viewModel.coordinateError, "Invalid coordinate format")
        
        viewModel.latitude = "91"
        viewModel.longitude = "0"
        XCTAssertFalse(viewModel.validateCoordinates())
        XCTAssertEqual(viewModel.coordinateError, "Latitude must be between -90 and 90")
        
        viewModel.latitude = "0"
        viewModel.longitude = "181"
        XCTAssertFalse(viewModel.validateCoordinates())
        XCTAssertEqual(viewModel.coordinateError, "Longitude must be between -180 and 180")
        
        viewModel.latitude = "37.7749"
        viewModel.longitude = "-122.4194"
        XCTAssertTrue(viewModel.validateCoordinates())
        XCTAssertNil(viewModel.coordinateError)
    }
    
    func testIsValid() {
        let viewModel = TreasureFormViewModel()
        
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.title = "Valid Title"
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.description = "Valid Description"
        XCTAssertFalse(viewModel.isValid)
        
        viewModel.latitude = "37.7749"
        viewModel.longitude = "-122.4194"
        XCTAssertTrue(viewModel.isValid)
    }
    
    func testCoordinateProperty() {
        let viewModel = TreasureFormViewModel()
        
        XCTAssertNil(viewModel.coordinate)
        
        viewModel.latitude = "abc"
        viewModel.longitude = "123"
        XCTAssertNil(viewModel.coordinate)
        
        viewModel.latitude = "37.7749"
        viewModel.longitude = "-122.4194"
        let coordinate = viewModel.coordinate
        XCTAssertNotNil(coordinate)
        XCTAssertEqual(coordinate?.latitude, 37.7749)
        XCTAssertEqual(coordinate?.longitude, -122.4194)
    }
    
    func testReset() {
        let viewModel = TreasureFormViewModel()
        
        viewModel.title = "Test"
        viewModel.description = "Test"
        viewModel.notes = "Notes"
        viewModel.latitude = "37.7749"
        viewModel.longitude = "-122.4194"
        viewModel.isCollected = true
        viewModel.imageData = Data()
        viewModel.titleError = "Error"
        viewModel.descriptionError = "Error"
        viewModel.coordinateError = "Error"
        
        viewModel.reset()
        
        XCTAssertEqual(viewModel.title, "")
        XCTAssertEqual(viewModel.description, "")
        XCTAssertEqual(viewModel.notes, "")
        XCTAssertEqual(viewModel.latitude, "")
        XCTAssertEqual(viewModel.longitude, "")
        XCTAssertFalse(viewModel.isCollected)
        XCTAssertNil(viewModel.imageData)
        XCTAssertNil(viewModel.titleError)
        XCTAssertNil(viewModel.descriptionError)
        XCTAssertNil(viewModel.coordinateError)
    }
}