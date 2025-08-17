//
//  FriendRequest.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

enum FriendRequestStatus: String, Codable, CaseIterable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case cancelled = "cancelled"
}

@Model
final class FriendRequest {
    @Attribute(.unique) var id: UUID
    var status: FriendRequestStatus
    var message: String?
    var sentAt: Date
    var respondedAt: Date?
    
    @Relationship(deleteRule: .nullify)
    var sender: User?
    
    @Relationship(deleteRule: .nullify)
    var receiver: User?
    
    init(
        sender: User,
        receiver: User,
        message: String? = nil,
        sentAt: Date = Date()
    ) {
        self.id = UUID()
        self.sender = sender
        self.receiver = receiver
        self.message = message
        self.status = .pending
        self.sentAt = sentAt
        self.respondedAt = nil
    }
}

extension FriendRequest {
    func accept() {
        status = .accepted
        respondedAt = Date()
    }
    
    func decline() {
        status = .declined
        respondedAt = Date()
    }
    
    func cancel() {
        status = .cancelled
        respondedAt = Date()
    }
    
    var isPending: Bool {
        status == .pending
    }
    
    var isResponded: Bool {
        status != .pending
    }
}