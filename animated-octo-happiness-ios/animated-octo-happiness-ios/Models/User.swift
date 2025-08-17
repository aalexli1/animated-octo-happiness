//
//  User.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

@Model
final class User {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var username: String
    var displayName: String
    var avatarEmoji: String
    var createdAt: Date
    var isBlocked: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \FriendRelationship.user)
    var friendships: [FriendRelationship]?
    
    @Relationship(deleteRule: .cascade, inverse: \FriendRequest.sender)
    var sentFriendRequests: [FriendRequest]?
    
    @Relationship(deleteRule: .cascade, inverse: \FriendRequest.receiver)
    var receivedFriendRequests: [FriendRequest]?
    
    @Relationship(deleteRule: .nullify, inverse: \HuntingGroup.owner)
    var ownedGroups: [HuntingGroup]?
    
    @Relationship(deleteRule: .nullify)
    var joinedGroups: [HuntingGroup]?
    
    @Relationship(deleteRule: .cascade, inverse: \ActivityFeedItem.user)
    var activities: [ActivityFeedItem]?
    
    init(
        username: String,
        displayName: String,
        avatarEmoji: String = "🧑",
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.username = username
        self.displayName = displayName
        self.avatarEmoji = avatarEmoji
        self.createdAt = createdAt
        self.isBlocked = false
    }
}

extension User {
    var friends: [User] {
        guard let friendships = friendships else { return [] }
        return friendships.compactMap { relationship in
            relationship.status == .accepted ? relationship.friend : nil
        }
    }
    
    var pendingFriendRequests: [FriendRequest] {
        guard let requests = receivedFriendRequests else { return [] }
        return requests.filter { $0.status == .pending }
    }
    
    func isFriendWith(_ user: User) -> Bool {
        guard let friendships = friendships else { return false }
        return friendships.contains { relationship in
            relationship.friend?.id == user.id && relationship.status == .accepted
        }
    }
    
    func hasPendingRequestFrom(_ user: User) -> Bool {
        guard let requests = receivedFriendRequests else { return false }
        return requests.contains { request in
            request.sender?.id == user.id && request.status == .pending
        }
    }
    
    func hasSentRequestTo(_ user: User) -> Bool {
        guard let requests = sentFriendRequests else { return false }
        return requests.contains { request in
            request.receiver?.id == user.id && request.status == .pending
        }
    }
}

extension User {
    static var preview: User {
        User(
            username: "adventurer123",
            displayName: "Adventure Seeker",
            avatarEmoji: "🏃"
        )
    }
    
    static var previewData: [User] {
        [
            User(username: "explorer1", displayName: "Explorer One", avatarEmoji: "🚀"),
            User(username: "hunter2", displayName: "Treasure Hunter", avatarEmoji: "🔍"),
            User(username: "collector3", displayName: "The Collector", avatarEmoji: "💎")
        ]
    }
}