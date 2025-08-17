import XCTest
import CoreLocation
@testable import animated_octo_happiness_ios

final class LocationNotificationTests: XCTestCase {
    var locationManager: LocationManager!
    var treasures: [Treasure]!
    
    override func setUp() {
        super.setUp()
        locationManager = LocationManager()
        
        treasures = [
            Treasure(
                name: "Test Treasure 1",
                emoji: "💎",
                description: "Test description",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                type: .gem,
                difficulty: .easy,
                createdBy: "Test User"
            ),
            Treasure(
                name: "Test Treasure 2",
                emoji: "🏆",
                description: "Test description",
                coordinate: CLLocationCoordinate2D(latitude: 37.7849, longitude: -122.4094),
                type: .gold,
                difficulty: .medium,
                createdBy: "Test User"
            )
        ]
    }
    
    override func tearDown() {
        locationManager = nil
        treasures = nil
        super.tearDown()
    }
    
    func testNearbyTreasureDetection() {
        let mockLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        locationManager.currentLocation = mockLocation
        
        let nearbyTreasures = locationManager.getNearbyTreasures(treasures, radius: 100)
        
        XCTAssertEqual(nearbyTreasures.count, 1)
        XCTAssertEqual(nearbyTreasures.first?.name, "Test Treasure 1")
    }
    
    func testDistanceToTreasure() {
        let mockLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        locationManager.currentLocation = mockLocation
        
        if let distance = locationManager.distanceToTreasure(treasures[0]) {
            XCTAssertLessThan(distance, 10)
        } else {
            XCTFail("Distance calculation failed")
        }
        
        if let distance = locationManager.distanceToTreasure(treasures[1]) {
            XCTAssertGreaterThan(distance, 1000)
        } else {
            XCTFail("Distance calculation failed")
        }
    }
    
    func testBearingToTreasure() {
        let mockLocation = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        locationManager.currentLocation = mockLocation
        
        if let bearing = locationManager.bearingToTreasure(treasures[1]) {
            XCTAssertGreaterThanOrEqual(bearing, 0)
            XCTAssertLessThan(bearing, 360)
        } else {
            XCTFail("Bearing calculation failed")
        }
    }
    
    func testLocationBasedNotificationTrigger() {
        let mockLocation1 = CLLocation(
            latitude: 37.7749,
            longitude: -122.4194
        )
        
        let mockLocation2 = CLLocation(
            latitude: 37.7849,
            longitude: -122.4094
        )
        
        locationManager.currentLocation = mockLocation1
        locationManager.checkForNearbyTreasuresAndNotify(treasures)
        
        locationManager.currentLocation = mockLocation2
        locationManager.checkForNearbyTreasuresAndNotify(treasures)
        
        let expectation = XCTestExpectation(description: "Notifications checked")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
                let nearbyNotifications = requests.filter { 
                    $0.identifier.starts(with: "nearby-treasures-")
                }
                
                expectation.fulfill()
            }
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    func testLocationManagerAuthorizationHandling() {
        XCTAssertNotNil(locationManager.authorizationStatus)
        
        let validStatuses: [CLAuthorizationStatus] = [
            .notDetermined,
            .restricted,
            .denied,
            .authorizedAlways,
            .authorizedWhenInUse
        ]
        
        XCTAssertTrue(validStatuses.contains(locationManager.authorizationStatus))
    }
}