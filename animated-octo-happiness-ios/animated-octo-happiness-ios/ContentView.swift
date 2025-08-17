//
//  ContentView.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/16/25.
//

import SwiftUI
import CoreLocation

struct ContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var showingLocationSettings = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.blue)
                    
                    Text("AR Treasure Hunt")
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                LocationStatusView(
                    authorizationStatus: locationManager.authorizationStatus,
                    isLocationServicesEnabled: locationManager.isLocationServicesEnabled
                )
                
                if let location = locationManager.location {
                    LocationDetailsView(location: location)
                } else {
                    Text("No location available")
                        .foregroundColor(.secondary)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                }
                
                if let error = locationManager.locationError {
                    ErrorView(error: error) {
                        if error == .denied || error == .locationServicesDisabled {
                            showingLocationSettings = true
                        }
                    }
                }
                
                Spacer()
                
                LocationActionButtons(locationManager: locationManager)
            }
            .padding()
            .navigationTitle("Location Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showingLocationSettings) {
                SettingsPromptView()
            }
        }
    }
}

#Preview {
    ContentView()
}
