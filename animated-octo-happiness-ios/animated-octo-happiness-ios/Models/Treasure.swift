//
//  Treasure.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import CoreLocation

enum TreasurePrivacy: String, Codable, CaseIterable {
    case `public`
    case friends
    case `private`
    case group
}

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
    var privacy: TreasurePrivacy
    
    @Relationship(deleteRule: .nullify)
    var owner: User?
    
    @Relationship(deleteRule: .nullify)
    var sharedWithUsers: [User]
    
    @Relationship(deleteRule: .nullify, inverse: \TreasureGroup.sharedTreasures)
    var sharedWithGroups: [TreasureGroup]
    
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
        privacy: TreasurePrivacy = .public,
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
        self.privacy = privacy
        self.owner = owner
        self.sharedWithUsers = []
        self.sharedWithGroups = []
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
        privacy: TreasurePrivacy = .public,
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
            privacy: privacy,
            owner: owner
        )
    }
}

extension Treasure {
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
    
    func canBeSeenBy(user: User) -> Bool {
        switch privacy {
        case .public:
            return true
        case .private:
            return owner?.id == user.id
        case .friends:
            guard let owner = owner else { return false }
            return owner.id == user.id || owner.isFriend(with: user) || sharedWithUsers.contains { $0.id == user.id }
        case .group:
            return sharedWithGroups.contains { $0.isMember(user) }
        }
    }
    
    func shareWith(user: User) {
        if !sharedWithUsers.contains(where: { $0.id == user.id }) {
            sharedWithUsers.append(user)
        }
    }
    
    func shareWith(group: TreasureGroup) {
        if !sharedWithGroups.contains(where: { $0.id == group.id }) {
            sharedWithGroups.append(group)
            group.shareTreasure(self)
        }
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