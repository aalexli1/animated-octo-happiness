//
//  OfflineTreasureService.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import CoreLocation

@MainActor
final class OfflineTreasureService: TreasureService {
    private let operationQueue: OfflineOperationQueue
    private let cacheManager: CacheManager
    private let networkMonitor: NetworkMonitor
    
    init(
        modelContext: ModelContext,
        operationQueue: OfflineOperationQueue,
        cacheManager: CacheManager = .shared,
        networkMonitor: NetworkMonitor = .shared
    ) {
        self.operationQueue = operationQueue
        self.cacheManager = cacheManager
        self.networkMonitor = networkMonitor
        super.init(modelContext: modelContext)
    }
    
    override func createTreasure(
        title: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        notes: String? = nil,
        imageData: Data? = nil
    ) throws -> Treasure {
        // Create treasure locally first
        let treasure = try super.createTreasure(
            title: title,
            description: description,
            coordinate: coordinate,
            notes: notes,
            imageData: imageData
        )
        
        // Cache the treasure data
        cacheManager.cacheTreasureData(treasure)
        
        // Queue for sync if online, otherwise it will sync when connection is restored
        if networkMonitor.isConnected {
            operationQueue.enqueueCreateTreasure(treasure)
        } else {
            // Store operation for later sync
            operationQueue.enqueueCreateTreasure(treasure)
        }
        
        // Cache image if provided
        if let imageData = imageData,
           let image = UIImage(data: imageData) {
            cacheManager.cacheImage(image, forKey: treasure.id.uuidString)
        }
        
        return treasure
    }
    
    override func updateTreasure(
        _ treasure: Treasure,
        title: String? = nil,
        description: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        isCollected: Bool? = nil,
        notes: String? = nil,
        imageData: Data? = nil
    ) throws {
        // Update locally first
        try super.updateTreasure(
            treasure,
            title: title,
            description: description,
            coordinate: coordinate,
            isCollected: isCollected,
            notes: notes,
            imageData: imageData
        )
        
        // Update cache
        cacheManager.cacheTreasureData(treasure)
        
        // Queue for sync
        operationQueue.enqueueUpdateTreasure(treasure)
        
        // Update cached image if provided
        if let imageData = imageData,
           let image = UIImage(data: imageData) {
            cacheManager.cacheImage(image, forKey: treasure.id.uuidString)
        }
    }
    
    override func markAsCollected(_ treasure: Treasure) throws {
        // Mark as collected locally
        try super.markAsCollected(treasure)
        
        // Update cache
        cacheManager.cacheTreasureData(treasure)
        
        // Queue for sync
        operationQueue.enqueueMarkAsCollected(treasureId: treasure.id)
    }
    
    override func deleteTreasure(_ treasure: Treasure) throws {
        let treasureId = treasure.id
        
        // Delete locally first
        try super.deleteTreasure(treasure)
        
        // Remove from cache
        cacheManager.remove(forKey: "treasure_\(treasureId.uuidString)")
        cacheManager.remove(forKey: "image_\(treasureId.uuidString)")
        
        // Queue for sync
        operationQueue.enqueueDeleteTreasure(id: treasureId)
    }
    
    func fetchTreasuresWithCache() throws -> [Treasure] {
        // Try to get from local database first
        let localTreasures = try fetchAllTreasures()
        
        // If offline, return local data
        guard networkMonitor.isConnected else {
            return localTreasures
        }
        
        // If online, check for updates
        // This would normally fetch from server and merge with local
        return localTreasures
    }
    
    func getCachedImage(for treasure: Treasure) -> UIImage? {
        // First check if treasure has image data
        if let imageData = treasure.imageData {
            return UIImage(data: imageData)
        }
        
        // Then check cache
        return cacheManager.getCachedImage(forKey: treasure.id.uuidString)
    }
    
    func preloadNearbyTreasures(coordinate: CLLocationCoordinate2D, radiusInMeters: Double) {
        Task {
            do {
                let nearbyTreasures = try await treasuresNearLocation(
                    coordinate: coordinate,
                    radiusInMeters: radiusInMeters
                )
                
                // Cache nearby treasures for offline access
                for treasure in nearbyTreasures {
                    cacheManager.cacheTreasureData(treasure)
                    
                    // Also cache images if they exist
                    if let imageData = treasure.imageData,
                       let image = UIImage(data: imageData) {
                        cacheManager.cacheImage(image, forKey: treasure.id.uuidString)
                    }
                }
            } catch {
                print("Failed to preload nearby treasures: \(error)")
            }
        }
    }
    
    func syncStatus() -> String {
        let pendingCount = operationQueue.getPendingOperationsCount()
        
        if !networkMonitor.isConnected {
            return "Offline - \(pendingCount) changes pending"
        } else if operationQueue.isProcessing {
            return "Syncing..."
        } else if pendingCount > 0 {
            return "\(pendingCount) changes pending sync"
        } else {
            return "All changes synced"
        }
    }
}