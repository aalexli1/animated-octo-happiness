//
//  SyncStatusView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI

struct SyncStatusView: View {
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var operationQueue: OfflineOperationQueue
    
    @State private var showDetails = false
    
    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text(statusText)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let subtitle = statusSubtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if operationQueue.getPendingOperationsCount() > 0 {
                Badge(count: operationQueue.getPendingOperationsCount())
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(statusBackgroundColor)
        .cornerRadius(8)
        .onTapGesture {
            showDetails.toggle()
        }
        .sheet(isPresented: $showDetails) {
            SyncDetailsView(
                syncManager: syncManager,
                networkMonitor: networkMonitor,
                operationQueue: operationQueue
            )
        }
    }
    
    private var statusIcon: some View {
        Group {
            if syncManager.isSyncing {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.7)
            } else if !networkMonitor.isConnected {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.orange)
            } else if operationQueue.getPendingOperationsCount() > 0 {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundColor(.blue)
            } else if syncManager.lastError != nil {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
    }
    
    private var statusText: String {
        if !networkMonitor.isConnected {
            return "Offline Mode"
        } else if syncManager.isSyncing {
            return "Syncing..."
        } else if let error = syncManager.lastError {
            return "Sync Failed"
        } else if operationQueue.getPendingOperationsCount() > 0 {
            return "Pending Sync"
        } else {
            return "All Synced"
        }
    }
    
    private var statusSubtitle: String? {
        if !networkMonitor.isConnected {
            return "Changes saved locally"
        } else if syncManager.isSyncing {
            return "\(Int(syncManager.syncProgress * 100))% complete"
        } else if operationQueue.getPendingOperationsCount() > 0 {
            return "\(operationQueue.getPendingOperationsCount()) operations pending"
        } else if let lastSync = syncManager.syncState.lastSyncDate {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .abbreviated
            return formatter.localizedString(for: lastSync, relativeTo: Date())
        }
        return nil
    }
    
    private var statusBackgroundColor: Color {
        if !networkMonitor.isConnected {
            return Color.orange.opacity(0.1)
        } else if syncManager.lastError != nil {
            return Color.red.opacity(0.1)
        } else if operationQueue.getPendingOperationsCount() > 0 {
            return Color.blue.opacity(0.1)
        } else {
            return Color.green.opacity(0.1)
        }
    }
}

struct Badge: View {
    let count: Int
    
    var body: some View {
        Text("\(count)")
            .font(.caption2)
            .fontWeight(.bold)
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue)
            .clipShape(Capsule())
    }
}

struct SyncDetailsView: View {
    @ObservedObject var syncManager: SyncManager
    @ObservedObject var networkMonitor: NetworkMonitor
    @ObservedObject var operationQueue: OfflineOperationQueue
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            List {
                Section("Network Status") {
                    HStack {
                        Text("Connection")
                        Spacer()
                        Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(networkMonitor.isConnected ? .green : .red)
                    }
                    
                    if let connectionType = networkMonitor.connectionType {
                        HStack {
                            Text("Type")
                            Spacer()
                            Text(connectionTypeString(connectionType))
                        }
                    }
                    
                    if networkMonitor.isExpensive {
                        HStack {
                            Text("Expensive Connection")
                            Spacer()
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Section("Sync Status") {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(syncManager.getSyncStatus())
                    }
                    
                    if let lastSync = syncManager.syncState.lastSyncDate {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(lastSync, style: .relative)
                        }
                    }
                    
                    HStack {
                        Text("Pending Operations")
                        Spacer()
                        Text("\(operationQueue.getPendingOperationsCount())")
                    }
                    
                    if syncManager.syncState.failedSyncs > 0 {
                        HStack {
                            Text("Failed Attempts")
                            Spacer()
                            Text("\(syncManager.syncState.failedSyncs)")
                                .foregroundColor(.red)
                        }
                    }
                }
                
                if !operationQueue.pendingOperations.isEmpty {
                    Section("Pending Operations") {
                        ForEach(operationQueue.pendingOperations) { operation in
                            OperationRow(operation: operation)
                        }
                    }
                }
                
                Section {
                    Button("Force Sync") {
                        Task {
                            await syncManager.forceSync()
                        }
                    }
                    .disabled(syncManager.isSyncing || !networkMonitor.isConnected)
                    
                    Button("Retry Failed Operations") {
                        operationQueue.retryFailedOperations()
                    }
                    .disabled(operationQueue.pendingOperations.filter { $0.status == .failed }.isEmpty)
                    
                    Button("Clear Queue", role: .destructive) {
                        operationQueue.clearQueue()
                    }
                    .disabled(operationQueue.pendingOperations.isEmpty)
                }
            }
            .navigationTitle("Sync Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func connectionTypeString(_ type: NWInterface.InterfaceType) -> String {
        switch type {
        case .wifi:
            return "Wi-Fi"
        case .cellular:
            return "Cellular"
        case .wiredEthernet:
            return "Ethernet"
        case .loopback:
            return "Loopback"
        case .other:
            return "Other"
        @unknown default:
            return "Unknown"
        }
    }
}

struct OperationRow: View {
    let operation: OfflineOperation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(operation.type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Text(operation.entityId.uuidString.prefix(8) + "...")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            statusBadge
        }
    }
    
    private var statusBadge: some View {
        Group {
            switch operation.status {
            case .pending:
                Text("Pending")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
                
            case .inProgress:
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(0.6)
                
            case .completed:
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
            case .failed:
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundColor(.red)
                    .font(.caption)
            }
        }
    }
}