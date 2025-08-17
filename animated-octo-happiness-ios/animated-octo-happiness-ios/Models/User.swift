//
//  User.swift
//  animated-octo-happiness-ios
//
//  Created by Auto-Agent on 8/17/25.
//

import Foundation
import SwiftData

@Model
final class User {
    var id: String
    var email: String?
    var displayName: String?
    var photoURL: String?
    var isAnonymous: Bool
    var createdAt: Date
    var lastLoginAt: Date?
    var treasuresCreated: [Treasure]?
    var treasuresFound: [Treasure]?
    var totalScore: Int
    var achievements: [String]
    var preferences: UserPreferences?
    var statistics: GameStatistics?
    var activeProfile: PlayerProfile?
    
    init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        photoURL: String? = nil,
        isAnonymous: Bool = false,
        createdAt: Date = Date(),
        lastLoginAt: Date? = nil,
        totalScore: Int = 0,
        achievements: [String] = []
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.isAnonymous = isAnonymous
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
        self.totalScore = totalScore
        self.achievements = achievements
    }
}

@Model
final class UserPreferences {
    var notificationsEnabled: Bool
    var locationSharingEnabled: Bool
    var soundEnabled: Bool
    var hapticFeedbackEnabled: Bool
    var theme: String
    
    init(
        notificationsEnabled: Bool = true,
        locationSharingEnabled: Bool = true,
        soundEnabled: Bool = true,
        hapticFeedbackEnabled: Bool = true,
        theme: String = "system"
    ) {
        self.notificationsEnabled = notificationsEnabled
        self.locationSharingEnabled = locationSharingEnabled
        self.soundEnabled = soundEnabled
        self.hapticFeedbackEnabled = hapticFeedbackEnabled
        self.theme = theme
    }
}

extension User {
    func migrateFromAnonymous(to email: String, displayName: String? = nil) {
        self.isAnonymous = false
        self.email = email
        self.displayName = displayName ?? email.components(separatedBy: "@").first
    }
    
    func updateProfile(displayName: String? = nil, photoURL: String? = nil) {
        if let displayName = displayName {
            self.displayName = displayName
        }
        if let photoURL = photoURL {
            self.photoURL = photoURL
        }
    }
    
    func recordLogin() {
        self.lastLoginAt = Date()
    }
    
    func addAchievement(_ achievement: String) {
        if !achievements.contains(achievement) {
            achievements.append(achievement)
        }
    }
    
    func incrementScore(by points: Int) {
        totalScore += points
    }
}