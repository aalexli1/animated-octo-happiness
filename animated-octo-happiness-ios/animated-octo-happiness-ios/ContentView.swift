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
            
            TreasureHuntView()
                .tabItem {
                    Label("Hunt", systemImage: "location.viewfinder")
                }
                .tag(4)
            
            SocialTabView()
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(5)
        }
        .environmentObject(locationManager)
        .onAppear {
            locationManager.requestLocationPermission()
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Treasure.self,
            User.self,
            FriendRequest.self,
            TreasureGroup.self,
            ActivityFeedItem.self
        ], inMemory: true)
}