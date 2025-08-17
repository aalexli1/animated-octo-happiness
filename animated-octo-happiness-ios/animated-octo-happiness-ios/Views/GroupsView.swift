//
//  GroupsView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct GroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var groupService = GroupService()
    @State private var showingCreateGroup = false
    @State private var showingJoinGroup = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            List {
                if !groupService.myGroups.isEmpty {
                    Section("My Groups") {
                        ForEach(groupService.myGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group, groupService: groupService)) {
                                GroupRowView(group: group, isOwner: true)
                            }
                        }
                    }
                }
                
                if !groupService.joinedGroups.isEmpty {
                    Section("Joined Groups") {
                        ForEach(groupService.joinedGroups) { group in
                            NavigationLink(destination: GroupDetailView(group: group, groupService: groupService)) {
                                GroupRowView(group: group, isOwner: false)
                            }
                        }
                    }
                }
            }
            .overlay {
                if groupService.myGroups.isEmpty && groupService.joinedGroups.isEmpty {
                    ContentUnavailableView(
                        "No Groups Yet",
                        systemImage: "person.3",
                        description: Text("Create or join a group to hunt treasures together!")
                    )
                }
            }
            .navigationTitle("Groups")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingCreateGroup = true }) {
                            Label("Create Group", systemImage: "plus.circle")
                        }
                        Button(action: { showingJoinGroup = true }) {
                            Label("Join Group", systemImage: "arrow.right.circle")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView(groupService: groupService)
            }
            .sheet(isPresented: $showingJoinGroup) {
                JoinGroupView(groupService: groupService)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                groupService.setModelContext(modelContext)
            }
        }
    }
}

struct GroupRowView: View {
    let group: HuntingGroup
    let isOwner: Bool
    
    var body: some View {
        HStack {
            Text(group.emoji)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .background(Color.blue.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                HStack {
                    Text(group.name)
                        .font(.headline)
                    if isOwner {
                        Image(systemName: "crown.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                }
                
                Text("\(group.memberCount)/\(group.maxMembers) members")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if let treasureCount = group.sharedTreasures?.count, treasureCount > 0 {
                VStack {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                    Text("\(treasureCount)")
                        .font(.caption2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct GroupDetailView: View {
    let group: HuntingGroup
    @ObservedObject var groupService: GroupService
    @Environment(\.dismiss) private var dismiss
    @State private var showingInviteCode = false
    @State private var showingDeleteConfirmation = false
    @State private var showingLeaveConfirmation = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private var isOwner: Bool {
        group.owner?.id == groupService.currentUser?.id
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text(group.emoji)
                        .font(.largeTitle)
                        .frame(width: 60, height: 60)
                        .background(Color.blue.opacity(0.2))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(group.name)
                            .font(.title2)
                            .bold()
                        if let description = group.groupDescription {
                            Text(description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
                
                if isOwner {
                    Button(action: { showingInviteCode = true }) {
                        Label("Show Invite Code", systemImage: "link")
                    }
                }
            }
            
            Section("Members (\(group.memberCount)/\(group.maxMembers))") {
                ForEach(group.members ?? []) { member in
                    HStack {
                        Text(member.avatarEmoji)
                            .font(.title2)
                            .frame(width: 40, height: 40)
                            .background(Color.gray.opacity(0.2))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            HStack {
                                Text(member.displayName)
                                    .font(.headline)
                                if member.id == group.owner?.id {
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.yellow)
                                        .font(.caption)
                                }
                            }
                            Text("@\(member.username)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        if isOwner && member.id != group.owner?.id {
                            Button(role: .destructive) {
                                Task {
                                    do {
                                        try await groupService.removeMember(member, from: group)
                                    } catch {
                                        errorMessage = error.localizedDescription
                                        showingError = true
                                    }
                                }
                            } label: {
                                Label("Remove", systemImage: "person.badge.minus")
                            }
                        }
                    }
                }
            }
            
            if let treasures = group.sharedTreasures, !treasures.isEmpty {
                Section("Shared Treasures") {
                    ForEach(treasures) { treasure in
                        HStack {
                            Text(treasure.emoji ?? "🎁")
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(treasure.title)
                                    .font(.headline)
                                Text(treasure.treasureDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            
                            Spacer()
                            
                            if treasure.isCollected {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            }
                        }
                    }
                }
            }
            
            Section {
                if isOwner {
                    Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                        Label("Delete Group", systemImage: "trash")
                    }
                } else {
                    Button(role: .destructive, action: { showingLeaveConfirmation = true }) {
                        Label("Leave Group", systemImage: "arrow.left.circle")
                    }
                }
            }
        }
        .navigationTitle(group.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingInviteCode) {
            InviteCodeView(group: group, groupService: groupService)
        }
        .alert("Delete Group", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                Task {
                    do {
                        try await groupService.deleteGroup(group)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this group? This action cannot be undone.")
        }
        .alert("Leave Group", isPresented: $showingLeaveConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Leave", role: .destructive) {
                Task {
                    do {
                        try await groupService.leaveGroup(group)
                        dismiss()
                    } catch {
                        errorMessage = error.localizedDescription
                        showingError = true
                    }
                }
            }
        } message: {
            Text("Are you sure you want to leave this group?")
        }
        .alert("Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct CreateGroupView: View {
    @ObservedObject var groupService: GroupService
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var groupDescription = ""
    @State private var selectedEmoji = "👥"
    @State private var maxMembers = 20
    @State private var showingError = false
    @State private var errorMessage = ""
    
    let emojiOptions = ["👥", "🏕️", "🗺️", "🔍", "🎯", "🏃", "🚀", "💎", "🏆", "🎭"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Group Information") {
                    TextField("Group Name", text: $groupName)
                    TextField("Description (optional)", text: $groupDescription, axis: .vertical)
                        .lineLimit(3...5)
                }
                
                Section("Emoji") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(emojiOptions, id: \.self) { emoji in
                            Button(action: { selectedEmoji = emoji }) {
                                Text(emoji)
                                    .font(.largeTitle)
                                    .frame(width: 50, height: 50)
                                    .background(selectedEmoji == emoji ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                            }
                        }
                    }
                }
                
                Section("Settings") {
                    Stepper("Max Members: \(maxMembers)", value: $maxMembers, in: 2...50)
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            await createGroup()
                        }
                    }
                    .disabled(groupName.isEmpty)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func createGroup() async {
        do {
            _ = try await groupService.createGroup(
                name: groupName,
                description: groupDescription.isEmpty ? nil : groupDescription,
                emoji: selectedEmoji,
                maxMembers: maxMembers
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct JoinGroupView: View {
    @ObservedObject var groupService: GroupService
    @Environment(\.dismiss) private var dismiss
    @State private var inviteCode = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.3.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Join a Group")
                    .font(.title)
                    .bold()
                
                Text("Enter the 6-character invite code to join a group")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("ABCD12", text: $inviteCode)
                    .textFieldStyle(.roundedBorder)
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .textInputAutocapitalization(.characters)
                    .padding(.horizontal, 40)
                
                Button(action: {
                    Task {
                        await joinGroup()
                    }
                }) {
                    Text("Join Group")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(inviteCode.count != 6)
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
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
    
    private func joinGroup() async {
        do {
            _ = try await groupService.joinGroup(withCode: inviteCode.uppercased())
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct InviteCodeView: View {
    let group: HuntingGroup
    @ObservedObject var groupService: GroupService
    @Environment(\.dismiss) private var dismiss
    @State private var copiedToClipboard = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Image(systemName: "link.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Invite Code")
                    .font(.title)
                    .bold()
                
                Text(group.inviteCode)
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundColor(.blue)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(10)
                
                Text("Share this code with friends to invite them to your group")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    Button(action: {
                        UIPasteboard.general.string = group.inviteCode
                        copiedToClipboard = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            copiedToClipboard = false
                        }
                    }) {
                        Label(copiedToClipboard ? "Copied!" : "Copy Code", 
                              systemImage: copiedToClipboard ? "checkmark.circle" : "doc.on.doc")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: {
                        Task {
                            try? await groupService.regenerateInviteCode(for: group)
                        }
                    }) {
                        Label("Generate New Code", systemImage: "arrow.clockwise")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    GroupsView()
        .modelContainer(for: [HuntingGroup.self, User.self])
}