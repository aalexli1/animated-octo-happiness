//
//  FriendService.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import Combine

class FriendService: ObservableObject {
    @Published var currentUser: User?
    @Published var friendRequests: [FriendRequest] = []
    @Published var friends: [User] = []
    @Published var blockedUsers: [User] = []
    @Published var activityFeed: [ActivityFeedItem] = []
    
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        loadCurrentUser()
    }
    
    func loadCurrentUser() {
        guard let context = modelContext else { return }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.username == "currentUser"
            }
        )
        
        do {
            let users = try context.fetch(descriptor)
            currentUser = users.first
            
            if currentUser == nil {
                let newUser = User(
                    username: "currentUser",
                    displayName: "Me",
                    email: "user@example.com",
                    avatarEmoji: "🤠"
                )
                context.insert(newUser)
                currentUser = newUser
                try context.save()
            }
            
            refreshFriendData()
        } catch {
            print("Error loading current user: \(error)")
        }
    }
    
    func refreshFriendData() {
        guard let user = currentUser else { return }
        
        friends = user.friends
        blockedUsers = user.blockedUsers
        loadFriendRequests()
        loadActivityFeed()
    }
    
    func sendFriendRequest(to username: String, message: String? = nil) throws {
        guard let context = modelContext,
              let currentUser = currentUser else {
            throw FriendServiceError.noCurrentUser
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.username == username
            }
        )
        
        let users = try context.fetch(descriptor)
        guard let targetUser = users.first else {
            throw FriendServiceError.userNotFound
        }
        
        if currentUser.isFriend(with: targetUser) {
            throw FriendServiceError.alreadyFriends
        }
        
        if currentUser.hasBlockedUser(targetUser) || targetUser.hasBlockedUser(currentUser) {
            throw FriendServiceError.userBlocked
        }
        
        let existingRequestDescriptor = FetchDescriptor<FriendRequest>(
            predicate: #Predicate { request in
                (request.fromUser?.id == currentUser.id && request.toUser?.id == targetUser.id) ||
                (request.fromUser?.id == targetUser.id && request.toUser?.id == currentUser.id)
            }
        )
        
        let existingRequests = try context.fetch(existingRequestDescriptor)
        if !existingRequests.filter({ $0.status == .pending }).isEmpty {
            throw FriendServiceError.requestAlreadyExists
        }
        
        let request = FriendRequest(from: currentUser, to: targetUser, message: message)
        context.insert(request)
        try context.save()
        
        loadFriendRequests()
    }
    
    func acceptFriendRequest(_ request: FriendRequest) throws {
        guard let context = modelContext else {
            throw FriendServiceError.noContext
        }
        
        request.accept()
        
        if let fromUser = request.fromUser,
           let toUser = request.toUser {
            let activity = ActivityFeedItem.friendJoined(friend: fromUser, for: toUser)
            context.insert(activity)
            
            let reciprocalActivity = ActivityFeedItem.friendJoined(friend: toUser, for: fromUser)
            context.insert(reciprocalActivity)
        }
        
        try context.save()
        refreshFriendData()
    }
    
    func declineFriendRequest(_ request: FriendRequest) throws {
        guard let context = modelContext else {
            throw FriendServiceError.noContext
        }
        
        request.decline()
        try context.save()
        loadFriendRequests()
    }
    
    func cancelFriendRequest(_ request: FriendRequest) throws {
        guard let context = modelContext else {
            throw FriendServiceError.noContext
        }
        
        request.cancel()
        try context.save()
        loadFriendRequests()
    }
    
    func removeFriend(_ friend: User) throws {
        guard let context = modelContext,
              let currentUser = currentUser else {
            throw FriendServiceError.noCurrentUser
        }
        
        currentUser.friends.removeAll { $0.id == friend.id }
        friend.friends.removeAll { $0.id == currentUser.id }
        
        try context.save()
        refreshFriendData()
    }
    
    func blockUser(_ user: User) throws {
        guard let context = modelContext,
              let currentUser = currentUser else {
            throw FriendServiceError.noCurrentUser
        }
        
        currentUser.blockUser(user)
        try context.save()
        refreshFriendData()
    }
    
    func unblockUser(_ user: User) throws {
        guard let context = modelContext,
              let currentUser = currentUser else {
            throw FriendServiceError.noCurrentUser
        }
        
        currentUser.unblockUser(user)
        try context.save()
        refreshFriendData()
    }
    
    private func loadFriendRequests() {
        guard let context = modelContext,
              let currentUser = currentUser else { return }
        
        let descriptor = FetchDescriptor<FriendRequest>(
            predicate: #Predicate { request in
                (request.toUser?.id == currentUser.id || request.fromUser?.id == currentUser.id) &&
                request.status == .pending
            },
            sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
        )
        
        do {
            friendRequests = try context.fetch(descriptor)
        } catch {
            print("Error loading friend requests: \(error)")
        }
    }
    
    private func loadActivityFeed() {
        guard let context = modelContext,
              let currentUser = currentUser else { return }
        
        let descriptor = FetchDescriptor<ActivityFeedItem>(
            predicate: #Predicate { item in
                item.user?.id == currentUser.id
            },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            activityFeed = try context.fetch(descriptor).prefix(50).map { $0 }
        } catch {
            print("Error loading activity feed: \(error)")
        }
    }
}

enum FriendServiceError: LocalizedError {
    case noCurrentUser
    case noContext
    case userNotFound
    case alreadyFriends
    case userBlocked
    case requestAlreadyExists
    
    var errorDescription: String? {
        switch self {
        case .noCurrentUser:
            return "No current user found"
        case .noContext:
            return "Model context not available"
        case .userNotFound:
            return "User not found"
        case .alreadyFriends:
            return "Already friends with this user"
        case .userBlocked:
            return "This user is blocked"
        case .requestAlreadyExists:
            return "Friend request already exists"
        }
    }
}