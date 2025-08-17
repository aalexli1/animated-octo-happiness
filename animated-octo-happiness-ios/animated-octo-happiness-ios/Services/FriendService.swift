//
//  FriendService.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import Combine

@MainActor
final class FriendService: ObservableObject {
    @Published var currentUser: User?
    @Published var friends: [User] = []
    @Published var pendingRequests: [FriendRequest] = []
    @Published var sentRequests: [FriendRequest] = []
    @Published var blockedUsers: [User] = []
    
    private var modelContext: ModelContext?
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func sendFriendRequest(to receiver: User, message: String? = nil) async throws {
        guard let currentUser = currentUser else {
            throw FriendServiceError.notAuthenticated
        }
        
        guard !currentUser.isFriendWith(receiver) else {
            throw FriendServiceError.alreadyFriends
        }
        
        guard !currentUser.hasSentRequestTo(receiver) else {
            throw FriendServiceError.requestAlreadySent
        }
        
        let request = FriendRequest(
            sender: currentUser,
            receiver: receiver,
            message: message
        )
        
        modelContext?.insert(request)
        
        let activity = ActivityFeedItem(
            type: .friendRequestSent,
            title: "Friend Request Sent",
            message: "You sent a friend request to \(receiver.displayName)",
            user: currentUser,
            relatedUser: receiver
        )
        modelContext?.insert(activity)
        
        try modelContext?.save()
        await refreshFriendData()
    }
    
    func acceptFriendRequest(_ request: FriendRequest) async throws {
        guard let currentUser = currentUser else {
            throw FriendServiceError.notAuthenticated
        }
        
        guard request.receiver?.id == currentUser.id else {
            throw FriendServiceError.unauthorizedAction
        }
        
        request.accept()
        
        if let sender = request.sender {
            let friendship1 = FriendRelationship(
                user: currentUser,
                friend: sender,
                status: .accepted
            )
            let friendship2 = FriendRelationship(
                user: sender,
                friend: currentUser,
                status: .accepted
            )
            
            modelContext?.insert(friendship1)
            modelContext?.insert(friendship2)
            
            let activity1 = ActivityFeedItem(
                type: .friendRequestAccepted,
                title: "Friend Request Accepted",
                message: "\(sender.displayName) is now your friend!",
                user: currentUser,
                relatedUser: sender
            )
            
            let activity2 = ActivityFeedItem(
                type: .friendRequestAccepted,
                title: "Friend Request Accepted",
                message: "\(currentUser.displayName) accepted your friend request!",
                user: sender,
                relatedUser: currentUser
            )
            
            modelContext?.insert(activity1)
            modelContext?.insert(activity2)
        }
        
        try modelContext?.save()
        await refreshFriendData()
    }
    
    func declineFriendRequest(_ request: FriendRequest) async throws {
        guard let currentUser = currentUser else {
            throw FriendServiceError.notAuthenticated
        }
        
        guard request.receiver?.id == currentUser.id else {
            throw FriendServiceError.unauthorizedAction
        }
        
        request.decline()
        try modelContext?.save()
        await refreshFriendData()
    }
    
    func cancelFriendRequest(_ request: FriendRequest) async throws {
        guard let currentUser = currentUser else {
            throw FriendServiceError.notAuthenticated
        }
        
        guard request.sender?.id == currentUser.id else {
            throw FriendServiceError.unauthorizedAction
        }
        
        request.cancel()
        try modelContext?.save()
        await refreshFriendData()
    }
    
    func removeFriend(_ friend: User) async throws {
        guard let currentUser = currentUser else {
            throw FriendServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw FriendServiceError.contextNotSet
        }
        
        let descriptor1 = FetchDescriptor<FriendRelationship>(
            predicate: #Predicate { relationship in
                relationship.user?.id == currentUser.id &&
                relationship.friend?.id == friend.id
            }
        )
        
        let descriptor2 = FetchDescriptor<FriendRelationship>(
            predicate: #Predicate { relationship in
                relationship.user?.id == friend.id &&
                relationship.friend?.id == currentUser.id
            }
        )
        
        if let relationships1 = try? modelContext.fetch(descriptor1) {
            for relationship in relationships1 {
                modelContext.delete(relationship)
            }
        }
        
        if let relationships2 = try? modelContext.fetch(descriptor2) {
            for relationship in relationships2 {
                modelContext.delete(relationship)
            }
        }
        
        try modelContext.save()
        await refreshFriendData()
    }
    
    func blockUser(_ user: User) async throws {
        guard let currentUser = currentUser else {
            throw FriendServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw FriendServiceError.contextNotSet
        }
        
        if currentUser.isFriendWith(user) {
            try await removeFriend(user)
        }
        
        let blockRelationship = FriendRelationship(
            user: currentUser,
            friend: user,
            status: .blocked
        )
        
        modelContext.insert(blockRelationship)
        
        let descriptor = FetchDescriptor<FriendRequest>(
            predicate: #Predicate { request in
                (request.sender?.id == user.id && request.receiver?.id == currentUser.id) ||
                (request.sender?.id == currentUser.id && request.receiver?.id == user.id)
            }
        )
        
        if let requests = try? modelContext.fetch(descriptor) {
            for request in requests {
                modelContext.delete(request)
            }
        }
        
        try modelContext.save()
        await refreshFriendData()
    }
    
    func unblockUser(_ user: User) async throws {
        guard let currentUser = currentUser else {
            throw FriendServiceError.notAuthenticated
        }
        
        guard let modelContext = modelContext else {
            throw FriendServiceError.contextNotSet
        }
        
        let descriptor = FetchDescriptor<FriendRelationship>(
            predicate: #Predicate { relationship in
                relationship.user?.id == currentUser.id &&
                relationship.friend?.id == user.id &&
                relationship.status == .blocked
            }
        )
        
        if let relationships = try? modelContext.fetch(descriptor) {
            for relationship in relationships {
                modelContext.delete(relationship)
            }
        }
        
        try modelContext.save()
        await refreshFriendData()
    }
    
    func searchUsers(query: String) async throws -> [User] {
        guard let modelContext = modelContext else {
            throw FriendServiceError.contextNotSet
        }
        
        let descriptor = FetchDescriptor<User>(
            predicate: #Predicate { user in
                user.username.localizedStandardContains(query) ||
                user.displayName.localizedStandardContains(query)
            }
        )
        
        return try modelContext.fetch(descriptor)
    }
    
    private func refreshFriendData() async {
        guard let currentUser = currentUser,
              let modelContext = modelContext else { return }
        
        do {
            let friendsDescriptor = FetchDescriptor<FriendRelationship>(
                predicate: #Predicate { relationship in
                    relationship.user?.id == currentUser.id &&
                    relationship.status == .accepted
                }
            )
            let friendRelationships = try modelContext.fetch(friendsDescriptor)
            self.friends = friendRelationships.compactMap { $0.friend }
            
            let pendingDescriptor = FetchDescriptor<FriendRequest>(
                predicate: #Predicate { request in
                    request.receiver?.id == currentUser.id &&
                    request.status == .pending
                }
            )
            self.pendingRequests = try modelContext.fetch(pendingDescriptor)
            
            let sentDescriptor = FetchDescriptor<FriendRequest>(
                predicate: #Predicate { request in
                    request.sender?.id == currentUser.id &&
                    request.status == .pending
                }
            )
            self.sentRequests = try modelContext.fetch(sentDescriptor)
            
            let blockedDescriptor = FetchDescriptor<FriendRelationship>(
                predicate: #Predicate { relationship in
                    relationship.user?.id == currentUser.id &&
                    relationship.status == .blocked
                }
            )
            let blockedRelationships = try modelContext.fetch(blockedDescriptor)
            self.blockedUsers = blockedRelationships.compactMap { $0.friend }
        } catch {
            print("Error refreshing friend data: \(error)")
        }
    }
}

enum FriendServiceError: LocalizedError {
    case notAuthenticated
    case alreadyFriends
    case requestAlreadySent
    case unauthorizedAction
    case contextNotSet
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be logged in to perform this action"
        case .alreadyFriends:
            return "You are already friends with this user"
        case .requestAlreadySent:
            return "You have already sent a friend request to this user"
        case .unauthorizedAction:
            return "You are not authorized to perform this action"
        case .contextNotSet:
            return "Database context not initialized"
        }
    }
}