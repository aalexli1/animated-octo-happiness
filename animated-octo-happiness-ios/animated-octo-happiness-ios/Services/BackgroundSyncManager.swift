//
//  BackgroundSyncManager.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import BackgroundTasks
import SwiftData

final class BackgroundSyncManager {
    static let shared = BackgroundSyncManager()
    
    private let syncTaskIdentifier = "com.animatedoctohappiness.sync"
    private let refreshTaskIdentifier = "com.animatedoctohappiness.refresh"
    
    private init() {}
    
    func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: syncTaskIdentifier,
            using: nil
        ) { task in
            self.handleSyncTask(task as! BGProcessingTask)
        }
        
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: refreshTaskIdentifier,
            using: nil
        ) { task in
            self.handleRefreshTask(task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundSync() {
        let request = BGProcessingTaskRequest(identifier: syncTaskIdentifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule background sync: \(error)")
        }
    }
    
    func scheduleAppRefresh() {
        let request = BGAppRefreshTaskRequest(identifier: refreshTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 30 * 60) // 30 minutes
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Failed to schedule app refresh: \(error)")
        }
    }
    
    private func handleSyncTask(_ task: BGProcessingTask) {
        // Schedule the next sync
        scheduleBackgroundSync()
        
        task.expirationHandler = {
            // Clean up any ongoing sync
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                // Perform sync operations
                await performBackgroundSync()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    private func handleRefreshTask(_ task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleAppRefresh()
        
        task.expirationHandler = {
            task.setTaskCompleted(success: false)
        }
        
        Task {
            do {
                // Perform quick refresh operations
                await performQuickRefresh()
                task.setTaskCompleted(success: true)
            } catch {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    @MainActor
    private func performBackgroundSync() async {
        guard let modelContainer = try? ModelContainer(for: Treasure.self) else { return }
        let modelContext = modelContainer.mainContext
        
        let networkMonitor = NetworkMonitor.shared
        let operationQueue = OfflineOperationQueue(networkMonitor: networkMonitor)
        let syncManager = SyncManager(
            modelContext: modelContext,
            networkMonitor: networkMonitor,
            operationQueue: operationQueue
        )
        
        // Wait for network connectivity
        guard await networkMonitor.waitForConnectivity(timeout: 10) else { return }
        
        // Perform sync
        await syncManager.performSync()
    }
    
    @MainActor
    private func performQuickRefresh() async {
        guard let modelContainer = try? ModelContainer(for: Treasure.self) else { return }
        let modelContext = modelContainer.mainContext
        
        let networkMonitor = NetworkMonitor.shared
        guard networkMonitor.isConnected else { return }
        
        // Perform quick operations like checking for new treasures
        // This should be a lightweight operation
        
        // Example: Check for new treasures near current location
        // let nearbyTreasures = await fetchNearbyTreasures()
        // await updateLocalDatabase(with: nearbyTreasures)
    }
    
    func cancelAllBackgroundTasks() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: syncTaskIdentifier)
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: refreshTaskIdentifier)
    }
}

extension BackgroundSyncManager {
    func simulateBackgroundSync() {
        #if DEBUG
        Task {
            await performBackgroundSync()
        }
        #endif
    }
    
    func simulateAppRefresh() {
        #if DEBUG
        Task {
            await performQuickRefresh()
        }
        #endif
    }
}