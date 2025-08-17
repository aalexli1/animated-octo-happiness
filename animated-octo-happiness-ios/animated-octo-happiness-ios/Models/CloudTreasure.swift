//
//  CloudTreasure.swift
//  animated-octo-happiness-ios
//
//  Cloud-compatible Treasure model for Firebase
//

import Foundation
import CoreLocation
import FirebaseFirestore

struct CloudTreasure: Identifiable, Codable {
    @DocumentID var id: String?
    let title: String
    let description: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    let createdBy: String
    let createdByName: String
    var isCollected: Bool
    var collectedBy: String?
    var collectedByName: String?
    var collectedAt: Date?
    var imageURL: String?
    var emoji: String
    var visibility: TreasureVisibility
    var sharedWith: [String]
    var notes: String?
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
    
    init(
        title: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        createdBy: String,
        createdByName: String,
        imageURL: String? = nil,
        emoji: String = "🎁",
        visibility: TreasureVisibility = .friends,
        sharedWith: [String] = [],
        notes: String? = nil
    ) {
        self.title = title
        self.description = description
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.createdAt = Date()
        self.createdBy = createdBy
        self.createdByName = createdByName
        self.isCollected = false
        self.imageURL = imageURL
        self.emoji = emoji
        self.visibility = visibility
        self.sharedWith = sharedWith
        self.notes = notes
    }
    
    mutating func markAsCollected(by userId: String, userName: String) {
        self.isCollected = true
        self.collectedBy = userId
        self.collectedByName = userName
        self.collectedAt = Date()
    }
}

extension CloudTreasure {
    func toLocalTreasure() -> Treasure {
        Treasure(
            title: title,
            description: description,
            latitude: latitude,
            longitude: longitude,
            timestamp: createdAt,
            isCollected: isCollected,
            notes: notes,
            imageData: nil,
            emoji: emoji,
            createdBy: createdByName
        )
    }
}