//
//  OfflineFirstDemo.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData
import CoreLocation

struct OfflineFirstDemoView: View {
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var operationQueue: OfflineOperationQueue
    @StateObject private var syncManager: SyncManager
    @StateObject private var cacheManager = CacheManager.shared
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingCreateSheet = false
    @State private var simulateOffline = false
    @State private var demoLog: [String] = []
    
    init() {
        let networkMonitor = NetworkMonitor.shared
        let operationQueue = OfflineOperationQueue(networkMonitor: networkMonitor)
        _operationQueue = StateObject(wrappedValue: operationQueue)
        
        // Note: SyncManager needs to be initialized with modelContext in onAppear
        _syncManager = StateObject(wrappedValue: SyncManager(
            modelContext: ModelContext(ModelContainer.preview),
            networkMonitor: networkMonitor,
            operationQueue: operationQueue
        ))
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Network Status Card
                NetworkStatusCard(
                    networkMonitor: networkMonitor,
                    simulateOffline: $simulateOffline
                )
                
                // Sync Status Card
                SyncStatusCard(
                    syncManager: syncManager,
                    operationQueue: operationQueue
                )
                
                // Demo Actions
                ScrollView {
                    VStack(spacing: 16) {
                        DemoActionCard(
                            title: "Create Offline",
                            description: "Create a treasure while offline",
                            systemImage: "plus.circle",
                            color: .blue
                        ) {
                            createOfflineTreasure()
                        }
                        
                        DemoActionCard(
                            title: "Simulate Conflict",
                            description: "Create a conflict scenario",
                            systemImage: "exclamationmark.triangle",
                            color: .orange
                        ) {
                            simulateConflict()
                        }
                        
                        DemoActionCard(
                            title: "Force Sync",
                            description: "Manually trigger sync",
                            systemImage: "arrow.triangle.2.circlepath",
                            color: .green
                        ) {
                            Task {
                                await syncManager.forceSync()
                                addLog("Manual sync triggered")
                            }
                        }
                        
                        DemoActionCard(
                            title: "Clear Cache",
                            description: "Clear all cached data",
                            systemImage: "trash",
                            color: .red
                        ) {
                            cacheManager.clearCache()
                            addLog("Cache cleared")
                        }
                        
                        DemoActionCard(
                            title: "Background Sync",
                            description: "Simulate background sync",
                            systemImage: "moon.circle",
                            color: .purple
                        ) {
                            BackgroundSyncManager.shared.simulateBackgroundSync()
                            addLog("Background sync simulated")
                        }
                    }
                    .padding()
                }
                
                // Demo Log
                if !demoLog.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Demo Log")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(demoLog.reversed(), id: \.self) { log in
                                    Text(log)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 150)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    }
                }
            }
            .navigationTitle("Offline-First Demo")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func createOfflineTreasure() {
        let service = OfflineTreasureService(
            modelContext: modelContext,
            operationQueue: operationQueue
        )
        
        do {
            let treasure = try service.createTreasure(
                title: "Offline Treasure \(Int.random(in: 100...999))",
                description: "Created while offline at \(Date().formatted())",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.7749 + Double.random(in: -0.01...0.01),
                    longitude: -122.4194 + Double.random(in: -0.01...0.01)
                )
            )
            addLog("Created offline treasure: \(treasure.title)")
        } catch {
            addLog("Failed to create treasure: \(error.localizedDescription)")
        }
    }
    
    private func simulateConflict() {
        // Create local and "server" versions of the same treasure
        let treasureId = UUID()
        
        let localPayload = TreasurePayload(
            from: Treasure(
                title: "Local Version",
                description: "Modified locally",
                latitude: 37.7749,
                longitude: -122.4194,
                timestamp: Date()
            )
        )
        
        let serverPayload = TreasurePayload(
            from: Treasure(
                title: "Server Version",
                description: "Modified on server",
                latitude: 37.7749,
                longitude: -122.4194,
                timestamp: Date().addingTimeInterval(-60)
            )
        )
        
        let resolution = syncManager.resolveConflict(
            local: localPayload,
            server: serverPayload,
            strategy: .lastWriteWins
        )
        
        addLog("Conflict resolved: \(resolution.title) wins")
    }
    
    private func addLog(_ message: String) {
        let timestamp = Date().formatted(date: .omitted, time: .shortened)
        demoLog.append("\(timestamp): \(message)")
    }
}

struct NetworkStatusCard: View {
    @ObservedObject var networkMonitor: NetworkMonitor
    @Binding var simulateOffline: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Network Status", systemImage: "wifi")
                    .font(.headline)
                Spacer()
                Toggle("Simulate Offline", isOn: $simulateOffline)
                    .toggleStyle(SwitchToggleStyle(tint: .orange))
            }
            
            HStack {
                Circle()
                    .fill(networkMonitor.isConnected && !simulateOffline ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(networkMonitor.isConnected && !simulateOffline ? "Connected" : "Offline")
                    .font(.subheadline)
                
                if let connectionType = networkMonitor.connectionType {
                    Text("(\(connectionTypeString(connectionType)))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if networkMonitor.isExpensive {
                Label("Expensive Connection", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private func connectionTypeString(_ type: NWInterface.InterfaceType) -> String {
        switch type {
        case .wifi: return "Wi-Fi"
        case .cellular: return "Cellular"
        case .wiredEthernet: return "Ethernet"
        default: return "Other"
        }
    }
}

struct SyncStatusCard: View {
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var operationQueue: OfflineOperationQueue
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Sync Status", systemImage: "arrow.triangle.2.circlepath")
                .font(.headline)
            
            HStack {
                Text("Pending Operations:")
                    .font(.subheadline)
                Spacer()
                Text("\(operationQueue.getPendingOperationsCount())")
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            
            if syncManager.isSyncing {
                ProgressView(value: syncManager.syncProgress) {
                    Text("Syncing... \(Int(syncManager.syncProgress * 100))%")
                        .font(.caption)
                }
            }
            
            if let lastSync = syncManager.syncState.lastSyncDate {
                HStack {
                    Text("Last Sync:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(lastSync, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct DemoActionCard: View {
    let title: String
    let description: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// MARK: - Preview Support

extension ModelContainer {
    static var preview: ModelContainer {
        do {
            let schema = Schema([Treasure.self])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            
            // Add sample data
            let context = container.mainContext
            
            for i in 1...5 {
                let treasure = Treasure(
                    title: "Sample Treasure \(i)",
                    description: "Description for treasure \(i)",
                    latitude: 37.7749 + Double(i) * 0.001,
                    longitude: -122.4194 + Double(i) * 0.001,
                    isCollected: i % 2 == 0
                )
                context.insert(treasure)
            }
            
            try context.save()
            return container
        } catch {
            fatalError("Failed to create preview container: \(error)")
        }
    }
}

#Preview {
    OfflineFirstDemoView()
        .modelContainer(ModelContainer.preview)
}