//
//  PlayerProfile.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import SwiftUI

@Model
final class PlayerProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var avatarEmoji: String
    var avatarColor: String
    var createdAt: Date
    var lastActiveAt: Date
    var isActive: Bool
    var statistics: GameStatistics?
    var treasuresFound: [Treasure]?
    var treasuresCreated: [Treasure]?
    
    init(
        name: String,
        avatarEmoji: String = "🧑‍💻",
        avatarColor: String = "blue"
    ) {
        self.id = UUID()
        self.name = name
        self.avatarEmoji = avatarEmoji
        self.avatarColor = avatarColor
        self.createdAt = Date()
        self.lastActiveAt = Date()
        self.isActive = false
        self.statistics = GameStatistics(userId: id.uuidString)
    }
    
    func makeActive() {
        self.isActive = true
        self.lastActiveAt = Date()
    }
    
    func deactivate() {
        self.isActive = false
    }
    
    var color: Color {
        switch avatarColor.lowercased() {
        case "red": return .red
        case "blue": return .blue
        case "green": return .green
        case "purple": return .purple
        case "orange": return .orange
        case "pink": return .pink
        case "yellow": return .yellow
        case "teal": return .teal
        case "indigo": return .indigo
        default: return .blue
        }
    }
}

extension PlayerProfile {
    static var defaultProfile: PlayerProfile {
        PlayerProfile(name: "Player 1", avatarEmoji: "🧑‍💻", avatarColor: "blue")
    }
    
    static var previewProfiles: [PlayerProfile] {
        [
            PlayerProfile(name: "Alice", avatarEmoji: "👩‍🎨", avatarColor: "purple"),
            PlayerProfile(name: "Bob", avatarEmoji: "👨‍💼", avatarColor: "green"),
            PlayerProfile(name: "Charlie", avatarEmoji: "🧑‍🚀", avatarColor: "orange")
        ]
    }
    
    static var availableEmojis: [String] {
        ["🧑‍💻", "👩‍🎨", "👨‍💼", "🧑‍🚀", "👩‍🔬", "👨‍🍳", 
         "🧑‍🎓", "👩‍⚕️", "👨‍🌾", "🧑‍🏫", "👩‍🏭", "👨‍🎤",
         "🦸", "🦹‍♀️", "🧙‍♂️", "🧝‍♀️", "🧛", "🧟‍♂️",
         "🐶", "🐱", "🐭", "🐹", "🐰", "🦊",
         "🐻", "🐼", "🐨", "🐯", "🦁", "🐮"]
    }
    
    static var availableColors: [(name: String, color: Color)] {
        [
            ("Red", .red),
            ("Blue", .blue),
            ("Green", .green),
            ("Purple", .purple),
            ("Orange", .orange),
            ("Pink", .pink),
            ("Yellow", .yellow),
            ("Teal", .teal),
            ("Indigo", .indigo)
        ]
    }
}