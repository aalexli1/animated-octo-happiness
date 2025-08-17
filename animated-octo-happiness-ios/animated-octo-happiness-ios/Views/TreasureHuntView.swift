//
//  TreasureHuntView.swift
//  animated-octo-happiness-ios
//
//  Created by Claude on 8/17/25.
//

import SwiftUI
import CoreLocation

struct TreasureHuntView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var treasures = Treasure.sampleTreasures
    @State private var foundTreasures = Set<UUID>()
    @State private var showingAR = false
    @State private var showingPermissionAlert = false
    @State private var showingCompletionAlert = false
    
    var body: some View {
        ZStack {
            if showingAR {
                ARTreasureView(
                    treasures: getNearbyTreasures(),
                    locationManager: locationManager,
                    foundTreasures: $foundTreasures
                )
                .ignoresSafeArea()
                .overlay(alignment: .topLeading) {
                    Button(action: {
                        showingAR = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.black.opacity(0.5)))
                    }
                    .padding()
                }
                .overlay(alignment: .top) {
                    VStack {
                        Text("AR Treasure Hunt")
                            .font(.title2)
                            .bold()
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color.black.opacity(0.7))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        
                        if let nearbyCount = getNearbyTreasures().count, nearbyCount > 0 {
                            Text("\(nearbyCount) treasure\(nearbyCount == 1 ? "" : "s") nearby")
                                .font(.subheadline)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                                .padding(.vertical, 4)
                                .background(Color.blue.opacity(0.7))
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.top, 50)
                }
            } else {
                MapTreasureView(
                    treasures: treasures,
                    locationManager: locationManager,
                    foundTreasures: $foundTreasures,
                    showingAR: $showingAR
                )
            }
        }
        .onAppear {
            checkLocationPermission()
        }
        .onChange(of: foundTreasures) { _ in
            if foundTreasures.count == treasures.count {
                showingCompletionAlert = true
            }
        }
        .alert("Location Permission Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Please enable location access in Settings to discover treasures.")
        }
        .alert("Congratulations!", isPresented: $showingCompletionAlert) {
            Button("Play Again") {
                resetGame()
            }
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've found all \(treasures.count) treasures! Great job!")
        }
    }
    
    private func getNearbyTreasures() -> [Treasure] {
        locationManager.getNearbyTreasures(treasures.filter { !foundTreasures.contains($0.id) })
    }
    
    private func checkLocationPermission() {
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestLocationPermission()
        case .denied, .restricted:
            showingPermissionAlert = true
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            break
        }
    }
    
    private func resetGame() {
        foundTreasures.removeAll()
        treasures = Treasure.sampleTreasures.shuffled()
    }
}