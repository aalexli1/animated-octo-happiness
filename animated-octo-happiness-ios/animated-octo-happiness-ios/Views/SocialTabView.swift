//
//  SocialTabView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct SocialTabView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ActivityFeedView()
                .tabItem {
                    Label("Activity", systemImage: "bell.fill")
                }
                .tag(0)
                .badge(getUnreadActivityCount())
            
            FriendListView()
                .tabItem {
                    Label("Friends", systemImage: "person.2.fill")
                }
                .tag(1)
                .badge(getPendingRequestsCount())
            
            GroupListView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }
                .tag(2)
        }
    }
    
    func getUnreadActivityCount() -> Int {
        0
    }
    
    func getPendingRequestsCount() -> Int {
        0
    }
}

#Preview {
    SocialTabView()
        .modelContainer(for: [
            User.self,
            FriendRequest.self,
            TreasureGroup.self,
            ActivityFeedItem.self,
            Treasure.self
        ], inMemory: true)
}