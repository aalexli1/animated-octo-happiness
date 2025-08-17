//
//  TreasureGroup.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

@Model
final class TreasureGroup {
    @Attribute(.unique) var id: UUID
    var name: String
    var groupDescription: String?
    var emoji: String
    var createdAt: Date
    var isActive: Bool
    
    @Relationship(deleteRule: .nullify)
    var owner: User?
    
    @Relationship(deleteRule: .nullify)
    var members: [User]
    
    @Relationship(deleteRule: .nullify)
    var sharedTreasures: [Treasure]
    
    init(
        name: String,
        description: String? = nil,
        owner: User,
        emoji: String = "👥"
    ) {
        self.id = UUID()
        self.name = name
        self.groupDescription = description
        self.emoji = emoji
        self.owner = owner
        self.members = [owner]
        self.sharedTreasures = []
        self.createdAt = Date()
        self.isActive = true
    }
    
    func addMember(_ user: User) {
        if !members.contains(where: { $0.id == user.id }) {
            members.append(user)
        }
    }
    
    func removeMember(_ user: User) {
        members.removeAll { $0.id == user.id }
    }
    
    func isMember(_ user: User) -> Bool {
        members.contains { $0.id == user.id }
    }
    
    func isOwner(_ user: User) -> Bool {
        owner?.id == user.id
    }
    
    func shareTreasure(_ treasure: Treasure) {
        if !sharedTreasures.contains(where: { $0.id == treasure.id }) {
            sharedTreasures.append(treasure)
        }
    }
}

extension TreasureGroup {
    static var preview: TreasureGroup {
        TreasureGroup(
            name: "Weekend Warriors",
            description: "Our weekend treasure hunting crew",
            owner: User.preview,
            emoji: "⚔️"
        )
    }
}