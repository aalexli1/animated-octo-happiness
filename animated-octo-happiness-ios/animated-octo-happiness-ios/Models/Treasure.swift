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
    var collectedBy: String?
    var collectedAt: Date?
    var notes: String?
    var imageData: Data?
    var emoji: String?
    var createdBy: String?
    var difficulty: Int
    var hints: [String]
    var isCustom: Bool
    
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
        collectedBy: String? = nil,
        collectedAt: Date? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        emoji: String? = "🎁",
        createdBy: String? = nil,
        difficulty: Int = 1,
        hints: [String] = [],
        isCustom: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.treasureDescription = description
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.isCollected = isCollected
        self.collectedBy = collectedBy
        self.collectedAt = collectedAt
        self.notes = notes
        self.imageData = imageData
        self.emoji = emoji
        self.createdBy = createdBy
        self.difficulty = difficulty
        self.hints = hints
        self.isCustom = isCustom
    }
    
    convenience init(
        title: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        timestamp: Date = Date(),
        isCollected: Bool = false,
        collectedBy: String? = nil,
        collectedAt: Date? = nil,
        notes: String? = nil,
        imageData: Data? = nil,
        emoji: String? = "🎁",
        createdBy: String? = nil,
        difficulty: Int = 1,
        hints: [String] = [],
        isCustom: Bool = false
    ) {
        self.init(
            title: title,
            description: description,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude,
            timestamp: timestamp,
            isCollected: isCollected,
            collectedBy: collectedBy,
            collectedAt: collectedAt,
            notes: notes,
            imageData: imageData,
            emoji: emoji,
            createdBy: createdBy,
            difficulty: difficulty,
            hints: hints,
            isCustom: isCustom
        )
    }
    
    var isFound: Bool {
        isCollected
    }
    
    var foundBy: String? {
        collectedBy
    }
    
    var foundAt: Date? {
        collectedAt
    }
    
    var photoData: Data? {
        get { imageData }
        set { imageData = newValue }
    }
    
    func markAsCollected(by userId: String) {
        self.isCollected = true
        self.collectedBy = userId
        self.collectedAt = Date()
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