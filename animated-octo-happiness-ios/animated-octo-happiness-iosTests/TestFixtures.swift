//
//  TestFixtures.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import Foundation
import CoreLocation
@testable import animated_octo_happiness_ios

struct TestFixtures {
    
    static func createTestTreasure(
        title: String = "Test Treasure",
        description: String = "Test Description",
        latitude: Double = 37.7749,
        longitude: Double = -122.4194,
        isCollected: Bool = false,
        notes: String? = nil,
        imageData: Data? = nil,
        emoji: String? = "💎",
        createdBy: String? = nil
    ) -> Treasure {
        Treasure(
            title: title,
            description: description,
            latitude: latitude,
            longitude: longitude,
            timestamp: Date(),
            isCollected: isCollected,
            notes: notes,
            imageData: imageData,
            emoji: emoji,
            createdBy: createdBy
        )
    }
    
    static func createTestTreasures(count: Int) -> [Treasure] {
        (0..<count).map { index in
            createTestTreasure(
                title: "Treasure \(index + 1)",
                description: "Description for treasure \(index + 1)",
                latitude: 37.7749 + Double(index) * 0.001,
                longitude: -122.4194 + Double(index) * 0.001
            )
        }
    }
    
    static func createTreasuresAroundLocation(
        center: CLLocationCoordinate2D,
        count: Int,
        radius: Double
    ) -> [Treasure] {
        var treasures: [Treasure] = []
        
        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * 2 * Double.pi
            let latOffset = (radius / 111000) * cos(angle)
            let lonOffset = (radius / (111000 * cos(center.latitude * Double.pi / 180))) * sin(angle)
            
            let treasure = createTestTreasure(
                title: "Treasure \(i + 1)",
                description: "Located \(Int(radius))m from center",
                latitude: center.latitude + latOffset,
                longitude: center.longitude + lonOffset
            )
            treasures.append(treasure)
        }
        
        return treasures
    }
    
    static var sanFranciscoLocation: CLLocation {
        CLLocation(latitude: 37.7749, longitude: -122.4194)
    }
    
    static var oaklandLocation: CLLocation {
        CLLocation(latitude: 37.8044, longitude: -122.2712)
    }
    
    static var newYorkLocation: CLLocation {
        CLLocation(latitude: 40.7128, longitude: -74.0060)
    }
    
    static var londonLocation: CLLocation {
        CLLocation(latitude: 51.5074, longitude: -0.1278)
    }
    
    static var tokyoLocation: CLLocation {
        CLLocation(latitude: 35.6762, longitude: 139.6503)
    }
    
    static func createMockImageData() -> Data {
        let width = 100
        let height = 100
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let totalBytes = height * bytesPerRow
        
        var pixelData = [UInt8](repeating: 0, count: totalBytes)
        
        for i in 0..<totalBytes {
            switch i % 4 {
            case 0: pixelData[i] = 255
            case 1: pixelData[i] = 128
            case 2: pixelData[i] = 64
            case 3: pixelData[i] = 255
            default: break
            }
        }
        
        return Data(pixelData)
    }
    
    static func createTestARTreasure(
        type: TreasureType = .gold,
        position: SIMD3<Float> = [0, 0, 0],
        isDiscovered: Bool = false
    ) -> ARTreasure {
        var treasure = ARTreasure(
            type: type,
            position: position
        )
        treasure.isDiscovered = isDiscovered
        return treasure
    }
    
    static func createTestARTreasures(count: Int) -> [ARTreasure] {
        let types = TreasureType.allCases
        
        return (0..<count).map { index in
            let type = types[index % types.count]
            let x = Float.random(in: -3...3)
            let z = Float.random(in: -3...3)
            let position = SIMD3<Float>(x, 0.1, z)
            
            return createTestARTreasure(type: type, position: position)
        }
    }
}

class MockLocationManager: LocationManager {
    var mockLocation: CLLocation?
    var mockAuthorizationStatus: CLAuthorizationStatus = .notDetermined
    var mockHeading: CLHeading?
    var mockError: Error?
    
    override var currentLocation: CLLocation? {
        get { mockLocation }
        set { mockLocation = newValue }
    }
    
    override var authorizationStatus: CLAuthorizationStatus {
        get { mockAuthorizationStatus }
        set { mockAuthorizationStatus = newValue }
    }
    
    override var heading: CLHeading? {
        get { mockHeading }
        set { mockHeading = newValue }
    }
    
    override var locationError: Error? {
        get { mockError }
        set { mockError = newValue }
    }
    
    override func requestLocationPermission() {
        mockAuthorizationStatus = .authorizedWhenInUse
    }
    
    override func startUpdatingLocation() {
    }
    
    override func stopUpdatingLocation() {
    }
}

@MainActor
class MockTreasureStore: TreasureStore {
    var mockTreasures: [Treasure] = []
    var addTreasureCalled = false
    var updateTreasureCalled = false
    var deleteTreasureCalled = false
    var saveCalled = false
    
    override var treasures: [Treasure] {
        get { mockTreasures }
        set { mockTreasures = newValue }
    }
    
    override func addTreasure(_ treasure: Treasure) async throws {
        addTreasureCalled = true
        mockTreasures.append(treasure)
    }
    
    override func updateTreasure(_ treasure: Treasure) async throws {
        updateTreasureCalled = true
        if let index = mockTreasures.firstIndex(where: { $0.id == treasure.id }) {
            mockTreasures[index] = treasure
        }
    }
    
    override func deleteTreasure(_ treasure: Treasure) async throws {
        deleteTreasureCalled = true
        mockTreasures.removeAll { $0.id == treasure.id }
    }
}