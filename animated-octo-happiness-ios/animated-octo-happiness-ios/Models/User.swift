//
//  User.swift
//  animated-octo-happiness-ios
//
//  User model for authentication and social features
//

import Foundation
import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    let email: String
    var displayName: String
    var profileImageURL: String?
    var createdAt: Date
    var updatedAt: Date
    var treasuresCreated: Int
    var treasuresFound: Int
    var friends: [String]
    var blockedUsers: [String]
    var notificationToken: String?
    var preferences: UserPreferences
    
    init(
        email: String,
        displayName: String,
        profileImageURL: String? = nil
    ) {
        self.email = email
        self.displayName = displayName
        self.profileImageURL = profileImageURL
        self.createdAt = Date()
        self.updatedAt = Date()
        self.treasuresCreated = 0
        self.treasuresFound = 0
        self.friends = []
        self.blockedUsers = []
        self.preferences = UserPreferences()
    }
}

struct UserPreferences: Codable {
    var shareLocation: Bool
    var notifyNearbyTreasures: Bool
    var notifyFriendActivities: Bool
    var notifyFriendRequests: Bool
    var treasureVisibility: TreasureVisibility
    var maxNotificationDistance: Double
    
    init(
        shareLocation: Bool = true,
        notifyNearbyTreasures: Bool = true,
        notifyFriendActivities: Bool = true,
        notifyFriendRequests: Bool = true,
        treasureVisibility: TreasureVisibility = .friends,
        maxNotificationDistance: Double = 5000
    ) {
        self.shareLocation = shareLocation
        self.notifyNearbyTreasures = notifyNearbyTreasures
        self.notifyFriendActivities = notifyFriendActivities
        self.notifyFriendRequests = notifyFriendRequests
        self.treasureVisibility = treasureVisibility
        self.maxNotificationDistance = maxNotificationDistance
    }
}

enum TreasureVisibility: String, Codable, CaseIterable {
    case `public` = "public"
    case friends = "friends"
    case `private` = "private"
    
    var displayName: String {
        switch self {
        case .public:
            return "Everyone"
        case .friends:
            return "Friends Only"
        case .private:
            return "Just Me"
        }
    }
}

struct FriendRequest: Identifiable, Codable {
    @DocumentID var id: String?
    let fromUserId: String
    let toUserId: String
    let fromUserName: String
    let toUserName: String
    let sentAt: Date
    var status: FriendRequestStatus
    var respondedAt: Date?
    
    init(
        fromUserId: String,
        toUserId: String,
        fromUserName: String,
        toUserName: String
    ) {
        self.fromUserId = fromUserId
        self.toUserId = toUserId
        self.fromUserName = fromUserName
        self.toUserName = toUserName
        self.sentAt = Date()
        self.status = .pending
    }
}

enum FriendRequestStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case rejected = "rejected"
    case cancelled = "cancelled"
}