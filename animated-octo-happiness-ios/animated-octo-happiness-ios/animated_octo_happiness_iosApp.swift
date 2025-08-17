//
//  animated_octo_happiness_iosApp.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/16/25.
//

import SwiftUI
import SwiftData
import BackgroundTasks

@main
struct animated_octo_happiness_iosApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var operationQueue: OfflineOperationQueue
    @StateObject private var syncManager: SyncManager
    @StateObject private var cacheManager = CacheManager.shared
    
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Treasure.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
            
            // Initialize offline-first components
            let networkMonitor = NetworkMonitor.shared
            let operationQueue = OfflineOperationQueue(networkMonitor: networkMonitor)
            let syncManager = SyncManager(
                modelContext: modelContainer.mainContext,
                networkMonitor: networkMonitor,
                operationQueue: operationQueue
            )
            
            _operationQueue = StateObject(wrappedValue: operationQueue)
            _syncManager = StateObject(wrappedValue: syncManager)
            
            // Register background tasks
            BackgroundSyncManager.shared.registerBackgroundTasks()
            
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(networkMonitor)
                .environmentObject(operationQueue)
                .environmentObject(syncManager)
                .environmentObject(cacheManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task { @MainActor in
                        locationManager.checkLocationServicesStatus()
                        await syncManager.performSync()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)) { _ in
                    BackgroundSyncManager.shared.scheduleBackgroundSync()
                    BackgroundSyncManager.shared.scheduleAppRefresh()
                }
        }
        .modelContainer(modelContainer)
    }
}