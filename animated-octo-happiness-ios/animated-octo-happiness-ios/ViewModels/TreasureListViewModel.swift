//
//  TreasureListViewModel.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftUI
import SwiftData
import CoreLocation
import Observation

@Observable
final class TreasureListViewModel {
    var treasures: [Treasure] = []
    var collectedTreasures: [Treasure] = []
    var uncollectedTreasures: [Treasure] = []
    var errorMessage: String?
    var isLoading = false
    var showingError = false
    var searchText = ""
    
    private let treasureService: TreasureService
    
    var filteredTreasures: [Treasure] {
        if searchText.isEmpty {
            return treasures
        } else {
            return treasures.filter { treasure in
                treasure.title.localizedCaseInsensitiveContains(searchText) ||
                treasure.treasureDescription.localizedCaseInsensitiveContains(searchText) ||
                (treasure.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var statistics: TreasureStatistics {
        TreasureStatistics(
            total: treasures.count,
            collected: collectedTreasures.count,
            uncollected: uncollectedTreasures.count
        )
    }
    
    init(modelContext: ModelContext) {
        self.treasureService = TreasureService(modelContext: modelContext)
    }
    
    @MainActor
    func loadTreasures() async {
        isLoading = true
        errorMessage = nil
        
        do {
            treasures = try treasureService.fetchAllTreasures()
            collectedTreasures = try treasureService.fetchCollectedTreasures()
            uncollectedTreasures = try treasureService.fetchUncollectedTreasures()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
        
        isLoading = false
    }
    
    @MainActor
    func createTreasure(
        title: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        notes: String? = nil,
        imageData: Data? = nil
    ) async -> Bool {
        do {
            _ = try treasureService.createTreasure(
                title: title,
                description: description,
                coordinate: coordinate,
                notes: notes,
                imageData: imageData
            )
            await loadTreasures()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            return false
        }
    }
    
    @MainActor
    func updateTreasure(
        _ treasure: Treasure,
        title: String? = nil,
        description: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        isCollected: Bool? = nil,
        notes: String? = nil,
        imageData: Data? = nil
    ) async -> Bool {
        do {
            try treasureService.updateTreasure(
                treasure,
                title: title,
                description: description,
                coordinate: coordinate,
                isCollected: isCollected,
                notes: notes,
                imageData: imageData
            )
            await loadTreasures()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            return false
        }
    }
    
    @MainActor
    func markAsCollected(_ treasure: Treasure) async {
        do {
            try treasureService.markAsCollected(treasure)
            await loadTreasures()
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
    
    @MainActor
    func deleteTreasure(_ treasure: Treasure) async -> Bool {
        do {
            try treasureService.deleteTreasure(treasure)
            await loadTreasures()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            return false
        }
    }
    
    @MainActor
    func deleteAllTreasures() async -> Bool {
        do {
            try treasureService.deleteAllTreasures()
            await loadTreasures()
            return true
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            return false
        }
    }
    
    @MainActor
    func findNearbyTreasures(
        coordinate: CLLocationCoordinate2D,
        radiusInMeters: Double = 1000
    ) async -> [Treasure] {
        do {
            return try treasureService.treasuresNearLocation(
                coordinate: coordinate,
                radiusInMeters: radiusInMeters
            )
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
            return []
        }
    }
}

struct TreasureStatistics {
    let total: Int
    let collected: Int
    let uncollected: Int
    
    var collectionRate: Double {
        guard total > 0 else { return 0 }
        return Double(collected) / Double(total)
    }
    
    var collectionPercentage: String {
        "\(Int(collectionRate * 100))%"
    }
}