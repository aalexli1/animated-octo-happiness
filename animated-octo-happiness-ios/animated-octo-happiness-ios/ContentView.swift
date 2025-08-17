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
    @StateObject private var friendService = FriendService()
    @StateObject private var groupService = GroupService()
    @Environment(\.modelContext) private var modelContext
    
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
            
            SocialHubView()
                .tabItem {
                    Label("Social", systemImage: "person.2.fill")
                }
                .tag(3)
                .badge(friendService.pendingRequests.count)
            
            TreasureHuntView()
                .tabItem {
                    Label("Hunt", systemImage: "location.viewfinder")
                }
                .tag(4)
        }
        .environmentObject(locationManager)
        .environmentObject(friendService)
        .environmentObject(groupService)
        .onAppear {
            locationManager.requestLocationPermission()
            setupDemoUser()
        }
    }
    
    private func setupDemoUser() {
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.username == "demo_user"
            }
        )
        
        if let existingUser = try? modelContext.fetch(descriptor).first {
            friendService.currentUser = existingUser
            groupService.setCurrentUser(existingUser)
        } else {
            let demoUser = User(
                username: "demo_user",
                displayName: "Demo User",
                avatarEmoji: "🎮"
            )
            modelContext.insert(demoUser)
            try? modelContext.save()
            
            friendService.currentUser = demoUser
            groupService.setCurrentUser(demoUser)
        }
        
        friendService.setModelContext(modelContext)
        groupService.setModelContext(modelContext)
    }
}

struct SocialHubView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Social", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Groups").tag(1)
                    Text("Activity").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedTab {
                case 0:
                    FriendsListView()
                case 1:
                    GroupsView()
                case 2:
                    ActivityFeedView()
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Social Hub")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [
            Treasure.self,
            User.self,
            FriendRelationship.self,
            FriendRequest.self,
            HuntingGroup.self,
            ActivityFeedItem.self
        ], inMemory: true)
}