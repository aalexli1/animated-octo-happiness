//
//  TreasureStore.swift
//  animated-octo-happiness-ios
//
//  Created by Auto Agent on 8/17/25.
//

import Foundation
import Combine
import CoreLocation

class TreasureStore: ObservableObject {
    @Published var treasures: [Treasure] = []
    
    private let userDefaults = UserDefaults.standard
    private let treasuresKey = "SavedTreasures"
    
    init() {
        loadTreasures()
    }
    
    func addTreasure(_ treasure: Treasure) {
        treasures.append(treasure)
        saveTreasures()
    }
    
    func removeTreasure(_ treasure: Treasure) {
        treasures.removeAll { $0.id == treasure.id }
        saveTreasures()
    }
    
    func updateTreasure(_ treasure: Treasure) {
        if let index = treasures.firstIndex(where: { $0.id == treasure.id }) {
            treasures[index] = treasure
            saveTreasures()
        }
    }
    
    func collectTreasure(_ treasure: Treasure) {
        if let index = treasures.firstIndex(where: { $0.id == treasure.id }) {
            treasures[index].isCollected = true
            saveTreasures()
        }
    }
    
    func createTreasure(at coordinate: CLLocationCoordinate2D, name: String, description: String) {
        let treasure = Treasure(
            name: name,
            description: description,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        addTreasure(treasure)
    }
    
    private func saveTreasures() {
        if let encoded = try? JSONEncoder().encode(treasures) {
            userDefaults.set(encoded, forKey: treasuresKey)
        }
    }
    
    private func loadTreasures() {
        if let data = userDefaults.data(forKey: treasuresKey),
           let decoded = try? JSONDecoder().decode([Treasure].self, from: data) {
            treasures = decoded
        } else {
            addSampleTreasures()
        }
    }
    
    private func addSampleTreasures() {
        let sampleTreasures = [
            Treasure(
                name: "Golden Gate Bridge View",
                description: "A beautiful view of the iconic bridge",
                latitude: 37.8199,
                longitude: -122.4783
            ),
            Treasure(
                name: "Fisherman's Wharf",
                description: "Sea lions and street performers await",
                latitude: 37.8080,
                longitude: -122.4177
            ),
            Treasure(
                name: "Coit Tower",
                description: "Panoramic views of the city",
                latitude: 37.8024,
                longitude: -122.4058
            )
        ]
        treasures = sampleTreasures
        saveTreasures()
    }
}