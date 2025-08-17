//
//  FriendRequest.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending
    case accepted
    case declined
    case cancelled
}

@Model
final class FriendRequest {
    @Attribute(.unique) var id: UUID
    var status: FriendRequestStatus
    var sentAt: Date
    var respondedAt: Date?
    var message: String?
    
    @Relationship(deleteRule: .nullify)
    var fromUser: User?
    
    @Relationship(deleteRule: .nullify)
    var toUser: User?
    
    init(
        from: User,
        to: User,
        message: String? = nil
    ) {
        self.id = UUID()
        self.fromUser = from
        self.toUser = to
        self.status = .pending
        self.sentAt = Date()
        self.message = message
    }
    
    func accept() {
        guard status == .pending,
              let fromUser = fromUser,
              let toUser = toUser else { return }
        
        status = .accepted
        respondedAt = Date()
        
        if !fromUser.friends.contains(where: { $0.id == toUser.id }) {
            fromUser.friends.append(toUser)
        }
        if !toUser.friends.contains(where: { $0.id == fromUser.id }) {
            toUser.friends.append(fromUser)
        }
    }
    
    func decline() {
        guard status == .pending else { return }
        status = .declined
        respondedAt = Date()
    }
    
    func cancel() {
        guard status == .pending else { return }
        status = .cancelled
        respondedAt = Date()
    }
}

extension FriendRequest {
    static func preview(from: User, to: User) -> FriendRequest {
        FriendRequest(
            from: from,
            to: to,
            message: "Let's hunt treasures together!"
        )
    }
}