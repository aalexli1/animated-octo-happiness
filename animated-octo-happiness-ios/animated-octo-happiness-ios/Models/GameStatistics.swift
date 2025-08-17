//
//  GameStatistics.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData

@Model
final class GameStatistics {
    var id: UUID
    var userId: String
    var totalTreasuresFound: Int
    var totalTreasuresCreated: Int
    var totalPoints: Int
    var totalPlayTime: TimeInterval
    var lastPlayedDate: Date
    var favoriteLocation: String?
    var longestStreak: Int
    var currentStreak: Int
    var lastStreakDate: Date?
    var achievementIds: [String]
    var distanceTraveled: Double
    var uniqueLocationsVisited: Int
    var treasuresByDifficulty: [Int: Int]
    var firstTreasureDate: Date?
    var mostRecentTreasureDate: Date?
    
    init(userId: String) {
        self.id = UUID()
        self.userId = userId
        self.totalTreasuresFound = 0
        self.totalTreasuresCreated = 0
        self.totalPoints = 0
        self.totalPlayTime = 0
        self.lastPlayedDate = Date()
        self.longestStreak = 0
        self.currentStreak = 0
        self.achievementIds = []
        self.distanceTraveled = 0.0
        self.uniqueLocationsVisited = 0
        self.treasuresByDifficulty = [:]
    }
    
    func recordTreasureFound(treasure: Treasure, points: Int = 10) {
        totalTreasuresFound += 1
        totalPoints += points * treasure.difficulty
        
        treasuresByDifficulty[treasure.difficulty, default: 0] += 1
        
        if firstTreasureDate == nil {
            firstTreasureDate = Date()
        }
        mostRecentTreasureDate = Date()
        
        updateStreak()
    }
    
    func recordTreasureCreated() {
        totalTreasuresCreated += 1
        totalPoints += 5
    }
    
    func updatePlayTime(seconds: TimeInterval) {
        totalPlayTime += seconds
        lastPlayedDate = Date()
    }
    
    func updateDistanceTraveled(meters: Double) {
        distanceTraveled += meters
    }
    
    private func updateStreak() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastDate = lastStreakDate {
            let lastDay = calendar.startOfDay(for: lastDate)
            let dayDifference = calendar.dateComponents([.day], from: lastDay, to: today).day ?? 0
            
            if dayDifference == 0 {
                return
            } else if dayDifference == 1 {
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else {
                currentStreak = 1
            }
        } else {
            currentStreak = 1
            if longestStreak == 0 {
                longestStreak = 1
            }
        }
        
        lastStreakDate = today
    }
    
    func checkAchievements() -> [String] {
        var newAchievements: [String] = []
        
        if totalTreasuresFound >= 1 && !achievementIds.contains("first_treasure") {
            achievementIds.append("first_treasure")
            newAchievements.append("first_treasure")
        }
        
        if totalTreasuresFound >= 10 && !achievementIds.contains("collector_10") {
            achievementIds.append("collector_10")
            newAchievements.append("collector_10")
        }
        
        if totalTreasuresFound >= 50 && !achievementIds.contains("collector_50") {
            achievementIds.append("collector_50")
            newAchievements.append("collector_50")
        }
        
        if totalTreasuresFound >= 100 && !achievementIds.contains("master_collector") {
            achievementIds.append("master_collector")
            newAchievements.append("master_collector")
        }
        
        if totalTreasuresCreated >= 5 && !achievementIds.contains("creator_5") {
            achievementIds.append("creator_5")
            newAchievements.append("creator_5")
        }
        
        if currentStreak >= 7 && !achievementIds.contains("week_streak") {
            achievementIds.append("week_streak")
            newAchievements.append("week_streak")
        }
        
        if currentStreak >= 30 && !achievementIds.contains("month_streak") {
            achievementIds.append("month_streak")
            newAchievements.append("month_streak")
        }
        
        if distanceTraveled >= 10000 && !achievementIds.contains("explorer_10km") {
            achievementIds.append("explorer_10km")
            newAchievements.append("explorer_10km")
        }
        
        return newAchievements
    }
}

extension GameStatistics {
    var formattedPlayTime: String {
        let hours = Int(totalPlayTime) / 3600
        let minutes = (Int(totalPlayTime) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
    
    var formattedDistance: String {
        if distanceTraveled < 1000 {
            return String(format: "%.0f m", distanceTraveled)
        } else {
            return String(format: "%.1f km", distanceTraveled / 1000)
        }
    }
    
    static var preview: GameStatistics {
        let stats = GameStatistics(userId: "preview-user")
        stats.totalTreasuresFound = 25
        stats.totalTreasuresCreated = 5
        stats.totalPoints = 300
        stats.totalPlayTime = 7200
        stats.currentStreak = 3
        stats.longestStreak = 7
        stats.distanceTraveled = 5280
        stats.uniqueLocationsVisited = 12
        stats.treasuresByDifficulty = [1: 15, 2: 8, 3: 2]
        return stats
    }
}