//
//  GroupListView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct GroupListView: View {
    @StateObject private var groupService = GroupService()
    @StateObject private var friendService = FriendService()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingCreateGroup = false
    
    var body: some View {
        NavigationView {
            Group {
                if groupService.userGroups.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No groups yet")
                            .font(.title2)
                            .foregroundColor(.gray)
                        Text("Create or join a group to share treasures with your team!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button(action: {
                            showingCreateGroup = true
                        }) {
                            Label("Create Group", systemImage: "plus.circle.fill")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    List {
                        ForEach(groupService.userGroups, id: \.id) { group in
                            NavigationLink(destination: GroupDetailView(group: group, groupService: groupService, friendService: friendService)) {
                                GroupRowView(group: group, isOwner: group.owner?.id == friendService.currentUser?.id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingCreateGroup = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(groupService: groupService, friendService: friendService)
            }
            .onAppear {
                friendService.setModelContext(modelContext)
                groupService.setModelContext(modelContext)
                groupService.setFriendService(friendService)
            }
        }
    }
}

struct GroupRowView: View {
    let group: TreasureGroup
    let isOwner: Bool
    
    var body: some View {
        HStack {
            Text(group.emoji)
                .font(.largeTitle)
            
            VStack(alignment: .leading) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                    if isOwner {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
                
                Text("\(group.members.count) member\(group.members.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct GroupDetailView: View {
    let group: TreasureGroup
    let groupService: GroupService
    let friendService: FriendService
    
    @State private var showingAddMember = false
    @State private var showingDeleteConfirmation = false
    @Environment(\.dismiss) private var dismiss
    
    var isOwner: Bool {
        group.owner?.id == friendService.currentUser?.id
    }
    
    var body: some View {
        List {
            Section(header: Text("Group Info")) {
                HStack {
                    Text("Name")
                    Spacer()
                    Text(group.name)
                        .foregroundColor(.secondary)
                }
                
                if let description = group.groupDescription {
                    HStack {
                        Text("Description")
                        Spacer()
                        Text(description)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                HStack {
                    Text("Created")
                    Spacer()
                    Text(group.createdAt, style: .date)
                        .foregroundColor(.secondary)
                }
            }
            
            Section(header: Text("Members (\(group.members.count))")) {
                ForEach(group.members, id: \.id) { member in
                    HStack {
                        Text(member.avatarEmoji)
                            .font(.title2)
                        
                        VStack(alignment: .leading) {
                            Text(member.displayName)
                                .font(.subheadline)
                            if member.id == group.owner?.id {
                                Text("Owner")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if isOwner && member.id != friendService.currentUser?.id {
                            Button(action: {
                                try? groupService.removeMemberFromGroup(member, group: group)
                            }) {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                
                if isOwner {
                    Button(action: {
                        showingAddMember = true
                    }) {
                        Label("Add Member", systemImage: "person.badge.plus")
                            .foregroundColor(.blue)
                    }
                }
            }
            
            Section(header: Text("Shared Treasures (\(group.sharedTreasures.count))")) {
                if group.sharedTreasures.isEmpty {
                    Text("No treasures shared yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(group.sharedTreasures, id: \.id) { treasure in
                        HStack {
                            Text(treasure.emoji ?? "🎁")
                            Text(treasure.title)
                            Spacer()
                        }
                    }
                }
            }
            
            Section {
                if isOwner {
                    Button(action: {
                        showingDeleteConfirmation = true
                    }) {
                        Text("Delete Group")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                } else {
                    Button(action: {
                        try? groupService.leaveGroup(group)
                        dismiss()
                    }) {
                        Text("Leave Group")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle(group.emoji + " " + group.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingAddMember) {
            AddGroupMemberView(group: group, groupService: groupService, friendService: friendService)
        }
        .confirmationDialog("Delete Group", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                try? groupService.deleteGroup(group)
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will permanently delete the group and remove all members.")
        }
    }
}

struct CreateGroupView: View {
    let groupService: GroupService
    let friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedEmoji = "👥"
    @State private var showingEmojiPicker = false
    
    let groupEmojis = ["👥", "⚔️", "🏴‍☠️", "🗺️", "💎", "🏆", "🎯", "🚀", "⭐", "🔥"]
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Group Details")) {
                    HStack {
                        Text("Icon")
                        Spacer()
                        Button(action: {
                            showingEmojiPicker = true
                        }) {
                            Text(selectedEmoji)
                                .font(.largeTitle)
                        }
                    }
                    
                    TextField("Group Name", text: $name)
                    
                    TextEditor(text: $description)
                        .frame(height: 100)
                        .placeholder(when: description.isEmpty) {
                            Text("Description (optional)")
                                .foregroundColor(.secondary)
                        }
                }
                
                Section {
                    Button(action: createGroup) {
                        Text("Create Group")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(name.isEmpty)
                }
            }
            .navigationTitle("New Group")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $selectedEmoji, emojis: groupEmojis)
            }
        }
    }
    
    private func createGroup() {
        do {
            _ = try groupService.createGroup(
                name: name,
                description: description.isEmpty ? nil : description,
                emoji: selectedEmoji
            )
            dismiss()
        } catch {
            print("Error creating group: \(error)")
        }
    }
}

struct AddGroupMemberView: View {
    let group: TreasureGroup
    let groupService: GroupService
    let friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    
    var availableFriends: [User] {
        friendService.friends.filter { friend in
            !group.members.contains { member in
                member.id == friend.id
            }
        }
    }
    
    var body: some View {
        NavigationView {
            List {
                if availableFriends.isEmpty {
                    Text("No friends to add")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    ForEach(availableFriends, id: \.id) { friend in
                        Button(action: {
                            try? groupService.addMemberToGroup(friend, group: group)
                            dismiss()
                        }) {
                            HStack {
                                Text(friend.avatarEmoji)
                                    .font(.title2)
                                
                                VStack(alignment: .leading) {
                                    Text(friend.displayName)
                                        .foregroundColor(.primary)
                                    Text("@\(friend.username)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "plus.circle")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add Member")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    let emojis: [String]
    @Environment(\.dismiss) private var dismiss
    
    let columns = [
        GridItem(.adaptive(minimum: 60))
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(emojis, id: \.self) { emoji in
                        Button(action: {
                            selectedEmoji = emoji
                            dismiss()
                        }) {
                            Text(emoji)
                                .font(.system(size: 40))
                                .frame(width: 60, height: 60)
                                .background(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.gray.opacity(0.1))
                                .cornerRadius(10)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Icon")
            .navigationBarItems(
                trailing: Button("Done") {
                    dismiss()
                }
            )
        }
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {
        
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

#Preview {
    GroupListView()
        .modelContainer(for: [User.self, TreasureGroup.self, Treasure.self], inMemory: true)
}