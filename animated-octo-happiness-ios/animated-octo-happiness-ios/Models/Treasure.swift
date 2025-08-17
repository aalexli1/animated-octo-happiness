//
//  Treasure.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import Foundation
import CoreLocation
import SwiftUI

struct Treasure: Identifiable, Codable {
    let id: UUID
    var title: String
    var message: String
    var latitude: Double
    var longitude: Double
    var emoji: String
    var photoData: Data?
    var createdAt: Date
    var createdBy: String
    var isFound: Bool
    var foundBy: String?
    var foundAt: Date?
    
    init(id: UUID = UUID(),
         title: String = "",
         message: String = "",
         latitude: Double = 0.0,
         longitude: Double = 0.0,
         emoji: String = "🎁",
         photoData: Data? = nil,
         createdAt: Date = Date(),
         createdBy: String = "",
         isFound: Bool = false,
         foundBy: String? = nil,
         foundAt: Date? = nil) {
        self.id = id
        self.title = title
        self.message = message
        self.latitude = latitude
        self.longitude = longitude
        self.emoji = emoji
        self.photoData = photoData
        self.createdAt = createdAt
        self.createdBy = createdBy
        self.isFound = isFound
        self.foundBy = foundBy
        self.foundAt = foundAt
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var location: CLLocation {
        CLLocation(latitude: latitude, longitude: longitude)
    }
}

extension Treasure {
    static let sampleTreasure = Treasure(
        title: "Hidden Surprise",
        message: "You found a special treasure! 🎉",
        latitude: 37.7749,
        longitude: -122.4194,
        emoji: "💎",
        createdBy: "SampleUser"
    )
}