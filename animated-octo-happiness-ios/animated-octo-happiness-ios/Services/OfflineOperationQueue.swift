//
//  OfflineOperationQueue.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import CoreLocation

enum OperationType: String, Codable {
    case create = "CREATE"
    case update = "UPDATE"
    case delete = "DELETE"
    case markCollected = "MARK_COLLECTED"
}

enum OperationStatus: String, Codable {
    case pending = "PENDING"
    case inProgress = "IN_PROGRESS"
    case completed = "COMPLETED"
    case failed = "FAILED"
}

struct OfflineOperation: Codable, Identifiable {
    let id: UUID
    let type: OperationType
    let entityId: UUID
    let entityType: String
    let payload: Data
    var status: OperationStatus
    let createdAt: Date
    var lastAttemptAt: Date?
    var attemptCount: Int
    var error: String?
    var version: Int
    
    init(
        type: OperationType,
        entityId: UUID,
        entityType: String = "Treasure",
        payload: Data,
        version: Int = 1
    ) {
        self.id = UUID()
        self.type = type
        self.entityId = entityId
        self.entityType = entityType
        self.payload = payload
        self.status = .pending
        self.createdAt = Date()
        self.lastAttemptAt = nil
        self.attemptCount = 0
        self.error = nil
        self.version = version
    }
}

struct TreasurePayload: Codable {
    let id: UUID
    let title: String
    let description: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let isCollected: Bool
    let notes: String?
    let emoji: String?
    let createdBy: String?
    let version: Int
    
    init(from treasure: Treasure, version: Int = 1) {
        self.id = treasure.id
        self.title = treasure.title
        self.description = treasure.treasureDescription
        self.latitude = treasure.latitude
        self.longitude = treasure.longitude
        self.timestamp = treasure.timestamp
        self.isCollected = treasure.isCollected
        self.notes = treasure.notes
        self.emoji = treasure.emoji
        self.createdBy = treasure.createdBy
        self.version = version
    }
}

@MainActor
final class OfflineOperationQueue: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let queueKey = "OfflineOperationQueue"
    private let maxRetries = 5
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    @Published private(set) var pendingOperations: [OfflineOperation] = []
    @Published private(set) var isProcessing: Bool = false
    @Published private(set) var syncStatus: String = "Ready"
    
    private var networkMonitor: NetworkMonitor
    private var processingTask: Task<Void, Never>?
    
    init(networkMonitor: NetworkMonitor = .shared) {
        self.networkMonitor = networkMonitor
        loadQueue()
        setupNetworkMonitoring()
    }
    
    private func setupNetworkMonitoring() {
        networkMonitor.onStatusChange { [weak self] status in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if status == .connected && !self.pendingOperations.isEmpty {
                    await self.processQueue()
                }
            }
        }
    }
    
    private func loadQueue() {
        guard let data = userDefaults.data(forKey: queueKey),
              let operations = try? decoder.decode([OfflineOperation].self, from: data) else {
            pendingOperations = []
            return
        }
        
        pendingOperations = operations.filter { $0.status != .completed }
    }
    
    private func saveQueue() {
        guard let data = try? encoder.encode(pendingOperations) else { return }
        userDefaults.set(data, forKey: queueKey)
    }
    
    func enqueue(
        type: OperationType,
        entityId: UUID,
        payload: TreasurePayload
    ) {
        guard let payloadData = try? encoder.encode(payload) else { return }
        
        let operation = OfflineOperation(
            type: type,
            entityId: entityId,
            payload: payloadData,
            version: payload.version
        )
        
        pendingOperations.append(operation)
        saveQueue()
        
        if networkMonitor.isConnected {
            Task {
                await processQueue()
            }
        }
    }
    
    func enqueueCreateTreasure(_ treasure: Treasure) {
        let payload = TreasurePayload(from: treasure)
        enqueue(type: .create, entityId: treasure.id, payload: payload)
    }
    
    func enqueueUpdateTreasure(_ treasure: Treasure) {
        let payload = TreasurePayload(from: treasure)
        enqueue(type: .update, entityId: treasure.id, payload: payload)
    }
    
    func enqueueDeleteTreasure(id: UUID) {
        guard let payloadData = try? encoder.encode(["id": id.uuidString]) else { return }
        
        let operation = OfflineOperation(
            type: .delete,
            entityId: id,
            payload: payloadData
        )
        
        pendingOperations.append(operation)
        saveQueue()
        
        if networkMonitor.isConnected {
            Task {
                await processQueue()
            }
        }
    }
    
    func enqueueMarkAsCollected(treasureId: UUID) {
        guard let payloadData = try? encoder.encode(["id": treasureId.uuidString, "isCollected": true]) else { return }
        
        let operation = OfflineOperation(
            type: .markCollected,
            entityId: treasureId,
            payload: payloadData
        )
        
        pendingOperations.append(operation)
        saveQueue()
        
        if networkMonitor.isConnected {
            Task {
                await processQueue()
            }
        }
    }
    
    func processQueue() async {
        guard !isProcessing && networkMonitor.isConnected else { return }
        
        isProcessing = true
        syncStatus = "Syncing..."
        
        for index in pendingOperations.indices {
            guard pendingOperations[index].status != .completed else { continue }
            
            pendingOperations[index].status = .inProgress
            pendingOperations[index].lastAttemptAt = Date()
            pendingOperations[index].attemptCount += 1
            
            do {
                try await processOperation(pendingOperations[index])
                pendingOperations[index].status = .completed
                syncStatus = "Synced"
            } catch {
                pendingOperations[index].status = .failed
                pendingOperations[index].error = error.localizedDescription
                
                if pendingOperations[index].attemptCount >= maxRetries {
                    pendingOperations[index].status = .failed
                    syncStatus = "Sync failed"
                } else {
                    pendingOperations[index].status = .pending
                    let backoffDelay = calculateBackoffDelay(attemptCount: pendingOperations[index].attemptCount)
                    try? await Task.sleep(nanoseconds: UInt64(backoffDelay * 1_000_000_000))
                }
            }
        }
        
        pendingOperations.removeAll { $0.status == .completed }
        saveQueue()
        
        isProcessing = false
        syncStatus = pendingOperations.isEmpty ? "All synced" : "Pending sync"
    }
    
    private func processOperation(_ operation: OfflineOperation) async throws {
        // This would normally call your backend API
        // For now, we'll simulate the network call
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 second delay
        
        // In a real implementation, you would:
        // 1. Decode the payload
        // 2. Make the appropriate API call based on operation type
        // 3. Handle the response
        // 4. Update local data if needed
        
        switch operation.type {
        case .create:
            // POST /api/treasures
            break
        case .update:
            // PUT /api/treasures/{id}
            break
        case .delete:
            // DELETE /api/treasures/{id}
            break
        case .markCollected:
            // PATCH /api/treasures/{id}/collect
            break
        }
    }
    
    private func calculateBackoffDelay(attemptCount: Int) -> TimeInterval {
        let baseDelay: TimeInterval = 2.0
        let maxDelay: TimeInterval = 300.0 // 5 minutes
        
        let delay = min(baseDelay * pow(2.0, Double(attemptCount - 1)), maxDelay)
        let jitter = Double.random(in: 0...1) * delay * 0.1
        
        return delay + jitter
    }
    
    func clearQueue() {
        pendingOperations.removeAll()
        saveQueue()
        syncStatus = "Queue cleared"
    }
    
    func retryFailedOperations() {
        for index in pendingOperations.indices {
            if pendingOperations[index].status == .failed {
                pendingOperations[index].status = .pending
                pendingOperations[index].attemptCount = 0
                pendingOperations[index].error = nil
            }
        }
        saveQueue()
        
        if networkMonitor.isConnected {
            Task {
                await processQueue()
            }
        }
    }
    
    func getPendingOperationsCount() -> Int {
        return pendingOperations.filter { $0.status == .pending || $0.status == .inProgress }.count
    }
}