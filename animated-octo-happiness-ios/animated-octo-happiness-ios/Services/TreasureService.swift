//
//  TreasureService.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftData
import CoreLocation

enum TreasureServiceError: LocalizedError {
    case invalidTitle
    case invalidDescription
    case invalidCoordinates
    case treasureNotFound
    case persistenceError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidTitle:
            return "Title must be between 1 and 100 characters"
        case .invalidDescription:
            return "Description must be between 1 and 500 characters"
        case .invalidCoordinates:
            return "Invalid coordinates provided"
        case .treasureNotFound:
            return "Treasure not found"
        case .persistenceError(let message):
            return "Persistence error: \(message)"
        }
    }
}

@MainActor
final class TreasureService {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func createTreasure(
        title: String,
        description: String,
        coordinate: CLLocationCoordinate2D,
        notes: String? = nil,
        imageData: Data? = nil
    ) throws -> Treasure {
        guard Treasure.isValidTitle(title) else {
            throw TreasureServiceError.invalidTitle
        }
        
        guard Treasure.isValidDescription(description) else {
            throw TreasureServiceError.invalidDescription
        }
        
        guard Treasure.isValidCoordinate(
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        ) else {
            throw TreasureServiceError.invalidCoordinates
        }
        
        let treasure = Treasure(
            title: title,
            description: description,
            coordinate: coordinate,
            notes: notes,
            imageData: imageData
        )
        
        modelContext.insert(treasure)
        
        do {
            try modelContext.save()
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
        
        return treasure
    }
    
    func fetchAllTreasures() throws -> [Treasure] {
        let descriptor = FetchDescriptor<Treasure>(
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func fetchTreasure(by id: UUID) throws -> Treasure? {
        let predicate = #Predicate<Treasure> { treasure in
            treasure.id == id
        }
        
        let descriptor = FetchDescriptor<Treasure>(predicate: predicate)
        
        do {
            return try modelContext.fetch(descriptor).first
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func fetchCollectedTreasures() throws -> [Treasure] {
        let predicate = #Predicate<Treasure> { treasure in
            treasure.isCollected == true
        }
        
        let descriptor = FetchDescriptor<Treasure>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func fetchUncollectedTreasures() throws -> [Treasure] {
        let predicate = #Predicate<Treasure> { treasure in
            treasure.isCollected == false
        }
        
        let descriptor = FetchDescriptor<Treasure>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        
        do {
            return try modelContext.fetch(descriptor)
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func updateTreasure(
        _ treasure: Treasure,
        title: String? = nil,
        description: String? = nil,
        coordinate: CLLocationCoordinate2D? = nil,
        isCollected: Bool? = nil,
        notes: String? = nil,
        imageData: Data? = nil
    ) throws {
        if let title = title {
            guard Treasure.isValidTitle(title) else {
                throw TreasureServiceError.invalidTitle
            }
            treasure.title = title
        }
        
        if let description = description {
            guard Treasure.isValidDescription(description) else {
                throw TreasureServiceError.invalidDescription
            }
            treasure.treasureDescription = description
        }
        
        if let coordinate = coordinate {
            guard Treasure.isValidCoordinate(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            ) else {
                throw TreasureServiceError.invalidCoordinates
            }
            treasure.latitude = coordinate.latitude
            treasure.longitude = coordinate.longitude
        }
        
        if let isCollected = isCollected {
            treasure.isCollected = isCollected
        }
        
        if let notes = notes {
            treasure.notes = notes.isEmpty ? nil : notes
        }
        
        if let imageData = imageData {
            treasure.imageData = imageData
        }
        
        do {
            try modelContext.save()
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func markAsCollected(_ treasure: Treasure) throws {
        treasure.isCollected = true
        
        do {
            try modelContext.save()
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func deleteTreasure(_ treasure: Treasure) throws {
        modelContext.delete(treasure)
        
        do {
            try modelContext.save()
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func deleteAllTreasures() throws {
        do {
            try modelContext.delete(model: Treasure.self)
            try modelContext.save()
        } catch {
            throw TreasureServiceError.persistenceError(error.localizedDescription)
        }
    }
    
    func treasuresNearLocation(
        coordinate: CLLocationCoordinate2D,
        radiusInMeters: Double
    ) throws -> [Treasure] {
        let allTreasures = try fetchAllTreasures()
        
        return allTreasures.filter { treasure in
            let treasureLocation = CLLocation(
                latitude: treasure.latitude,
                longitude: treasure.longitude
            )
            let targetLocation = CLLocation(
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )
            
            return treasureLocation.distance(from: targetLocation) <= radiusInMeters
        }
    }
}