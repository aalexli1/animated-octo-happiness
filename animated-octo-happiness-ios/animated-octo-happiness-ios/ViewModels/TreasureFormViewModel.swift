//
//  TreasureFormViewModel.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftUI
import CoreLocation
import Observation

@Observable
final class TreasureFormViewModel {
    var title = ""
    var description = ""
    var notes = ""
    var latitude = ""
    var longitude = ""
    var isCollected = false
    var imageData: Data?
    
    var titleError: String?
    var descriptionError: String?
    var coordinateError: String?
    
    var isValid: Bool {
        validateTitle() && validateDescription() && validateCoordinates()
    }
    
    var coordinate: CLLocationCoordinate2D? {
        guard let lat = Double(latitude),
              let lon = Double(longitude) else {
            return nil
        }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
    
    init() {}
    
    init(treasure: Treasure) {
        self.title = treasure.title
        self.description = treasure.treasureDescription
        self.notes = treasure.notes ?? ""
        self.latitude = String(treasure.latitude)
        self.longitude = String(treasure.longitude)
        self.isCollected = treasure.isCollected
        self.imageData = treasure.imageData
    }
    
    func setCurrentLocation(_ coordinate: CLLocationCoordinate2D) {
        latitude = String(format: "%.6f", coordinate.latitude)
        longitude = String(format: "%.6f", coordinate.longitude)
        _ = validateCoordinates()
    }
    
    @discardableResult
    func validateTitle() -> Bool {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            titleError = "Title is required"
            return false
        } else if trimmed.count > 100 {
            titleError = "Title must be 100 characters or less"
            return false
        }
        
        titleError = nil
        return true
    }
    
    @discardableResult
    func validateDescription() -> Bool {
        let trimmed = description.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.isEmpty {
            descriptionError = "Description is required"
            return false
        } else if trimmed.count > 500 {
            descriptionError = "Description must be 500 characters or less"
            return false
        }
        
        descriptionError = nil
        return true
    }
    
    @discardableResult
    func validateCoordinates() -> Bool {
        guard let lat = Double(latitude),
              let lon = Double(longitude) else {
            coordinateError = "Invalid coordinate format"
            return false
        }
        
        if lat < -90 || lat > 90 {
            coordinateError = "Latitude must be between -90 and 90"
            return false
        }
        
        if lon < -180 || lon > 180 {
            coordinateError = "Longitude must be between -180 and 180"
            return false
        }
        
        coordinateError = nil
        return true
    }
    
    func reset() {
        title = ""
        description = ""
        notes = ""
        latitude = ""
        longitude = ""
        isCollected = false
        imageData = nil
        titleError = nil
        descriptionError = nil
        coordinateError = nil
    }
}