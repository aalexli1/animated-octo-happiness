//
//  Treasure.swift
//  animated-octo-happiness-ios
//
//  Created by Claude on 8/17/25.
//

import Foundation
import CoreLocation

struct Treasure: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let coordinate: CLLocationCoordinate2D
    let symbolName: String
    var isFound: Bool = false
    let hint: String?
    
    init(name: String, coordinate: CLLocationCoordinate2D, symbolName: String = "star.fill", hint: String? = nil) {
        self.name = name
        self.coordinate = coordinate
        self.symbolName = symbolName
        self.hint = hint
    }
    
    static func == (lhs: Treasure, rhs: Treasure) -> Bool {
        lhs.id == rhs.id
    }
}

extension Treasure {
    static let sampleTreasures = [
        Treasure(
            name: "Golden Star",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            symbolName: "star.fill",
            hint: "Look near the water"
        ),
        Treasure(
            name: "Diamond Gem",
            coordinate: CLLocationCoordinate2D(latitude: 37.7751, longitude: -122.4180),
            symbolName: "diamond.fill",
            hint: "Hidden in the park"
        ),
        Treasure(
            name: "Ancient Coin",
            coordinate: CLLocationCoordinate2D(latitude: 37.7740, longitude: -122.4200),
            symbolName: "bitcoinsign.circle.fill",
            hint: "Near the old building"
        )
    ]
}