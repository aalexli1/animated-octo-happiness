//
//  MapTreasureView.swift
//  animated-octo-happiness-ios
//
//  Created by Claude on 8/17/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapTreasureView: View {
    let treasures: [Treasure]
    @ObservedObject var locationManager: LocationManager
    @Binding var foundTreasures: Set<UUID>
    @Binding var showingAR: Bool
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
    )
    
    @State private var userTrackingMode: MapUserTrackingMode = .follow
    
    var body: some View {
        ZStack {
            Map(coordinateRegion: $region,
                showsUserLocation: true,
                userTrackingMode: $userTrackingMode,
                annotationItems: treasures.filter { !foundTreasures.contains($0.id) }) { treasure in
                MapAnnotation(coordinate: treasure.coordinate) {
                    TreasureAnnotation(treasure: treasure, distance: locationManager.distanceToTreasure(treasure))
                }
            }
            .ignoresSafeArea()
            
            VStack {
                HStack {
                    Text("Treasures Found: \(foundTreasures.count)/\(treasures.count)")
                        .font(.headline)
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding()
                    
                    Spacer()
                }
                
                Spacer()
                
                if let nearbyTreasures = getNearbyTreasures(), !nearbyTreasures.isEmpty {
                    VStack {
                        Text("Nearby Treasures")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(nearbyTreasures) { treasure in
                            HStack {
                                Image(systemName: treasure.symbolName)
                                    .foregroundColor(.yellow)
                                Text(treasure.name)
                                    .foregroundColor(.white)
                                Spacer()
                                if let distance = locationManager.distanceToTreasure(treasure) {
                                    Text("\(Int(distance))m")
                                        .foregroundColor(.gray)
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        Button(action: {
                            showingAR = true
                        }) {
                            Label("Open AR View", systemImage: "camera.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                    .padding()
                }
            }
        }
        .onAppear {
            updateRegionToUserLocation()
        }
        .onChange(of: locationManager.currentLocation) { _ in
            updateRegionToUserLocation()
        }
    }
    
    private func getNearbyTreasures() -> [Treasure]? {
        guard locationManager.currentLocation != nil else { return nil }
        return locationManager.getNearbyTreasures(treasures.filter { !foundTreasures.contains($0.id) })
    }
    
    private func updateRegionToUserLocation() {
        if let location = locationManager.currentLocation {
            withAnimation {
                region = MKCoordinateRegion(
                    center: location.coordinate,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
            }
        }
    }
}

struct TreasureAnnotation: View {
    let treasure: Treasure
    let distance: CLLocationDistance?
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: treasure.symbolName)
                .font(.title)
                .foregroundColor(.yellow)
                .padding(8)
                .background(Circle().fill(Color.black.opacity(0.7)))
                .overlay(
                    Circle()
                        .stroke(Color.yellow, lineWidth: 2)
                )
            
            if let distance = distance {
                Text("\(Int(distance))m")
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.black.opacity(0.7)))
                    .offset(y: -5)
            }
        }
    }
}