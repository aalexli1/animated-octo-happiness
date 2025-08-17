//
//  GameStateManager.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/17/25.
//

import Foundation
import Combine

class GameStateManager: ObservableObject {
    @Published var playerStats: PlayerStats
    @Published var achievements: [Achievement] = []
    @Published var discoveredTreasures: Set<UUID> = []
    
    private let userDefaults = UserDefaults.standard
    private let statsKey = "playerStats"
    private let achievementsKey = "achievements"
    private let treasuresKey = "discoveredTreasures"
    
    static let shared = GameStateManager()
    
    init() {
        self.playerStats = PlayerStats()
        loadState()
        initializeAchievements()
    }
    
    private func initializeAchievements() {
        achievements = [
            Achievement(id: "first_treasure", name: "First Discovery", description: "Find your first treasure", requirement: 1, icon: "star.fill"),
            Achievement(id: "treasure_hunter", name: "Treasure Hunter", description: "Find 10 treasures", requirement: 10, icon: "crown.fill"),
            Achievement(id: "master_hunter", name: "Master Hunter", description: "Find 50 treasures", requirement: 50, icon: "trophy.fill"),
            Achievement(id: "gold_rush", name: "Gold Rush", description: "Find 5 gold treasures", requirement: 5, icon: "dollarsign.circle.fill"),
            Achievement(id: "high_scorer", name: "High Scorer", description: "Reach 1000 points", requirement: 1000, icon: "gamecontroller.fill"),
            Achievement(id: "explorer", name: "Explorer", description: "Play for 30 minutes", requirement: 30, icon: "map.fill"),
            Achievement(id: "perfectionist", name: "Perfectionist", description: "Find all treasures in a single session", requirement: 1, icon: "checkmark.seal.fill")
        ]
    }
    
    func recordTreasureDiscovery(_ treasure: Treasure) {
        discoveredTreasures.insert(treasure.id)
        playerStats.totalTreasuresFound += 1
        playerStats.totalScore += treasure.type.points
        
        switch treasure.type {
        case .gold:
            playerStats.goldTreasuresFound += 1
        case .silver:
            playerStats.silverTreasuresFound += 1
        case .bronze:
            playerStats.bronzeTreasuresFound += 1
        case .gem:
            playerStats.gemTreasuresFound += 1
        case .artifact:
            playerStats.artifactTreasuresFound += 1
        }
        
        checkAchievements()
        saveState()
    }
    
    func recordSessionComplete(treasuresFound: Int, totalTreasures: Int) {
        playerStats.sessionsPlayed += 1
        
        if treasuresFound == totalTreasures {
            playerStats.perfectSessions += 1
        }
        
        checkAchievements()
        saveState()
    }
    
    func updatePlayTime(_ minutes: Int) {
        playerStats.totalPlayTimeMinutes += minutes
        checkAchievements()
        saveState()
    }
    
    private func checkAchievements() {
        for index in achievements.indices {
            if !achievements[index].isUnlocked {
                switch achievements[index].id {
                case "first_treasure":
                    if playerStats.totalTreasuresFound >= 1 {
                        achievements[index].unlock()
                    }
                case "treasure_hunter":
                    if playerStats.totalTreasuresFound >= 10 {
                        achievements[index].unlock()
                    }
                case "master_hunter":
                    if playerStats.totalTreasuresFound >= 50 {
                        achievements[index].unlock()
                    }
                case "gold_rush":
                    if playerStats.goldTreasuresFound >= 5 {
                        achievements[index].unlock()
                    }
                case "high_scorer":
                    if playerStats.totalScore >= 1000 {
                        achievements[index].unlock()
                    }
                case "explorer":
                    if playerStats.totalPlayTimeMinutes >= 30 {
                        achievements[index].unlock()
                    }
                case "perfectionist":
                    if playerStats.perfectSessions >= 1 {
                        achievements[index].unlock()
                    }
                default:
                    break
                }
            }
        }
    }
    
    private func saveState() {
        if let encoded = try? JSONEncoder().encode(playerStats) {
            userDefaults.set(encoded, forKey: statsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(achievements) {
            userDefaults.set(encoded, forKey: achievementsKey)
        }
        
        if let encoded = try? JSONEncoder().encode(Array(discoveredTreasures)) {
            userDefaults.set(encoded, forKey: treasuresKey)
        }
    }
    
    private func loadState() {
        if let data = userDefaults.data(forKey: statsKey),
           let decoded = try? JSONDecoder().decode(PlayerStats.self, from: data) {
            self.playerStats = decoded
        }
        
        if let data = userDefaults.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode([Achievement].self, from: data) {
            self.achievements = decoded
        }
        
        if let data = userDefaults.data(forKey: treasuresKey),
           let decoded = try? JSONDecoder().decode([UUID].self, from: data) {
            self.discoveredTreasures = Set(decoded)
        }
    }
    
    func resetProgress() {
        playerStats = PlayerStats()
        discoveredTreasures.removeAll()
        initializeAchievements()
        saveState()
    }
}

struct PlayerStats: Codable {
    var totalTreasuresFound: Int = 0
    var totalScore: Int = 0
    var goldTreasuresFound: Int = 0
    var silverTreasuresFound: Int = 0
    var bronzeTreasuresFound: Int = 0
    var gemTreasuresFound: Int = 0
    var artifactTreasuresFound: Int = 0
    var sessionsPlayed: Int = 0
    var perfectSessions: Int = 0
    var totalPlayTimeMinutes: Int = 0
}

struct Achievement: Identifiable, Codable {
    let id: String
    let name: String
    let description: String
    let requirement: Int
    let icon: String
    var isUnlocked: Bool = false
    var unlockedDate: Date?
    
    mutating func unlock() {
        isUnlocked = true
        unlockedDate = Date()
    }
}