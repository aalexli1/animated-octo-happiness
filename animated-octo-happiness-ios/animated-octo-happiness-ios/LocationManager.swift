//
//  LocationManager.swift
//  animated-octo-happiness-ios
//
//  Core Location service for AR Treasure Hunt
//

import CoreLocation
import SwiftUI
import Combine

@MainActor
class LocationManager: NSObject, ObservableObject {
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var locationError: LocationError?
    @Published var isLocationServicesEnabled: Bool = false
    
    private let locationManager = CLLocationManager()
    private var requestedAccuracy: CLLocationAccuracy = kCLLocationAccuracyBest
    
    enum LocationError: LocalizedError, Equatable {
        case denied
        case restricted
        case locationServicesDisabled
        case accuracyReduced
        case timeout
        case unknown(String)
        
        static func == (lhs: LocationError, rhs: LocationError) -> Bool {
            switch (lhs, rhs) {
            case (.denied, .denied),
                 (.restricted, .restricted),
                 (.locationServicesDisabled, .locationServicesDisabled),
                 (.accuracyReduced, .accuracyReduced),
                 (.timeout, .timeout):
                return true
            case (.unknown(let lhsError), .unknown(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
        
        var errorDescription: String? {
            switch self {
            case .denied:
                return "Location access denied. Please enable in Settings."
            case .restricted:
                return "Location access restricted by device policy."
            case .locationServicesDisabled:
                return "Location services disabled. Please enable in Settings."
            case .accuracyReduced:
                return "Location accuracy is reduced."
            case .timeout:
                return "Location request timed out."
            case .unknown(let errorString):
                return "Location error: \(errorString)"
            }
        }
    }
    
    override init() {
        super.init()
        setupLocationManager()
        checkLocationServicesStatus()
    }
    
    func requestLocationPermission() {
        guard CLLocationManager.locationServicesEnabled() else {
            locationError = .locationServicesDisabled
            return
        }
        
        switch authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = authorizationStatus == .denied ? .denied : .restricted
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        @unknown default:
            break
        }
    }
    
    func startLocationUpdates() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.startUpdatingLocation()
    }
    
    func stopLocationUpdates() {
        locationManager.stopUpdatingLocation()
    }
    
    func requestOneTimeLocation() {
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        
        locationManager.requestLocation()
    }
    
    func setLocationAccuracy(_ accuracy: CLLocationAccuracy) {
        requestedAccuracy = accuracy
        locationManager.desiredAccuracy = accuracy
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = requestedAccuracy
        locationManager.distanceFilter = 10
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func checkLocationServicesStatus() {
        isLocationServicesEnabled = CLLocationManager.locationServicesEnabled()
    }
    
    private func handleLocationError(_ error: Error) {
        if let clError = error as? CLError {
            switch clError.code {
            case .denied:
                locationError = .denied
            case .locationUnknown:
                locationError = .timeout
            case .network:
                locationError = .unknown(clError.localizedDescription)
            default:
                locationError = .unknown(clError.localizedDescription)
            }
        } else {
            locationError = .unknown(error.localizedDescription)
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        
        Task { @MainActor in
            locationError = nil
            location = newLocation
            
            if #available(iOS 14.0, *) {
                if manager.accuracyAuthorization == .reducedAccuracy {
                    locationError = .accuracyReduced
                }
            }
        }
    }
    
    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            handleLocationError(error)
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            authorizationStatus = manager.authorizationStatus
            
            switch authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationError = nil
                checkLocationServicesStatus()
            case .denied:
                locationError = .denied
                stopLocationUpdates()
            case .restricted:
                locationError = .restricted
                stopLocationUpdates()
            case .notDetermined:
                locationError = nil
            @unknown default:
                break
            }
        }
    }
}