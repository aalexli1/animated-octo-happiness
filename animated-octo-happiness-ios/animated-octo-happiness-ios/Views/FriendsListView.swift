//
//  FriendsListView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct FriendsListView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var friendService = FriendService()
    @State private var selectedTab = 0
    @State private var searchText = ""
    @State private var showingAddFriend = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("Friends", selection: $selectedTab) {
                    Text("Friends").tag(0)
                    Text("Requests").tag(1)
                    Text("Blocked").tag(2)
                }
                .pickerStyle(.segmented)
                .padding()
                
                switch selectedTab {
                case 0:
                    friendsListContent
                case 1:
                    requestsListContent
                case 2:
                    blockedListContent
                default:
                    EmptyView()
                }
            }
            .navigationTitle("Friends")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddFriend = true }) {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search friends")
            .sheet(isPresented: $showingAddFriend) {
                AddFriendView(friendService: friendService)
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                friendService.setModelContext(modelContext)
            }
        }
    }
    
    private var friendsListContent: some View {
        Group {
            if friendService.friends.isEmpty {
                ContentUnavailableView(
                    "No Friends Yet",
                    systemImage: "person.2",
                    description: Text("Add friends to share treasures and compete together!")
                )
            } else {
                List {
                    ForEach(filteredFriends) { friend in
                        FriendRowView(friend: friend) {
                            Task {
                                do {
                                    try await friendService.removeFriend(friend)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var requestsListContent: some View {
        Group {
            if friendService.pendingRequests.isEmpty && friendService.sentRequests.isEmpty {
                ContentUnavailableView(
                    "No Pending Requests",
                    systemImage: "envelope",
                    description: Text("Friend requests will appear here")
                )
            } else {
                List {
                    if !friendService.pendingRequests.isEmpty {
                        Section("Received Requests") {
                            ForEach(friendService.pendingRequests) { request in
                                FriendRequestRowView(
                                    request: request,
                                    isReceived: true,
                                    onAccept: {
                                        Task {
                                            do {
                                                try await friendService.acceptFriendRequest(request)
                                            } catch {
                                                errorMessage = error.localizedDescription
                                                showingError = true
                                            }
                                        }
                                    },
                                    onDecline: {
                                        Task {
                                            do {
                                                try await friendService.declineFriendRequest(request)
                                            } catch {
                                                errorMessage = error.localizedDescription
                                                showingError = true
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                    
                    if !friendService.sentRequests.isEmpty {
                        Section("Sent Requests") {
                            ForEach(friendService.sentRequests) { request in
                                FriendRequestRowView(
                                    request: request,
                                    isReceived: false,
                                    onCancel: {
                                        Task {
                                            do {
                                                try await friendService.cancelFriendRequest(request)
                                            } catch {
                                                errorMessage = error.localizedDescription
                                                showingError = true
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var blockedListContent: some View {
        Group {
            if friendService.blockedUsers.isEmpty {
                ContentUnavailableView(
                    "No Blocked Users",
                    systemImage: "person.fill.xmark",
                    description: Text("Blocked users will appear here")
                )
            } else {
                List {
                    ForEach(friendService.blockedUsers) { user in
                        BlockedUserRowView(user: user) {
                            Task {
                                do {
                                    try await friendService.unblockUser(user)
                                } catch {
                                    errorMessage = error.localizedDescription
                                    showingError = true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var filteredFriends: [User] {
        if searchText.isEmpty {
            return friendService.friends
        } else {
            return friendService.friends.filter { friend in
                friend.displayName.localizedCaseInsensitiveContains(searchText) ||
                friend.username.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
}

struct FriendRowView: View {
    let friend: User
    let onRemove: () -> Void
    
    var body: some View {
        HStack {
            Text(friend.avatarEmoji)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
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
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive, action: onRemove) {
                Label("Remove", systemImage: "person.badge.minus")
            }
        }
    }
}

struct FriendRequestRowView: View {
    let request: FriendRequest
    let isReceived: Bool
    var onAccept: (() -> Void)?
    var onDecline: (() -> Void)?
    var onCancel: (() -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                let user = isReceived ? request.sender : request.receiver
                Text(user?.avatarEmoji ?? "🧑")
                    .font(.largeTitle)
                    .frame(width: 50, height: 50)
                    .background(Color.gray.opacity(0.2))
                    .clipShape(Circle())
                
                VStack(alignment: .leading) {
                    Text(user?.displayName ?? "Unknown")
                        .font(.headline)
                    Text("@\(user?.username ?? "unknown")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text(request.sentAt, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let message = request.message {
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
            
            if isReceived {
                HStack {
                    Button(action: { onAccept?() }) {
                        Label("Accept", systemImage: "checkmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button(action: { onDecline?() }) {
                        Label("Decline", systemImage: "xmark")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Button(action: { onCancel?() }) {
                    Label("Cancel Request", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 4)
    }
}

struct BlockedUserRowView: View {
    let user: User
    let onUnblock: () -> Void
    
    var body: some View {
        HStack {
            Text(user.avatarEmoji)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .background(Color.gray.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(user.displayName)
                    .font(.headline)
                Text("@\(user.username)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Unblock", action: onUnblock)
                .buttonStyle(.bordered)
        }
    }
}

struct AddFriendView: View {
    @ObservedObject var friendService: FriendService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchResults: [User] = []
    @State private var selectedUser: User?
    @State private var message = ""
    @State private var isSearching = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                TextField("Search by username or display name", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                    .onSubmit {
                        Task {
                            await searchUsers()
                        }
                    }
                
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if !searchResults.isEmpty {
                    List(searchResults) { user in
                        Button(action: { selectedUser = user }) {
                            HStack {
                                Text(user.avatarEmoji)
                                    .font(.largeTitle)
                                    .frame(width: 50, height: 50)
                                    .background(Color.gray.opacity(0.2))
                                    .clipShape(Circle())
                                
                                VStack(alignment: .leading) {
                                    Text(user.displayName)
                                        .font(.headline)
                                    Text("@\(user.username)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedUser?.id == user.id {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if selectedUser != nil {
                    VStack(alignment: .leading) {
                        Text("Add a message (optional)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        TextField("Hi! Let's hunt treasures together!", text: $message)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle("Add Friend")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Send") {
                        Task {
                            await sendFriendRequest()
                        }
                    }
                    .disabled(selectedUser == nil)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    private func searchUsers() async {
        guard !searchText.isEmpty else { return }
        
        isSearching = true
        do {
            searchResults = try await friendService.searchUsers(query: searchText)
            searchResults = searchResults.filter { user in
                user.id != friendService.currentUser?.id
            }
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        isSearching = false
    }
    
    private func sendFriendRequest() async {
        guard let selectedUser = selectedUser else { return }
        
        do {
            try await friendService.sendFriendRequest(
                to: selectedUser,
                message: message.isEmpty ? nil : message
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

#Preview {
    FriendsListView()
        .modelContainer(for: [User.self, FriendRelationship.self, FriendRequest.self])
}