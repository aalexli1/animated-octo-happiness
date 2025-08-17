//
//  FriendListView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct FriendListView: View {
    @StateObject private var friendService = FriendService()
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddFriend = false
    @State private var showingRequests = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            VStack {
                Picker("View", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Requests").tag(1)
                    Text("Blocked").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedTab {
                case 0:
                    friendsList
                case 1:
                    requestsList
                case 2:
                    blockedList
                default:
                    friendsList
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddFriend = true
                    }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(friendService: friendService)
            }
            .onAppear {
                friendService.setModelContext(modelContext)
            }
        }
    }
    
    private var friendsList: some View {
        Group {
            if friendService.friends.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No friends yet")
                        .font(.title2)
                        .foregroundColor(.gray)
                    Text("Add friends to share treasures and compete!")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(friendService.friends, id: \.id) { friend in
                        FriendRowView(friend: friend, friendService: friendService)
                    }
                }
            }
        }
    }
    
    private var requestsList: some View {
        Group {
            if friendService.friendRequests.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No pending requests")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(friendService.friendRequests, id: \.id) { request in
                        FriendRequestRowView(request: request, friendService: friendService)
                    }
                }
            }
        }
    }
    
    private var blockedList: some View {
        Group {
            if friendService.blockedUsers.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "person.fill.xmark")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text("No blocked users")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(friendService.blockedUsers, id: \.id) { user in
                        BlockedUserRowView(user: user, friendService: friendService)
                    }
                }
            }
        }
    }
}

struct FriendRowView: View {
    let friend: User
    let friendService: FriendService
    @State private var showingOptions = false
    
    var body: some View {
        HStack {
            Text(friend.avatarEmoji)
                .font(.largeTitle)
            
            VStack(alignment: .leading) {
                Text(friend.displayName)
                    .font(.headline)
                Text("@\(friend.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                showingOptions = true
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .confirmationDialog("Friend Options", isPresented: $showingOptions) {
            Button("Remove Friend", role: .destructive) {
                try? friendService.removeFriend(friend)
            }
            Button("Block User", role: .destructive) {
                try? friendService.blockUser(friend)
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

struct FriendRequestRowView: View {
    let request: FriendRequest
    let friendService: FriendService
    
    var isIncoming: Bool {
        request.toUser?.id == friendService.currentUser?.id
    }
    
    var displayUser: User? {
        isIncoming ? request.fromUser : request.toUser
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                if let user = displayUser {
                    Text(user.avatarEmoji)
                        .font(.largeTitle)
                    
                    VStack(alignment: .leading) {
                        Text(user.displayName)
                            .font(.headline)
                        Text("@\(user.username)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isIncoming {
                        HStack(spacing: 12) {
                            Button(action: {
                                try? friendService.acceptFriendRequest(request)
                            }) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.title2)
                            }
                            
                            Button(action: {
                                try? friendService.declineFriendRequest(request)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.title2)
                            }
                        }
                    } else {
                        Button(action: {
                            try? friendService.cancelFriendRequest(request)
                        }) {
                            Text("Cancel")
                                .foregroundColor(.red)
                                .font(.caption)
                        }
                    }
                }
            }
            
            if let message = request.message, !message.isEmpty {
                Text(message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
            
            Text(isIncoming ? "Received" : "Sent")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct BlockedUserRowView: View {
    let user: User
    let friendService: FriendService
    
    var body: some View {
        HStack {
            Text(user.avatarEmoji)
                .font(.largeTitle)
                .opacity(0.5)
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.headline)
                    .opacity(0.5)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(0.5)
            }
            
            Spacer()
            
            Button(action: {
                try? friendService.unblockUser(user)
            }) {
                Text("Unblock")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddFriendView: View {
    let friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    
    @State private var username = ""
    @State private var message = ""
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Find Friend")) {
                    TextField("Username", text: $username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }
                
                Section(header: Text("Optional Message")) {
                    TextEditor(text: $message)
                        .frame(height: 100)
                }
                
                Section {
                    Button(action: sendFriendRequest) {
                        Text("Send Friend Request")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .listRowBackground(Color.blue)
                    .disabled(username.isEmpty)
                }
            }
            .navigationTitle("Add Friend")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .alert("Error", isPresented: $showingError) {
                Button("OK") {}
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func sendFriendRequest() {
        do {
            try friendService.sendFriendRequest(to: username, message: message.isEmpty ? nil : message)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    FriendListView()
        .modelContainer(for: [User.self, FriendRequest.self, Treasure.self], inMemory: true)
}