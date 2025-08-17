//
//  TreasureSharingView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct TreasureSharingView: View {
    let treasure: Treasure
    @ObservedObject var friendService: FriendService
    @ObservedObject var groupService: GroupService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPrivacy: PrivacyLevel
    @State private var selectedFriends: Set<UUID> = []
    @State private var selectedGroup: HuntingGroup?
    @State private var showingError = false
    @State private var errorMessage = ""
    
    init(treasure: Treasure, friendService: FriendService, groupService: GroupService) {
        self.treasure = treasure
        self.friendService = friendService
        self.groupService = groupService
        self._selectedPrivacy = State(initialValue: treasure.privacyLevel)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Privacy Level") {
                    Picker("Who can see this treasure?", selection: $selectedPrivacy) {
                        ForEach(PrivacyLevel.allCases, id: \.self) { level in
                            Label(level.displayName, systemImage: level.icon)
                                .tag(level)
                        }
                    }
                    .pickerStyle(.inline)
                    
                    Text(selectedPrivacy.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if selectedPrivacy == .friendsOnly {
                    Section("Share with Friends") {
                        if friendService.friends.isEmpty {
                            Text("No friends to share with")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(friendService.friends) { friend in
                                HStack {
                                    Text(friend.avatarEmoji)
                                        .font(.title2)
                                        .frame(width: 40, height: 40)
                                        .background(Color.gray.opacity(0.2))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading) {
                                        Text(friend.displayName)
                                            .font(.headline)
                                        Text("@\(friend.username)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedFriends.contains(friend.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedFriends.contains(friend.id) {
                                        selectedFriends.remove(friend.id)
                                    } else {
                                        selectedFriends.insert(friend.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                if selectedPrivacy == .groupOnly {
                    Section("Share with Group") {
                        let allGroups = groupService.myGroups + groupService.joinedGroups
                        if allGroups.isEmpty {
                            Text("No groups to share with")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(allGroups) { group in
                                HStack {
                                    Text(group.emoji)
                                        .font(.title2)
                                        .frame(width: 40, height: 40)
                                        .background(Color.blue.opacity(0.2))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading) {
                                        Text(group.name)
                                            .font(.headline)
                                        Text("\(group.memberCount) members")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedGroup?.id == group.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    selectedGroup = group
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Text("Current Privacy: \(treasure.privacyLevel.displayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let sharedWithUsers = treasure.sharedWithUsers, !sharedWithUsers.isEmpty {
                        VStack(alignment: .leading) {
                            Text("Currently shared with:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            ForEach(sharedWithUsers) { user in
                                Text("• \(user.displayName)")
                                    .font(.caption)
                            }
                        }
                    }
                    
                    if let sharedGroup = treasure.sharedWithGroup {
                        Text("Shared with group: \(sharedGroup.name)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Share Treasure")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveSharingSettings()
                    }
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func saveSharingSettings() {
        treasure.privacyLevel = selectedPrivacy
        
        switch selectedPrivacy {
        case .publicAccess, .privateAccess:
            treasure.sharedWithUsers = nil
            treasure.sharedWithGroup = nil
            
        case .friendsOnly:
            let selectedFriendsList = friendService.friends.filter { selectedFriends.contains($0.id) }
            treasure.shareWith(users: selectedFriendsList)
            treasure.sharedWithGroup = nil
            
            for friend in selectedFriendsList {
                let activity = ActivityFeedItem(
                    type: .treasureShared,
                    title: "Treasure Shared",
                    message: "\(friendService.currentUser?.displayName ?? "Someone") shared '\(treasure.title)' with you",
                    user: friend,
                    relatedUser: friendService.currentUser,
                    relatedTreasure: treasure
                )
                modelContext.insert(activity)
            }
            
        case .groupOnly:
            if let group = selectedGroup {
                treasure.shareWithGroup(group)
                treasure.sharedWithUsers = nil
                
                Task {
                    try? await groupService.shareWithGroup(treasure, group: group)
                }
            }
        }
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            errorMessage = "Failed to save sharing settings: \(error.localizedDescription)"
            showingError = true
        }
    }
}

struct TreasurePrivacyBadge: View {
    let privacyLevel: PrivacyLevel
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: privacyLevel.icon)
                .font(.caption)
            Text(privacyLevel.displayName)
                .font(.caption)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundColor)
        .foregroundColor(foregroundColor)
        .cornerRadius(8)
    }
    
    private var backgroundColor: Color {
        switch privacyLevel {
        case .publicAccess: return .green.opacity(0.2)
        case .friendsOnly: return .blue.opacity(0.2)
        case .groupOnly: return .purple.opacity(0.2)
        case .privateAccess: return .gray.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        switch privacyLevel {
        case .publicAccess: return .green
        case .friendsOnly: return .blue
        case .groupOnly: return .purple
        case .privateAccess: return .gray
        }
    }
}

#Preview {
    TreasureSharingView(
        treasure: Treasure.preview,
        friendService: FriendService(),
        groupService: GroupService()
    )
    .modelContainer(for: [Treasure.self, User.self, HuntingGroup.self])
}