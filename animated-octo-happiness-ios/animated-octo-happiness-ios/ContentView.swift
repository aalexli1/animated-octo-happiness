//
//  ContentView.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/16/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var locationManager = LocationManager()
    @StateObject private var authService = AuthenticationService()
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Group {
            switch authService.authState {
            case .unauthenticated:
                LoginView()
                    .environmentObject(authService)
            case .authenticating:
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .authenticated, .anonymous:
                AuthenticatedContentView(selectedTab: $selectedTab)
                    .environmentObject(locationManager)
                    .environmentObject(authService)
            }
        }
        .onAppear {
            authService.setModelContext(modelContext)
            locationManager.requestLocationPermission()
        }
    }
}

struct AuthenticatedContentView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        TabView(selection: $selectedTab) {
            MapView()
                .ignoresSafeArea()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }
                .tag(0)
            
            ARTreasureHuntView()
                .tabItem {
                    Label("AR Hunt", systemImage: "camera.viewfinder")
                }
                .tag(1)
            
            CollectionView()
                .tabItem {
                    Label("Collection", systemImage: "star.fill")
                }
                .tag(2)
            
            TreasureListView()
                .tabItem {
                    Label("Treasures", systemImage: "list.bullet")
                }
                .tag(3)
            
            UserProfileView(authService: authService)
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Treasure.self, inMemory: true)
}