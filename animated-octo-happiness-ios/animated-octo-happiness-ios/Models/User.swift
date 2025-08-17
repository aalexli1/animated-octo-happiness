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
    var email: String?
    var avatarEmoji: String
    var createdAt: Date
    var lastActiveAt: Date
    var isBlocked: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \FriendRequest.fromUser)
    var sentFriendRequests: [FriendRequest]
    
    @Relationship(deleteRule: .cascade, inverse: \FriendRequest.toUser)
    var receivedFriendRequests: [FriendRequest]
    
    @Relationship(deleteRule: .nullify)
    var friends: [User]
    
    @Relationship(deleteRule: .nullify)
    var blockedUsers: [User]
    
    @Relationship(deleteRule: .cascade, inverse: \TreasureGroup.owner)
    var ownedGroups: [TreasureGroup]
    
    @Relationship(deleteRule: .nullify, inverse: \TreasureGroup.members)
    var joinedGroups: [TreasureGroup]
    
    @Relationship(deleteRule: .cascade, inverse: \Treasure.owner)
    var createdTreasures: [Treasure]
    
    @Relationship(deleteRule: .nullify)
    var collectedTreasures: [Treasure]
    
    @Relationship(deleteRule: .cascade, inverse: \ActivityFeedItem.user)
    var activityFeedItems: [ActivityFeedItem]
    
    init(
        username: String,
        displayName: String,
        email: String? = nil,
        avatarEmoji: String = "🤠"
    ) {
        self.id = UUID()
        self.username = username
        self.displayName = displayName
        self.email = email
        self.avatarEmoji = avatarEmoji
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.isBlocked = false
        self.sentFriendRequests = []
        self.receivedFriendRequests = []
        self.friends = []
        self.blockedUsers = []
        self.ownedGroups = []
        self.joinedGroups = []
        self.createdTreasures = []
        self.collectedTreasures = []
        self.activityFeedItems = []
    }
    
    func isFriend(with user: User) -> Bool {
        friends.contains { $0.id == user.id }
    }
    
    func hasBlockedUser(_ user: User) -> Bool {
        blockedUsers.contains { $0.id == user.id }
    }
    
    func blockUser(_ user: User) {
        if !hasBlockedUser(user) {
            blockedUsers.append(user)
            friends.removeAll { $0.id == user.id }
        }
    }
    
    func unblockUser(_ user: User) {
        blockedUsers.removeAll { $0.id == user.id }
    }
}

extension User {
    static var preview: User {
        User(
            username: "adventurer123",
            displayName: "Adventure Seeker",
            email: "adventurer@example.com",
            avatarEmoji: "🏴‍☠️"
        )
    }
    
    static var previewFriends: [User] {
        [
            User(username: "treasurehunter", displayName: "Treasure Hunter", avatarEmoji: "💎"),
            User(username: "explorer", displayName: "The Explorer", avatarEmoji: "🧭"),
            User(username: "goldseeker", displayName: "Gold Seeker", avatarEmoji: "⛏️")
        ]
    }
}