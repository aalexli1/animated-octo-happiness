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
    @StateObject private var friendService = FriendService()
    @StateObject private var groupService = GroupService()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedPrivacy: TreasurePrivacy = .public
    @State private var selectedFriends: Set<UUID> = []
    @State private var selectedGroups: Set<UUID> = []
    @State private var showingSuccess = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Treasure")) {
                    HStack {
                        Text(treasure.emoji ?? "🎁")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text(treasure.title)
                                .font(.headline)
                            Text(treasure.treasureDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                    }
                }
                
                Section(header: Text("Privacy Settings")) {
                    Picker("Who can see this treasure?", selection: $selectedPrivacy) {
                        Text("Everyone").tag(TreasurePrivacy.public)
                        Text("Friends Only").tag(TreasurePrivacy.friends)
                        Text("Groups Only").tag(TreasurePrivacy.group)
                        Text("Private").tag(TreasurePrivacy.private)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                if selectedPrivacy == .friends {
                    Section(header: Text("Share with Friends")) {
                        if friendService.friends.isEmpty {
                            Text("No friends to share with")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(friendService.friends, id: \.id) { friend in
                                HStack {
                                    Text(friend.avatarEmoji)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading) {
                                        Text(friend.displayName)
                                        Text("@\(friend.username)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedFriends.contains(friend.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
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
                
                if selectedPrivacy == .group {
                    Section(header: Text("Share with Groups")) {
                        if groupService.userGroups.isEmpty {
                            Text("No groups to share with")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(groupService.userGroups, id: \.id) { group in
                                HStack {
                                    Text(group.emoji)
                                        .font(.title2)
                                    
                                    VStack(alignment: .leading) {
                                        Text(group.name)
                                        Text("\(group.members.count) members")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    if selectedGroups.contains(group.id) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                    }
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if selectedGroups.contains(group.id) {
                                        selectedGroups.remove(group.id)
                                    } else {
                                        selectedGroups.insert(group.id)
                                    }
                                }
                            }
                        }
                    }
                }
                
                Section {
                    Button(action: shareTreasure) {
                        Text("Update Sharing Settings")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                }
            }
            .navigationTitle("Share Treasure")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .onAppear {
                friendService.setModelContext(modelContext)
                groupService.setModelContext(modelContext)
                groupService.setFriendService(friendService)
                
                selectedPrivacy = treasure.privacy
                selectedFriends = Set(treasure.sharedWithUsers.map { $0.id })
                selectedGroups = Set(treasure.sharedWithGroups.map { $0.id })
            }
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Treasure sharing settings updated successfully!")
            }
        }
    }
    
    private func shareTreasure() {
        treasure.privacy = selectedPrivacy
        
        treasure.sharedWithUsers.removeAll()
        if selectedPrivacy == .friends {
            for friendId in selectedFriends {
                if let friend = friendService.friends.first(where: { $0.id == friendId }) {
                    treasure.shareWith(user: friend)
                    
                    if let currentUser = friendService.currentUser {
                        let activity = ActivityFeedItem.treasureShared(
                            by: currentUser,
                            treasure: treasure,
                            with: friend
                        )
                        modelContext.insert(activity)
                    }
                }
            }
        }
        
        treasure.sharedWithGroups.removeAll()
        if selectedPrivacy == .group {
            for groupId in selectedGroups {
                if let group = groupService.userGroups.first(where: { $0.id == groupId }) {
                    treasure.shareWith(group: group)
                    
                    if let currentUser = friendService.currentUser {
                        for member in group.members where member.id != currentUser.id {
                            let activity = ActivityFeedItem(
                                type: .treasureShared,
                                title: "Treasure shared with group",
                                message: "\(currentUser.displayName) shared '\(treasure.title)' with '\(group.name)'",
                                user: member,
                                relatedTreasure: treasure,
                                relatedUser: currentUser,
                                relatedGroup: group
                            )
                            modelContext.insert(activity)
                        }
                    }
                }
            }
        }
        
        do {
            try modelContext.save()
            showingSuccess = true
        } catch {
            print("Error saving treasure sharing settings: \(error)")
        }
    }
}

#Preview {
    TreasureSharingView(treasure: Treasure.preview)
        .modelContainer(for: [User.self, Treasure.self, TreasureGroup.self], inMemory: true)
}