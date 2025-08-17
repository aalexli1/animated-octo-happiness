//
//  ContentView.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/16/25.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    @StateObject private var treasureStore = TreasureStore()
    @StateObject private var locationManager = LocationManager()
    @State private var showingCreationView = false
    @State private var selectedTreasure: Treasure?
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                Map(coordinateRegion: $region, 
                    showsUserLocation: true,
                    annotationItems: treasureStore.treasures) { treasure in
                    MapAnnotation(coordinate: treasure.coordinate) {
                        Button {
                            selectedTreasure = treasure
                        } label: {
                            VStack {
                                Text(treasure.emoji)
                                    .font(.title2)
                                    .padding(6)
                                    .background(Circle().fill(Color.white))
                                    .shadow(radius: 2)
                                
                                Image(systemName: "triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.white)
                                    .rotationEffect(.degrees(180))
                                    .offset(y: -3)
                            }
                        }
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    HStack {
                        Spacer()
                        
                        Button {
                            showingCreationView = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title2)
                                .foregroundColor(.white)
                                .frame(width: 60, height: 60)
                                .background(Circle().fill(Color.blue))
                                .shadow(radius: 4)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Treasure Hunt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Label("Treasures: \(treasureStore.treasures.count)", 
                          systemImage: "mappin.and.ellipse")
                        .labelStyle(.titleAndIcon)
                        .font(.caption)
                }
            }
        }
        .sheet(isPresented: $showingCreationView) {
            TreasureCreationView { treasure in
                Task {
                    try? await treasureStore.addTreasure(treasure)
                }
            }
        }
        .sheet(item: $selectedTreasure) { treasure in
            TreasureDetailView(treasure: treasure, treasureStore: treasureStore)
        }
        .onAppear {
            locationManager.requestLocationPermission()
        }
        .onChange(of: locationManager.location) { _, newLocation in
            if let location = newLocation {
                withAnimation {
                    region.center = location.coordinate
                }
            }
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.last
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}

#Preview {
    ContentView()
}
