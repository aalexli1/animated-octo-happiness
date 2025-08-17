//
//  HuntingGroup.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

@Model
final class HuntingGroup {
    @Attribute(.unique) var id: UUID
    @Attribute(.unique) var inviteCode: String
    var name: String
    var groupDescription: String?
    var emoji: String
    var createdAt: Date
    var maxMembers: Int
    var isActive: Bool
    
    @Relationship(deleteRule: .nullify)
    var owner: User?
    
    @Relationship(deleteRule: .nullify)
    var members: [User]?
    
    @Relationship(deleteRule: .nullify)
    var sharedTreasures: [Treasure]?
    
    init(
        name: String,
        description: String? = nil,
        emoji: String = "👥",
        owner: User,
        maxMembers: Int = 20,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.inviteCode = HuntingGroup.generateInviteCode()
        self.name = name
        self.groupDescription = description
        self.emoji = emoji
        self.owner = owner
        self.members = [owner]
        self.maxMembers = maxMembers
        self.createdAt = createdAt
        self.isActive = true
    }
}

extension HuntingGroup {
    var memberCount: Int {
        members?.count ?? 0
    }
    
    var isFull: Bool {
        memberCount >= maxMembers
    }
    
    func addMember(_ user: User) -> Bool {
        guard !isFull, isActive else { return false }
        if members == nil {
            members = []
        }
        if !members!.contains(where: { $0.id == user.id }) {
            members!.append(user)
            return true
        }
        return false
    }
    
    func removeMember(_ user: User) {
        members?.removeAll { $0.id == user.id }
    }
    
    func isMember(_ user: User) -> Bool {
        members?.contains { $0.id == user.id } ?? false
    }
    
    func isOwner(_ user: User) -> Bool {
        owner?.id == user.id
    }
    
    static func generateInviteCode() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<6).map { _ in letters.randomElement()! })
    }
    
    func regenerateInviteCode() {
        inviteCode = HuntingGroup.generateInviteCode()
    }
}

extension HuntingGroup {
    static var preview: HuntingGroup {
        HuntingGroup(
            name: "Weekend Explorers",
            description: "A group for weekend treasure hunting adventures",
            emoji: "🏕️",
            owner: User.preview,
            maxMembers: 10
        )
    }
}