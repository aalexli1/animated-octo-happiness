//
//  FriendRelationship.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

enum FriendshipStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case blocked = "blocked"
}

@Model
final class FriendRelationship {
    @Attribute(.unique) var id: UUID
    var status: FriendshipStatus
    var createdAt: Date
    var updatedAt: Date
    
    @Relationship(deleteRule: .nullify)
    var user: User?
    
    @Relationship(deleteRule: .nullify)
    var friend: User?
    
    init(
        user: User,
        friend: User,
        status: FriendshipStatus = .pending,
        createdAt: Date = Date()
    ) {
        self.id = UUID()
        self.user = user
        self.friend = friend
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = createdAt
    }
}

extension FriendRelationship {
    func accept() {
        status = .accepted
        updatedAt = Date()
    }
    
    func block() {
        status = .blocked
        updatedAt = Date()
    }
    
    func unblock() {
        status = .pending
        updatedAt = Date()
    }
}