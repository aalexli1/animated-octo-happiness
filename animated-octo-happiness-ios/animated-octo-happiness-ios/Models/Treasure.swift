//
//  Treasure.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class Treasure {
    @Attribute(.unique) var id: UUID
    var title: String
    var treasureDescription: String
    var latitude: Double
    var longitude: Double
    var timestamp: Date
    var isCollected: Bool
    var notes: String?
    var imageData: Data?
    var emoji: String?
    var createdBy: String?
    var privacyLevel: PrivacyLevel
    
    @Relationship(deleteRule: .nullify)
    var owner: User?
    
    @Relationship(deleteRule: .nullify)
    var sharedWithUsers: [User]?
    
    @Relationship(deleteRule: .nullify)
    var sharedWithGroup: HuntingGroup?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(
        title: String,
        description: String,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        isCollected: Bool = false,
        notes: String? = nil,
        imageData: Data? = nil,
        emoji: String? = "🎁",
        createdBy: String? = nil,
        privacyLevel: PrivacyLevel = .publicAccess,
        owner: User? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.treasureDescription = description
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.isCollected = isCollected
        self.notes = notes
        self.imageData = imageData
        self.emoji = emoji
        self.createdBy = createdBy
        self.privacyLevel = privacyLevel
        self.owner = owner
    }
    
    convenience init(
        title: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        timestamp: Date = Date(),
        isCollected: Bool = false,
        notes: String? = nil,
        imageData: Data? = nil,
        emoji: String? = "🎁",
        createdBy: String? = nil,
        privacyLevel: PrivacyLevel = .publicAccess,
        owner: User? = nil
    ) {
        self.init(
            title: title,
            description: description,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: timestamp,
            isCollected: isCollected,
            notes: notes,
            imageData: imageData,
            emoji: emoji,
            createdBy: createdBy,
            privacyLevel: privacyLevel,
            owner: owner
        )
    }
}

extension Treasure {
    func canBeViewedBy(_ user: User?) -> Bool {
        switch privacyLevel {
        case .publicAccess:
            return true
        case .privateAccess:
            return user?.id == owner?.id
        case .friendsOnly:
            guard let user = user, let owner = owner else { return false }
            return user.id == owner.id || owner.isFriendWith(user)
        case .groupOnly:
            guard let user = user, let group = sharedWithGroup else { return false }
            return group.isMember(user)
        }
    }
    
    func shareWith(users: [User]) {
        if sharedWithUsers == nil {
            sharedWithUsers = []
        }
        for user in users {
            if !sharedWithUsers!.contains(where: { $0.id == user.id }) {
                sharedWithUsers!.append(user)
            }
        }
    }
    
    func shareWithGroup(_ group: HuntingGroup) {
        sharedWithGroup = group
        privacyLevel = .groupOnly
    }
    
    func removeSharing(for user: User) {
        sharedWithUsers?.removeAll { $0.id == user.id }
    }
    
    static func isValidTitle(_ title: String) -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 100
    }
    
    static func isValidDescription(_ description: String) -> Bool {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && trimmed.count <= 500
    }
    
    static func isValidCoordinate(latitude: Double, longitude: Double) -> Bool {
        return latitude >= -90 && latitude <= 90 && longitude >= -180 && longitude <= 180
    }
}

extension Treasure {
    static var preview: Treasure {
        Treasure(
            title: "Ancient Coin",
            description: "A mysterious golden coin found near the old oak tree",
            latitude: 37.7749,
            longitude: -122.4194,
            timestamp: Date(),
            isCollected: false,
            notes: "Found while metal detecting in the park",
            emoji: "💰"
        )
    }
    
    static var previewData: [Treasure] {
        [
            Treasure(
                title: "Ancient Coin",
                description: "A mysterious golden coin found near the old oak tree",
                latitude: 37.7749,
                longitude: -122.4194,
                timestamp: Date().addingTimeInterval(-86400),
                isCollected: true,
                notes: "Found while metal detecting in the park",
                emoji: "💰"
            ),
            Treasure(
                title: "Crystal Fragment",
                description: "A shimmering crystal piece that reflects rainbow colors",
                latitude: 37.7849,
                longitude: -122.4094,
                timestamp: Date().addingTimeInterval(-172800),
                isCollected: false,
                notes: "Discovered near the waterfall",
                emoji: "💎"
            ),
            Treasure(
                title: "Old Map",
                description: "A weathered map showing locations of other treasures",
                latitude: 37.7649,
                longitude: -122.4294,
                timestamp: Date().addingTimeInterval(-259200),
                isCollected: false,
                emoji: "🗺️"
            )
        ]
    }
}