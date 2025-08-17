//
//  LocationViews.swift
//  animated-octo-happiness-ios
//
//  UI components for location tracking display
//

import SwiftUI
import CoreLocation

struct LocationStatusView: View {
    let authorizationStatus: CLAuthorizationStatus
    let isLocationServicesEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Permission Status:")
                    .fontWeight(.medium)
                Spacer()
                Text(statusText)
                    .foregroundColor(statusColor)
            }
            
            HStack {
                Text("Location Services:")
                    .fontWeight(.medium)
                Spacer()
                Text(isLocationServicesEnabled ? "Enabled" : "Disabled")
                    .foregroundColor(isLocationServicesEnabled ? .green : .red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var statusText: String {
        switch authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always Authorized"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
    
    private var statusColor: Color {
        switch authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse: return .green
        case .denied, .restricted: return .red
        case .notDetermined: return .orange
        @unknown default: return .gray
        }
    }
}

struct LocationDetailsView: View {
    let location: CLLocation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Location")
                .font(.headline)
            
            LocationRow(title: "Latitude", value: String(format: "%.6f", location.coordinate.latitude))
            LocationRow(title: "Longitude", value: String(format: "%.6f", location.coordinate.longitude))
            LocationRow(title: "Accuracy", value: String(format: "%.1f m", location.horizontalAccuracy))
            LocationRow(title: "Altitude", value: String(format: "%.1f m", location.altitude))
            
            if location.speed >= 0 {
                LocationRow(title: "Speed", value: String(format: "%.1f m/s", location.speed))
            }
            
            LocationRow(title: "Timestamp", value: DateFormatter.localizedString(from: location.timestamp, dateStyle: .none, timeStyle: .medium))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

struct LocationRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .fontWeight(.medium)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

struct ErrorView: View {
    let error: LocationManager.LocationError
    let onSettingsTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                Text(error.localizedDescription ?? "Unknown error")
                    .foregroundColor(.primary)
                Spacer()
            }
            
            if error == .denied || error == .locationServicesDisabled {
                Button("Open Settings", action: onSettingsTap)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color(.systemYellow).opacity(0.1))
        .cornerRadius(10)
    }
}

struct LocationActionButtons: View {
    @ObservedObject var locationManager: LocationManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                Button("Request Permission") {
                    locationManager.requestLocationPermission()
                }
                .buttonStyle(.borderedProminent)
                .disabled(locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways)
                
                Button("Get Location") {
                    locationManager.requestOneTimeLocation()
                }
                .buttonStyle(.bordered)
                .disabled(locationManager.authorizationStatus != .authorizedWhenInUse && locationManager.authorizationStatus != .authorizedAlways)
            }
            
            HStack(spacing: 16) {
                Button("Start Tracking") {
                    locationManager.startUpdatingLocation()
                }
                .buttonStyle(.bordered)
                .disabled(locationManager.authorizationStatus != .authorizedWhenInUse && locationManager.authorizationStatus != .authorizedAlways)
                
                Button("Stop Tracking") {
                    locationManager.stopUpdatingLocation()
                }
                .buttonStyle(.bordered)
            }
        }
    }
}

struct SettingsPromptView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "gear")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Location Settings Required")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("To use location features, please enable location access in Settings.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                Button("Open Settings") {
                    if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsURL)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}