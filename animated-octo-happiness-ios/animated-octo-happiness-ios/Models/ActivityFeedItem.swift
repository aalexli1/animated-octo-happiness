//
//  ActivityFeedItem.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

enum ActivityType: String, Codable, CaseIterable {
    case treasureCreated = "treasure_created"
    case treasureFound = "treasure_found"
    case treasureShared = "treasure_shared"
    case friendRequestSent = "friend_request_sent"
    case friendRequestAccepted = "friend_request_accepted"
    case groupCreated = "group_created"
    case groupJoined = "group_joined"
    case achievementUnlocked = "achievement_unlocked"
}

@Model
final class ActivityFeedItem {
    @Attribute(.unique) var id: UUID
    var type: ActivityType
    var title: String
    var message: String
    var timestamp: Date
    var isRead: Bool
    
    @Relationship(deleteRule: .nullify)
    var user: User?
    
    @Relationship(deleteRule: .nullify)
    var relatedUser: User?
    
    @Relationship(deleteRule: .nullify)
    var relatedTreasure: Treasure?
    
    @Relationship(deleteRule: .nullify)
    var relatedGroup: HuntingGroup?
    
    init(
        type: ActivityType,
        title: String,
        message: String,
        user: User,
        relatedUser: User? = nil,
        relatedTreasure: Treasure? = nil,
        relatedGroup: HuntingGroup? = nil,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.user = user
        self.relatedUser = relatedUser
        self.relatedTreasure = relatedTreasure
        self.relatedGroup = relatedGroup
        self.timestamp = timestamp
        self.isRead = false
    }
}

extension ActivityFeedItem {
    func markAsRead() {
        isRead = true
    }
    
    var emoji: String {
        switch type {
        case .treasureCreated: return "✨"
        case .treasureFound: return "🎉"
        case .treasureShared: return "🤝"
        case .friendRequestSent: return "👋"
        case .friendRequestAccepted: return "✅"
        case .groupCreated: return "👥"
        case .groupJoined: return "🤝"
        case .achievementUnlocked: return "🏆"
        }
    }
}

extension ActivityFeedItem {
    static var previewData: [ActivityFeedItem] {
        let user = User.preview
        let friend = User(username: "friend123", displayName: "Friend")
        let treasure = Treasure.preview
        
        return [
            ActivityFeedItem(
                type: .treasureFound,
                title: "Treasure Found!",
                message: "Your friend found the Ancient Coin",
                user: user,
                relatedUser: friend,
                relatedTreasure: treasure
            ),
            ActivityFeedItem(
                type: .friendRequestAccepted,
                title: "New Friend!",
                message: "Explorer One accepted your friend request",
                user: user,
                relatedUser: friend
            ),
            ActivityFeedItem(
                type: .treasureShared,
                title: "New Treasure Shared",
                message: "A friend shared a treasure with you",
                user: user,
                relatedUser: friend,
                relatedTreasure: treasure
            )
        ]
    }
}