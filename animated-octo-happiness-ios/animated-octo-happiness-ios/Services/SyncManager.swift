//
//  SyncManager.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import Combine

enum ConflictResolutionStrategy {
    case clientWins
    case serverWins
    case lastWriteWins
    case merge
}

enum SyncError: LocalizedError {
    case networkUnavailable
    case conflictDetected(String)
    case syncInProgress
    case dataCorruption
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkUnavailable:
            return "Network is unavailable. Changes will be synced when connection is restored."
        case .conflictDetected(let message):
            return "Conflict detected: \(message)"
        case .syncInProgress:
            return "Sync is already in progress"
        case .dataCorruption:
            return "Data corruption detected"
        case .serverError(let message):
            return "Server error: \(message)"
        }
    }
}

struct SyncState {
    var lastSyncDate: Date?
    var syncInProgress: Bool = false
    var pendingChanges: Int = 0
    var failedSyncs: Int = 0
    var conflictCount: Int = 0
}

struct ConflictResolution {
    let localVersion: TreasurePayload
    let serverVersion: TreasurePayload
    let resolution: TreasurePayload
    let strategy: ConflictResolutionStrategy
}

@MainActor
final class SyncManager: ObservableObject {
    @Published private(set) var syncState = SyncState()
    @Published private(set) var isSyncing = false
    @Published private(set) var lastError: SyncError?
    @Published private(set) var syncProgress: Double = 0.0
    
    private let networkMonitor: NetworkMonitor
    private let operationQueue: OfflineOperationQueue
    private let modelContext: ModelContext
    private let userDefaults = UserDefaults.standard
    
    private var syncTask: Task<Void, Never>?
    private var syncTimer: Timer?
    private let syncInterval: TimeInterval = 30.0 // 30 seconds
    
    private let lastSyncKey = "LastSyncDate"
    private let syncVersionKey = "SyncVersion"
    
    init(
        modelContext: ModelContext,
        networkMonitor: NetworkMonitor = .shared,
        operationQueue: OfflineOperationQueue
    ) {
        self.modelContext = modelContext
        self.networkMonitor = networkMonitor
        self.operationQueue = operationQueue
        
        loadSyncState()
        setupNetworkMonitoring()
        startPeriodicSync()
    }
    
    deinit {
        syncTimer?.invalidate()
        syncTask?.cancel()
    }
    
    private func loadSyncState() {
        if let lastSyncDate = userDefaults.object(forKey: lastSyncKey) as? Date {
            syncState.lastSyncDate = lastSyncDate
        }
    }
    
    private func saveSyncState() {
        userDefaults.set(syncState.lastSyncDate, forKey: lastSyncKey)
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.onStatusChange { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if status == .connected {
                    await self.performSync()
                }
            }
        }
    }
    
    private func startPeriodicSync() {
        syncTimer = Timer.scheduledTimer(withTimeInterval: syncInterval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.networkMonitor.isConnected {
                    await self.performSync()
                }
            }
        }
    }
    
    func performSync() async {
        guard !isSyncing else {
            lastError = .syncInProgress
            return
        }
        
        guard networkMonitor.isConnected else {
            lastError = .networkUnavailable
            return
        }
        
        isSyncing = true
        syncState.syncInProgress = true
        syncProgress = 0.0
        lastError = nil
        
        do {
            // Step 1: Pull changes from server
            syncProgress = 0.2
            try await pullChanges()
            
            // Step 2: Process pending operations
            syncProgress = 0.4
            await operationQueue.processQueue()
            
            // Step 3: Push local changes
            syncProgress = 0.6
            try await pushChanges()
            
            // Step 4: Resolve conflicts if any
            syncProgress = 0.8
            try await resolveConflicts()
            
            // Step 5: Update sync state
            syncProgress = 1.0
            syncState.lastSyncDate = Date()
            syncState.failedSyncs = 0
            saveSyncState()
            
        } catch {
            syncState.failedSyncs += 1
            if let syncError = error as? SyncError {
                lastError = syncError
            } else {
                lastError = .serverError(error.localizedDescription)
            }
        }
        
        isSyncing = false
        syncState.syncInProgress = false
        syncState.pendingChanges = operationQueue.getPendingOperationsCount()
    }
    
    private func pullChanges() async throws {
        // In a real implementation, this would:
        // 1. Fetch changes from server since last sync
        // 2. Apply changes to local database
        // 3. Handle pagination for large datasets
        
        // Simulated network delay
        try await Task.sleep(nanoseconds: 500_000_000)
        
        // Example: Fetch treasures modified since last sync
        // let serverTreasures = try await api.fetchTreasures(since: syncState.lastSyncDate)
        // await applyServerChanges(serverTreasures)
    }
    
    private func pushChanges() async throws {
        // In a real implementation, this would:
        // 1. Gather all local changes
        // 2. Send them to the server
        // 3. Handle batch uploads for efficiency
        
        // Get all local treasures that need syncing
        let descriptor = FetchDescriptor<Treasure>()
        let localTreasures = try modelContext.fetch(descriptor)
        
        // Process each treasure
        for treasure in localTreasures {
            // Check if treasure needs syncing (has local changes)
            // This would normally check a "needsSync" flag or compare versions
            
            // Simulated network delay
            try await Task.sleep(nanoseconds: 100_000_000)
        }
    }
    
    private func resolveConflicts() async throws {
        // In a real implementation, this would:
        // 1. Detect conflicts between local and server data
        // 2. Apply resolution strategy
        // 3. Update both local and server with resolution
        
        syncState.conflictCount = 0
        
        // Example conflict resolution logic
        // let conflicts = detectConflicts()
        // for conflict in conflicts {
        //     let resolution = resolveConflict(conflict, strategy: .lastWriteWins)
        //     try await applyResolution(resolution)
        // }
    }
    
    func resolveConflict(
        local: TreasurePayload,
        server: TreasurePayload,
        strategy: ConflictResolutionStrategy = .lastWriteWins
    ) -> TreasurePayload {
        switch strategy {
        case .clientWins:
            return local
            
        case .serverWins:
            return server
            
        case .lastWriteWins:
            return local.timestamp > server.timestamp ? local : server
            
        case .merge:
            // Merge logic - combine non-conflicting fields
            var merged = local
            
            // If server has newer timestamp, use server's basic fields
            if server.timestamp > local.timestamp {
                merged.title = server.title
                merged.description = server.description
            }
            
            // Keep the most recent collection status
            if server.isCollected && !local.isCollected {
                merged.isCollected = true
            }
            
            // Merge notes by combining them
            if let serverNotes = server.notes,
               let localNotes = local.notes,
               serverNotes != localNotes {
                merged.notes = "\(localNotes)\n---\n\(serverNotes)"
            }
            
            return merged
        }
    }
    
    func forceSync() async {
        syncState.failedSyncs = 0
        await performSync()
    }
    
    func cancelSync() {
        syncTask?.cancel()
        isSyncing = false
        syncState.syncInProgress = false
    }
    
    func resetSyncState() {
        syncState = SyncState()
        userDefaults.removeObject(forKey: lastSyncKey)
        userDefaults.removeObject(forKey: syncVersionKey)
        operationQueue.clearQueue()
    }
    
    func getSyncStatus() -> String {
        if isSyncing {
            return "Syncing... \(Int(syncProgress * 100))%"
        } else if !networkMonitor.isConnected {
            return "Offline"
        } else if syncState.pendingChanges > 0 {
            return "\(syncState.pendingChanges) pending"
        } else if let lastSync = syncState.lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            return "Last sync: \(formatter.localizedString(for: lastSync, relativeTo: Date()))"
        } else {
            return "Not synced"
        }
    }
}