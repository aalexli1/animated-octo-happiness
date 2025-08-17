//
//  NetworkMonitor.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import Network
import Combine

enum NetworkStatus {
    case connected
    case disconnected
    case unknown
}

@MainActor
final class NetworkMonitor: ObservableObject {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published private(set) var status: NetworkStatus = .unknown
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var connectionType: NWInterface.InterfaceType?
    @Published private(set) var isExpensive: Bool = false
    @Published private(set) var isConstrained: Bool = false
    
    private var statusChangeHandlers: [(NetworkStatus) -> Void] = []
    
    static let shared = NetworkMonitor()
    
    private init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                let previousStatus = self.status
                
                if path.status == .satisfied {
                    self.status = .connected
                    self.isConnected = true
                } else {
                    self.status = .disconnected
                    self.isConnected = false
                }
                
                self.isExpensive = path.isExpensive
                self.isConstrained = path.isConstrained
                
                if path.usesInterfaceType(.wifi) {
                    self.connectionType = .wifi
                } else if path.usesInterfaceType(.cellular) {
                    self.connectionType = .cellular
                } else if path.usesInterfaceType(.wiredEthernet) {
                    self.connectionType = .wiredEthernet
                } else {
                    self.connectionType = nil
                }
                
                if previousStatus != self.status {
                    self.notifyStatusChange(self.status)
                }
            }
        }
        
        monitor.start(queue: queue)
    }
    
    private func stopMonitoring() {
        monitor.cancel()
    }
    
    func onStatusChange(_ handler: @escaping (NetworkStatus) -> Void) {
        statusChangeHandlers.append(handler)
    }
    
    private func notifyStatusChange(_ status: NetworkStatus) {
        for handler in statusChangeHandlers {
            handler(status)
        }
    }
    
    func checkConnectivity() -> Bool {
        return isConnected
    }
    
    func waitForConnectivity(timeout: TimeInterval = 30) async -> Bool {
        if isConnected {
            return true
        }
        
        let startTime = Date()
        
        while Date().timeIntervalSince(startTime) < timeout {
            if isConnected {
                return true
            }
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        }
        
        return false
    }
}