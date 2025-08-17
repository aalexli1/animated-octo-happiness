//
//  PersistenceManager.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import SwiftUI
import CoreLocation

@MainActor
class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    @Published var currentProfile: PlayerProfile?
    @Published var allProfiles: [PlayerProfile] = []
    @Published var treasures: [Treasure] = []
    @Published var currentUser: User?
    
    private var modelContext: ModelContext?
    
    private init() {}
    
    func configure(with modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await loadInitialData()
        }
    }
    
    private func loadInitialData() async {
        guard let context = modelContext else { return }
        
        do {
            let profileDescriptor = FetchDescriptor<PlayerProfile>(
                sortBy: [SortDescriptor(\.lastActiveAt, order: .reverse)]
            )
            allProfiles = try context.fetch(profileDescriptor)
            
            if let activeProfile = allProfiles.first(where: { $0.isActive }) {
                currentProfile = activeProfile
            } else if allProfiles.isEmpty {
                let defaultProfile = PlayerProfile.defaultProfile
                context.insert(defaultProfile)
                try context.save()
                allProfiles = [defaultProfile]
                currentProfile = defaultProfile
                defaultProfile.makeActive()
            }
            
            let treasureDescriptor = FetchDescriptor<Treasure>(
                sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
            )
            treasures = try context.fetch(treasureDescriptor)
            
            let userDescriptor = FetchDescriptor<User>()
            let users = try context.fetch(userDescriptor)
            currentUser = users.first
            
        } catch {
            print("Failed to load initial data: \(error)")
        }
    }
    
    func createProfile(name: String, emoji: String, color: String) async throws {
        guard let context = modelContext else { return }
        
        let newProfile = PlayerProfile(name: name, avatarEmoji: emoji, avatarColor: color)
        context.insert(newProfile)
        
        allProfiles.forEach { $0.deactivate() }
        newProfile.makeActive()
        
        try context.save()
        await loadInitialData()
        currentProfile = newProfile
    }
    
    func switchProfile(to profile: PlayerProfile) async throws {
        guard let context = modelContext else { return }
        
        allProfiles.forEach { $0.deactivate() }
        profile.makeActive()
        
        try context.save()
        currentProfile = profile
    }
    
    func deleteProfile(_ profile: PlayerProfile) async throws {
        guard let context = modelContext else { return }
        
        context.delete(profile)
        try context.save()
        
        await loadInitialData()
        
        if currentProfile?.id == profile.id {
            currentProfile = allProfiles.first
            currentProfile?.makeActive()
        }
    }
    
    func addTreasure(
        title: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        imageData: Data? = nil,
        emoji: String? = nil,
        difficulty: Int = 1,
        hints: [String] = [],
        isCustom: Bool = true
    ) async throws {
        guard let context = modelContext else { return }
        
        let treasure = Treasure(
            title: title,
            description: description,
            coordinate: coordinate,
            imageData: imageData,
            emoji: emoji,
            createdBy: currentProfile?.id.uuidString ?? currentUser?.id,
            difficulty: difficulty,
            hints: hints,
            isCustom: isCustom
        )
        
        context.insert(treasure)
        
        if let profile = currentProfile {
            if profile.treasuresCreated == nil {
                profile.treasuresCreated = []
            }
            profile.treasuresCreated?.append(treasure)
            profile.statistics?.recordTreasureCreated()
        }
        
        try context.save()
        treasures.append(treasure)
    }
    
    func collectTreasure(_ treasure: Treasure) async throws {
        guard let context = modelContext else { return }
        
        let userId = currentProfile?.id.uuidString ?? currentUser?.id ?? "unknown"
        treasure.markAsCollected(by: userId)
        
        if let profile = currentProfile {
            if profile.treasuresFound == nil {
                profile.treasuresFound = []
            }
            profile.treasuresFound?.append(treasure)
            profile.statistics?.recordTreasureFound(treasure: treasure)
            
            let newAchievements = profile.statistics?.checkAchievements() ?? []
            for achievement in newAchievements {
                NotificationManager.shared.scheduleAchievementNotification(achievementId: achievement)
            }
        }
        
        try context.save()
    }
    
    func updateTreasure(_ treasure: Treasure) async throws {
        guard let context = modelContext else { return }
        try context.save()
    }
    
    func deleteTreasure(_ treasure: Treasure) async throws {
        guard let context = modelContext else { return }
        
        context.delete(treasure)
        try context.save()
        
        if let index = treasures.firstIndex(where: { $0.id == treasure.id }) {
            treasures.remove(at: index)
        }
    }
    
    func nearbyTreasures(from location: CLLocation, radius: Double = 1000) -> [Treasure] {
        treasures.filter { treasure in
            let treasureLocation = CLLocation(
                latitude: treasure.latitude,
                longitude: treasure.longitude
            )
            return treasureLocation.distance(from: location) <= radius && !treasure.isCollected
        }
    }
    
    func userCreatedTreasures() -> [Treasure] {
        guard let userId = currentProfile?.id.uuidString ?? currentUser?.id else { return [] }
        return treasures.filter { $0.createdBy == userId }
    }
    
    func userCollectedTreasures() -> [Treasure] {
        guard let userId = currentProfile?.id.uuidString ?? currentUser?.id else { return [] }
        return treasures.filter { $0.collectedBy == userId }
    }
    
    func exportTreasures() async throws -> Data {
        let exportData = TreasureExportData(
            treasures: treasures.map { TreasureExportItem(from: $0) },
            profiles: allProfiles.map { ProfileExportItem(from: $0) },
            exportDate: Date(),
            version: "1.0"
        )
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(exportData)
    }
    
    func importTreasures(from data: Data) async throws {
        guard let context = modelContext else { return }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let importData = try decoder.decode(TreasureExportData.self, from: data)
        
        for treasureItem in importData.treasures {
            let treasure = Treasure(
                title: treasureItem.title,
                description: treasureItem.description,
                latitude: treasureItem.latitude,
                longitude: treasureItem.longitude,
                timestamp: treasureItem.timestamp,
                isCollected: treasureItem.isCollected,
                collectedBy: treasureItem.collectedBy,
                collectedAt: treasureItem.collectedAt,
                notes: treasureItem.notes,
                emoji: treasureItem.emoji,
                createdBy: treasureItem.createdBy,
                difficulty: treasureItem.difficulty,
                hints: treasureItem.hints,
                isCustom: treasureItem.isCustom
            )
            context.insert(treasure)
        }
        
        try context.save()
        await loadInitialData()
    }
    
    func migrateFromJSONStore() async throws {
        let documentsDirectory = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!
        let treasuresFile = documentsDirectory.appendingPathComponent("treasures.json")
        
        guard FileManager.default.fileExists(atPath: treasuresFile.path) else { return }
        
        do {
            let data = try Data(contentsOf: treasuresFile)
            try await importTreasures(from: data)
            
            try FileManager.default.removeItem(at: treasuresFile)
            print("Successfully migrated treasures from JSON storage")
        } catch {
            print("Failed to migrate from JSON: \(error)")
        }
    }
}

struct TreasureExportItem: Codable {
    let id: UUID
    let title: String
    let description: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let isCollected: Bool
    let collectedBy: String?
    let collectedAt: Date?
    let notes: String?
    let emoji: String?
    let createdBy: String?
    let difficulty: Int
    let hints: [String]
    let isCustom: Bool
    
    init(from treasure: Treasure) {
        self.id = treasure.id
        self.title = treasure.title
        self.description = treasure.treasureDescription
        self.latitude = treasure.latitude
        self.longitude = treasure.longitude
        self.timestamp = treasure.timestamp
        self.isCollected = treasure.isCollected
        self.collectedBy = treasure.collectedBy
        self.collectedAt = treasure.collectedAt
        self.notes = treasure.notes
        self.emoji = treasure.emoji
        self.createdBy = treasure.createdBy
        self.difficulty = treasure.difficulty
        self.hints = treasure.hints
        self.isCustom = treasure.isCustom
    }
}

struct ProfileExportItem: Codable {
    let id: UUID
    let name: String
    let avatarEmoji: String
    let avatarColor: String
    let treasuresFoundCount: Int
    let treasuresCreatedCount: Int
    let totalPoints: Int
    
    init(from profile: PlayerProfile) {
        self.id = profile.id
        self.name = profile.name
        self.avatarEmoji = profile.avatarEmoji
        self.avatarColor = profile.avatarColor
        self.treasuresFoundCount = profile.treasuresFound?.count ?? 0
        self.treasuresCreatedCount = profile.treasuresCreated?.count ?? 0
        self.totalPoints = profile.statistics?.totalPoints ?? 0
    }
}

struct TreasureExportData: Codable {
    let treasures: [TreasureExportItem]
    let profiles: [ProfileExportItem]
    let exportDate: Date
    let version: String
}