//
//  Treasure.swift
//  animated-octo-happiness-ios
//
//  Created by Auto Agent on 8/17/25.
//

import Foundation
import CoreLocation
import MapKit

struct Treasure: Identifiable, Codable {
    let id: UUID
    let name: String
    let treasureDescription: String
    let latitude: Double
    let longitude: Double
    let createdAt: Date
    var isCollected: Bool
    
    init(id: UUID = UUID(), 
         name: String, 
         description: String, 
         latitude: Double, 
         longitude: Double, 
         createdAt: Date = Date(), 
         isCollected: Bool = false) {
        self.id = id
        self.name = name
        self.treasureDescription = description
        self.latitude = latitude
        self.longitude = longitude
        self.createdAt = createdAt
        self.isCollected = isCollected
    }
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

class TreasureAnnotation: NSObject, MKAnnotation {
    let treasure: Treasure
    
    init(treasure: Treasure) {
        self.treasure = treasure
        super.init()
    }
    
    var coordinate: CLLocationCoordinate2D {
        treasure.coordinate
    }
    
    var title: String? {
        treasure.name
    }
    
    var subtitle: String? {
        treasure.treasureDescription
    }
}