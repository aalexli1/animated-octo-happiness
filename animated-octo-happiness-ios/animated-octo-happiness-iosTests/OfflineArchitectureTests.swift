//
//  OfflineArchitectureTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import SwiftData
import Network
@testable import animated_octo_happiness_ios

final class OfflineArchitectureTests: XCTestCase {
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    var networkMonitor: NetworkMonitor!
    var operationQueue: OfflineOperationQueue!
    var syncManager: SyncManager!
    var cacheManager: CacheManager!
    var offlineService: OfflineTreasureService!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create in-memory model container for testing
        let schema = Schema([Treasure.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = modelContainer.mainContext
        
        // Initialize components
        await MainActor.run {
            networkMonitor = NetworkMonitor.shared
            operationQueue = OfflineOperationQueue(networkMonitor: networkMonitor)
            syncManager = SyncManager(
                modelContext: modelContext,
                networkMonitor: networkMonitor,
                operationQueue: operationQueue
            )
            cacheManager = CacheManager.shared
            offlineService = OfflineTreasureService(
                modelContext: modelContext,
                operationQueue: operationQueue,
                cacheManager: cacheManager,
                networkMonitor: networkMonitor
            )
        }
    }
    
    override func tearDown() async throws {
        await MainActor.run {
            operationQueue.clearQueue()
            cacheManager.clearCache()
            syncManager.resetSyncState()
        }
        
        modelContext = nil
        modelContainer = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Network Monitor Tests
    
    func testNetworkMonitorInitialization() async {
        await MainActor.run {
            XCTAssertNotNil(networkMonitor)
            XCTAssertTrue(networkMonitor.status == .connected || networkMonitor.status == .disconnected)
        }
    }
    
    func testNetworkConnectivityCheck() async {
        await MainActor.run {
            let isConnected = networkMonitor.checkConnectivity()
            XCTAssertEqual(isConnected, networkMonitor.isConnected)
        }
    }
    
    // MARK: - Operation Queue Tests
    
    func testEnqueueCreateOperation() async {
        await MainActor.run {
            let treasure = Treasure(
                title: "Test Treasure",
                description: "Test Description",
                latitude: 37.7749,
                longitude: -122.4194
            )
            
            operationQueue.enqueueCreateTreasure(treasure)
            
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), 1)
            XCTAssertFalse(operationQueue.pendingOperations.isEmpty)
            XCTAssertEqual(operationQueue.pendingOperations.first?.type, .create)
        }
    }
    
    func testEnqueueUpdateOperation() async {
        await MainActor.run {
            let treasure = Treasure(
                title: "Test Treasure",
                description: "Test Description",
                latitude: 37.7749,
                longitude: -122.4194
            )
            
            operationQueue.enqueueUpdateTreasure(treasure)
            
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), 1)
            XCTAssertEqual(operationQueue.pendingOperations.first?.type, .update)
        }
    }
    
    func testEnqueueDeleteOperation() async {
        await MainActor.run {
            let treasureId = UUID()
            
            operationQueue.enqueueDeleteTreasure(id: treasureId)
            
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), 1)
            XCTAssertEqual(operationQueue.pendingOperations.first?.type, .delete)
            XCTAssertEqual(operationQueue.pendingOperations.first?.entityId, treasureId)
        }
    }
    
    func testClearQueue() async {
        await MainActor.run {
            let treasure = Treasure(
                title: "Test Treasure",
                description: "Test Description",
                latitude: 37.7749,
                longitude: -122.4194
            )
            
            operationQueue.enqueueCreateTreasure(treasure)
            operationQueue.enqueueUpdateTreasure(treasure)
            
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), 2)
            
            operationQueue.clearQueue()
            
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), 0)
            XCTAssertTrue(operationQueue.pendingOperations.isEmpty)
        }
    }
    
    // MARK: - Sync Manager Tests
    
    func testSyncManagerInitialization() async {
        await MainActor.run {
            XCTAssertNotNil(syncManager)
            XCTAssertFalse(syncManager.isSyncing)
            XCTAssertEqual(syncManager.syncProgress, 0.0)
        }
    }
    
    func testConflictResolutionClientWins() async {
        await MainActor.run {
            let localPayload = TreasurePayload(
                from: Treasure(
                    title: "Local Title",
                    description: "Local Description",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    timestamp: Date()
                )
            )
            
            let serverPayload = TreasurePayload(
                from: Treasure(
                    title: "Server Title",
                    description: "Server Description",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    timestamp: Date().addingTimeInterval(-3600)
                )
            )
            
            let resolution = syncManager.resolveConflict(
                local: localPayload,
                server: serverPayload,
                strategy: .clientWins
            )
            
            XCTAssertEqual(resolution.title, "Local Title")
            XCTAssertEqual(resolution.description, "Local Description")
        }
    }
    
    func testConflictResolutionServerWins() async {
        await MainActor.run {
            let localPayload = TreasurePayload(
                from: Treasure(
                    title: "Local Title",
                    description: "Local Description",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    timestamp: Date()
                )
            )
            
            let serverPayload = TreasurePayload(
                from: Treasure(
                    title: "Server Title",
                    description: "Server Description",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    timestamp: Date().addingTimeInterval(-3600)
                )
            )
            
            let resolution = syncManager.resolveConflict(
                local: localPayload,
                server: serverPayload,
                strategy: .serverWins
            )
            
            XCTAssertEqual(resolution.title, "Server Title")
            XCTAssertEqual(resolution.description, "Server Description")
        }
    }
    
    func testConflictResolutionLastWriteWins() async {
        await MainActor.run {
            let olderDate = Date().addingTimeInterval(-3600)
            let newerDate = Date()
            
            let localPayload = TreasurePayload(
                from: Treasure(
                    title: "Local Title",
                    description: "Local Description",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    timestamp: newerDate
                )
            )
            
            let serverPayload = TreasurePayload(
                from: Treasure(
                    title: "Server Title",
                    description: "Server Description",
                    latitude: 37.7749,
                    longitude: -122.4194,
                    timestamp: olderDate
                )
            )
            
            let resolution = syncManager.resolveConflict(
                local: localPayload,
                server: serverPayload,
                strategy: .lastWriteWins
            )
            
            XCTAssertEqual(resolution.title, "Local Title")
            XCTAssertEqual(resolution.description, "Local Description")
        }
    }
    
    func testSyncStatusDisplay() async {
        await MainActor.run {
            let status = syncManager.getSyncStatus()
            XCTAssertFalse(status.isEmpty)
        }
    }
    
    // MARK: - Cache Manager Tests
    
    func testCacheStore() async {
        await MainActor.run {
            let testData = "Test Data".data(using: .utf8)!
            let key = "test_key"
            
            cacheManager.store(testData, forKey: key, type: .treasureData)
            
            let retrieved = cacheManager.retrieve(forKey: key)
            XCTAssertNotNil(retrieved)
            XCTAssertEqual(retrieved, testData)
        }
    }
    
    func testCacheRemove() async {
        await MainActor.run {
            let testData = "Test Data".data(using: .utf8)!
            let key = "test_key"
            
            cacheManager.store(testData, forKey: key, type: .treasureData)
            XCTAssertNotNil(cacheManager.retrieve(forKey: key))
            
            cacheManager.remove(forKey: key)
            XCTAssertNil(cacheManager.retrieve(forKey: key))
        }
    }
    
    func testCacheVersioning() async {
        await MainActor.run {
            let testData = "Test Data".data(using: .utf8)!
            let key = "test_key"
            let version = 2
            
            cacheManager.store(testData, forKey: key, type: .treasureData, version: version)
            
            XCTAssertEqual(cacheManager.getVersion(forKey: key), version)
            XCTAssertTrue(cacheManager.isVersionCurrent(forKey: key, currentVersion: 2))
            XCTAssertTrue(cacheManager.isVersionCurrent(forKey: key, currentVersion: 1))
            XCTAssertFalse(cacheManager.isVersionCurrent(forKey: key, currentVersion: 3))
        }
    }
    
    func testCacheClear() async {
        await MainActor.run {
            let testData = "Test Data".data(using: .utf8)!
            
            cacheManager.store(testData, forKey: "key1", type: .treasureData)
            cacheManager.store(testData, forKey: "key2", type: .images)
            
            cacheManager.clearCache(for: .treasureData)
            
            XCTAssertNil(cacheManager.retrieve(forKey: "key1"))
            XCTAssertNotNil(cacheManager.retrieve(forKey: "key2"))
            
            cacheManager.clearCache()
            
            XCTAssertNil(cacheManager.retrieve(forKey: "key2"))
        }
    }
    
    // MARK: - Offline Service Tests
    
    func testOfflineCreateTreasure() async throws {
        try await MainActor.run {
            let initialCount = operationQueue.getPendingOperationsCount()
            
            let treasure = try offlineService.createTreasure(
                title: "Offline Treasure",
                description: "Created while offline",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            )
            
            XCTAssertNotNil(treasure)
            XCTAssertEqual(treasure.title, "Offline Treasure")
            
            // Check that operation was queued
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), initialCount + 1)
            
            // Check that treasure was cached
            let cachedData = cacheManager.getCachedTreasureData(id: treasure.id)
            XCTAssertNotNil(cachedData)
            XCTAssertEqual(cachedData?.title, "Offline Treasure")
        }
    }
    
    func testOfflineUpdateTreasure() async throws {
        try await MainActor.run {
            let treasure = try offlineService.createTreasure(
                title: "Original Title",
                description: "Original Description",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            )
            
            let initialCount = operationQueue.getPendingOperationsCount()
            
            try offlineService.updateTreasure(
                treasure,
                title: "Updated Title",
                description: "Updated Description"
            )
            
            XCTAssertEqual(treasure.title, "Updated Title")
            XCTAssertEqual(treasure.treasureDescription, "Updated Description")
            
            // Check that update operation was queued
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), initialCount + 1)
            
            // Check that cache was updated
            let cachedData = cacheManager.getCachedTreasureData(id: treasure.id)
            XCTAssertEqual(cachedData?.title, "Updated Title")
        }
    }
    
    func testOfflineDeleteTreasure() async throws {
        try await MainActor.run {
            let treasure = try offlineService.createTreasure(
                title: "To Delete",
                description: "Will be deleted",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            )
            
            let treasureId = treasure.id
            operationQueue.clearQueue() // Clear the create operation
            
            try offlineService.deleteTreasure(treasure)
            
            // Check that delete operation was queued
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), 1)
            XCTAssertEqual(operationQueue.pendingOperations.first?.type, .delete)
            
            // Check that cache was cleared
            XCTAssertNil(cacheManager.getCachedTreasureData(id: treasureId))
        }
    }
    
    func testOfflineMarkAsCollected() async throws {
        try await MainActor.run {
            let treasure = try offlineService.createTreasure(
                title: "Uncollected",
                description: "Not yet collected",
                coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
            )
            
            operationQueue.clearQueue() // Clear the create operation
            
            try offlineService.markAsCollected(treasure)
            
            XCTAssertTrue(treasure.isCollected)
            
            // Check that operation was queued
            XCTAssertEqual(operationQueue.getPendingOperationsCount(), 1)
            XCTAssertEqual(operationQueue.pendingOperations.first?.type, .markCollected)
            
            // Check that cache was updated
            let cachedData = cacheManager.getCachedTreasureData(id: treasure.id)
            XCTAssertTrue(cachedData?.isCollected ?? false)
        }
    }
    
    // MARK: - Performance Tests
    
    func testLargeQueuePerformance() async {
        await MainActor.run {
            measure {
                for i in 0..<100 {
                    let treasure = Treasure(
                        title: "Treasure \(i)",
                        description: "Description \(i)",
                        latitude: 37.7749 + Double(i) * 0.001,
                        longitude: -122.4194 + Double(i) * 0.001
                    )
                    operationQueue.enqueueCreateTreasure(treasure)
                }
                
                XCTAssertEqual(operationQueue.getPendingOperationsCount(), 100)
            }
        }
    }
    
    func testCachePerformance() async {
        await MainActor.run {
            let testData = String(repeating: "x", count: 1000).data(using: .utf8)!
            
            measure {
                for i in 0..<100 {
                    let key = "performance_test_\(i)"
                    cacheManager.store(testData, forKey: key, type: .treasureData)
                    let _ = cacheManager.retrieve(forKey: key)
                }
            }
        }
    }
}