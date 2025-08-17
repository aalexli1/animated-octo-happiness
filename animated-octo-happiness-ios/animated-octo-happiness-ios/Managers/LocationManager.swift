//
//  LocationManager.swift
//  animated-octo-happiness-ios
//
//  Created by Claude on 8/17/25.
//

import Foundation
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var heading: CLHeading?
    @Published var locationError: Error?
    
    private let locationManager = CLLocationManager()
    private let detectionRadius: CLLocationDistance = 100
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1
        locationManager.headingFilter = 1
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func distanceToTreasure(_ treasure: Treasure) -> CLLocationDistance? {
        guard let currentLocation = currentLocation else { return nil }
        let treasureLocation = CLLocation(
            latitude: treasure.coordinate.latitude,
            longitude: treasure.coordinate.longitude
        )
        return currentLocation.distance(from: treasureLocation)
    }
    
    func bearingToTreasure(_ treasure: Treasure) -> Double? {
        guard let currentLocation = currentLocation else { return nil }
        
        let lat1 = currentLocation.coordinate.latitude.toRadians()
        let lon1 = currentLocation.coordinate.longitude.toRadians()
        let lat2 = treasure.coordinate.latitude.toRadians()
        let lon2 = treasure.coordinate.longitude.toRadians()
        
        let dLon = lon2 - lon1
        let y = sin(dLon) * cos(lat2)
        let x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon)
        
        var bearing = atan2(y, x).toDegrees()
        bearing = (bearing + 360).truncatingRemainder(dividingBy: 360)
        
        return bearing
    }
    
    func getNearbyTreasures(_ treasures: [Treasure], radius: CLLocationDistance = 100) -> [Treasure] {
        treasures.filter { treasure in
            guard let distance = distanceToTreasure(treasure) else { return false }
            return distance <= radius
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error
    }
}

private extension Double {
    func toRadians() -> Double {
        self * .pi / 180
    }
    
    func toDegrees() -> Double {
        self * 180 / .pi
    }
}