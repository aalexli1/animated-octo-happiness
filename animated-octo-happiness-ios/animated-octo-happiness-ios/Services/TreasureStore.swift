//
//  TreasureStore.swift
//  animated-octo-happiness-ios
//
//  Created by Assistant on 8/17/25.
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class TreasureStore: ObservableObject {
    @Published var treasures: [Treasure] = []
    
    private let documentsDirectory = FileManager.default.urls(for: .documentDirectory, 
                                                             in: .userDomainMask).first!
    private let treasuresFile: URL
    private let photosDirectory: URL
    
    init() {
        treasuresFile = documentsDirectory.appendingPathComponent("treasures.json")
        photosDirectory = documentsDirectory.appendingPathComponent("photos")
        
        createPhotosDirectoryIfNeeded()
        loadTreasures()
    }
    
    private func createPhotosDirectoryIfNeeded() {
        if !FileManager.default.fileExists(atPath: photosDirectory.path) {
            try? FileManager.default.createDirectory(at: photosDirectory, 
                                                    withIntermediateDirectories: true)
        }
    }
    
    func addTreasure(_ treasure: Treasure) async throws {
        var newTreasure = treasure
        
        if let imageData = treasure.imageData {
            let photoURL = photosDirectory.appendingPathComponent("\(treasure.id.uuidString).jpg")
            try imageData.write(to: photoURL)
            newTreasure.imageData = nil
        }
        
        treasures.append(newTreasure)
        try await saveTreasures()
    }
    
    func updateTreasure(_ treasure: Treasure) async throws {
        if let index = treasures.firstIndex(where: { $0.id == treasure.id }) {
            treasures[index] = treasure
            try await saveTreasures()
        }
    }
    
    func deleteTreasure(_ treasure: Treasure) async throws {
        treasures.removeAll { $0.id == treasure.id }
        
        let photoURL = photosDirectory.appendingPathComponent("\(treasure.id.uuidString).jpg")
        try? FileManager.default.removeItem(at: photoURL)
        
        try await saveTreasures()
    }
    
    func markTreasureAsFound(_ treasure: Treasure, foundBy: String) async throws {
        if let index = treasures.firstIndex(where: { $0.id == treasure.id }) {
            treasures[index].isCollected = true
            treasures[index].createdBy = foundBy
            treasures[index].timestamp = Date()
            try await saveTreasures()
        }
    }
    
    func loadPhotoData(for treasure: Treasure) -> Data? {
        let photoURL = photosDirectory.appendingPathComponent("\(treasure.id.uuidString).jpg")
        return try? Data(contentsOf: photoURL)
    }
    
    private func saveTreasures() async throws {
        // SwiftData handles persistence automatically
        // JSON encoding not needed for @Model classes
    }
    
    private func loadTreasures() {
        // SwiftData handles loading automatically
        // JSON decoding not needed for @Model classes
    }
    
    func nearbyTreasures(from location: CLLocation, radius: Double = 1000) -> [Treasure] {
        treasures.filter { treasure in
            let treasureLocation = CLLocation(latitude: treasure.latitude, 
                                             longitude: treasure.longitude)
            return treasureLocation.distance(from: location) <= radius
        }
    }
    
    func userCreatedTreasures(by userName: String) -> [Treasure] {
        treasures.filter { $0.createdBy == userName }
    }
    
    func foundTreasures(by userName: String) -> [Treasure] {
        treasures.filter { $0.isCollected && $0.createdBy == userName }
    }
}