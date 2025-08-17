//
//  ActivityFeedItem.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

enum ActivityType: String, Codable, CaseIterable {
    case treasureCreated
    case treasureCollected
    case treasureShared
    case friendJoined
    case groupCreated
    case groupJoined
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
    var relatedTreasure: Treasure?
    
    @Relationship(deleteRule: .nullify)
    var relatedUser: User?
    
    @Relationship(deleteRule: .nullify)
    var relatedGroup: TreasureGroup?
    
    init(
        type: ActivityType,
        title: String,
        message: String,
        user: User,
        relatedTreasure: Treasure? = nil,
        relatedUser: User? = nil,
        relatedGroup: TreasureGroup? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.message = message
        self.user = user
        self.relatedTreasure = relatedTreasure
        self.relatedUser = relatedUser
        self.relatedGroup = relatedGroup
        self.timestamp = Date()
        self.isRead = false
    }
    
    func markAsRead() {
        isRead = true
    }
}

extension ActivityFeedItem {
    static func treasureCollected(by user: User, treasure: Treasure) -> ActivityFeedItem {
        ActivityFeedItem(
            type: .treasureCollected,
            title: "\(user.displayName) found a treasure!",
            message: "\(user.displayName) collected \(treasure.title)",
            user: user,
            relatedTreasure: treasure
        )
    }
    
    static func treasureShared(by user: User, treasure: Treasure, with friend: User) -> ActivityFeedItem {
        ActivityFeedItem(
            type: .treasureShared,
            title: "\(user.displayName) shared a treasure",
            message: "\(user.displayName) shared \(treasure.title) with you",
            user: friend,
            relatedTreasure: treasure,
            relatedUser: user
        )
    }
    
    static func friendJoined(friend: User, for user: User) -> ActivityFeedItem {
        ActivityFeedItem(
            type: .friendJoined,
            title: "New friend joined!",
            message: "\(friend.displayName) is now your friend",
            user: user,
            relatedUser: friend
        )
    }
}