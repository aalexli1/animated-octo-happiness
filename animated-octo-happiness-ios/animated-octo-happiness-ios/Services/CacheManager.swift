//
//  CacheManager.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import SwiftUI

struct CachePolicy {
    let maxAge: TimeInterval
    let maxSize: Int64 // in bytes
    let maxItems: Int
}

enum CacheType {
    case images
    case treasureData
    case mapTiles
    case arAssets
    
    var policy: CachePolicy {
        switch self {
        case .images:
            return CachePolicy(
                maxAge: 7 * 24 * 60 * 60, // 7 days
                maxSize: 100 * 1024 * 1024, // 100 MB
                maxItems: 500
            )
        case .treasureData:
            return CachePolicy(
                maxAge: 24 * 60 * 60, // 1 day
                maxSize: 10 * 1024 * 1024, // 10 MB
                maxItems: 1000
            )
        case .mapTiles:
            return CachePolicy(
                maxAge: 30 * 24 * 60 * 60, // 30 days
                maxSize: 200 * 1024 * 1024, // 200 MB
                maxItems: 2000
            )
        case .arAssets:
            return CachePolicy(
                maxAge: 14 * 24 * 60 * 60, // 14 days
                maxSize: 50 * 1024 * 1024, // 50 MB
                maxItems: 100
            )
        }
    }
}

struct CacheEntry: Codable {
    let key: String
    let data: Data
    let timestamp: Date
    let size: Int64
    let version: Int
}

@MainActor
final class CacheManager: ObservableObject {
    static let shared = CacheManager()
    
    @Published private(set) var totalCacheSize: Int64 = 0
    @Published private(set) var cacheItemCount: Int = 0
    
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let metadataFile: URL
    private var cacheMetadata: [String: CacheMetadata] = [:]
    
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    struct CacheMetadata: Codable {
        let key: String
        let type: String
        let size: Int64
        let timestamp: Date
        let version: Int
        let accessCount: Int
        var lastAccessDate: Date
    }
    
    private init() {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.cacheDirectory = documentsPath.appendingPathComponent("OfflineCache")
        self.metadataFile = cacheDirectory.appendingPathComponent("metadata.json")
        
        setupCache()
        loadMetadata()
        calculateCacheSize()
    }
    
    private func setupCache() {
        if !fileManager.fileExists(atPath: cacheDirectory.path) {
            try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        }
    }
    
    private func loadMetadata() {
        guard fileManager.fileExists(atPath: metadataFile.path),
              let data = try? Data(contentsOf: metadataFile),
              let metadata = try? decoder.decode([String: CacheMetadata].self, from: data) else {
            cacheMetadata = [:]
            return
        }
        cacheMetadata = metadata
    }
    
    private func saveMetadata() {
        guard let data = try? encoder.encode(cacheMetadata) else { return }
        try? data.write(to: metadataFile)
    }
    
    private func calculateCacheSize() {
        totalCacheSize = 0
        cacheItemCount = 0
        
        guard let files = try? fileManager.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.fileSizeKey]) else { return }
        
        for file in files {
            if file.lastPathComponent == "metadata.json" { continue }
            
            if let attributes = try? fileManager.attributesOfItem(atPath: file.path),
               let fileSize = attributes[.size] as? Int64 {
                totalCacheSize += fileSize
                cacheItemCount += 1
            }
        }
    }
    
    func store(_ data: Data, forKey key: String, type: CacheType, version: Int = 1) {
        let fileName = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        // Check if we need to enforce cache limits
        enforcePolicy(for: type, newDataSize: Int64(data.count))
        
        // Write data to file
        do {
            try data.write(to: fileURL)
            
            // Update metadata
            let metadata = CacheMetadata(
                key: key,
                type: String(describing: type),
                size: Int64(data.count),
                timestamp: Date(),
                version: version,
                accessCount: 1,
                lastAccessDate: Date()
            )
            
            cacheMetadata[key] = metadata
            saveMetadata()
            
            // Update cache size
            totalCacheSize += Int64(data.count)
            cacheItemCount += 1
            
        } catch {
            print("Failed to cache data: \(error)")
        }
    }
    
    func retrieve(forKey key: String) -> Data? {
        let fileName = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        guard fileManager.fileExists(atPath: fileURL.path),
              let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        // Update access metadata
        if var metadata = cacheMetadata[key] {
            metadata.lastAccessDate = Date()
            var updatedMetadata = metadata
            updatedMetadata.accessCount += 1
            cacheMetadata[key] = updatedMetadata
            saveMetadata()
        }
        
        return data
    }
    
    func remove(forKey key: String) {
        let fileName = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        let fileURL = cacheDirectory.appendingPathComponent(fileName)
        
        if let metadata = cacheMetadata[key] {
            totalCacheSize -= metadata.size
            cacheItemCount -= 1
        }
        
        try? fileManager.removeItem(at: fileURL)
        cacheMetadata.removeValue(forKey: key)
        saveMetadata()
    }
    
    func clearCache(for type: CacheType? = nil) {
        if let type = type {
            // Clear specific type
            let typeString = String(describing: type)
            let keysToRemove = cacheMetadata.compactMap { key, metadata in
                metadata.type == typeString ? key : nil
            }
            
            for key in keysToRemove {
                remove(forKey: key)
            }
        } else {
            // Clear all cache
            try? fileManager.removeItem(at: cacheDirectory)
            setupCache()
            cacheMetadata.removeAll()
            saveMetadata()
            totalCacheSize = 0
            cacheItemCount = 0
        }
    }
    
    private func enforcePolicy(for type: CacheType, newDataSize: Int64) {
        let policy = type.policy
        let typeString = String(describing: type)
        
        // Get all entries for this type
        var typeEntries = cacheMetadata.filter { $0.value.type == typeString }
        
        // Calculate current size for this type
        let currentTypeSize = typeEntries.values.reduce(0) { $0 + $1.size }
        
        // Check if we need to make room
        if currentTypeSize + newDataSize > policy.maxSize || typeEntries.count >= policy.maxItems {
            // Sort by last access date (LRU)
            let sortedEntries = typeEntries.sorted { $0.value.lastAccessDate < $1.value.lastAccessDate }
            
            var sizeToFree = (currentTypeSize + newDataSize) - policy.maxSize
            var itemsToRemove = max(0, typeEntries.count - policy.maxItems + 1)
            
            for (key, metadata) in sortedEntries {
                if sizeToFree <= 0 && itemsToRemove <= 0 { break }
                
                remove(forKey: key)
                sizeToFree -= metadata.size
                itemsToRemove -= 1
            }
        }
        
        // Also remove expired entries
        let now = Date()
        let expiredEntries = typeEntries.filter { key, metadata in
            now.timeIntervalSince(metadata.timestamp) > policy.maxAge
        }
        
        for (key, _) in expiredEntries {
            remove(forKey: key)
        }
    }
    
    func pruneCache() {
        // Remove expired items from all cache types
        for type in [CacheType.images, .treasureData, .mapTiles, .arAssets] {
            enforcePolicy(for: type, newDataSize: 0)
        }
    }
    
    func getCacheInfo() -> (size: String, items: Int) {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        let sizeString = formatter.string(fromByteCount: totalCacheSize)
        return (sizeString, cacheItemCount)
    }
    
    func getVersion(forKey key: String) -> Int? {
        return cacheMetadata[key]?.version
    }
    
    func isVersionCurrent(forKey key: String, currentVersion: Int) -> Bool {
        guard let cachedVersion = getVersion(forKey: key) else { return false }
        return cachedVersion >= currentVersion
    }
}

extension CacheManager {
    func cacheImage(_ image: UIImage, forKey key: String) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        store(data, forKey: "image_\(key)", type: .images)
    }
    
    func getCachedImage(forKey key: String) -> UIImage? {
        guard let data = retrieve(forKey: "image_\(key)") else { return nil }
        return UIImage(data: data)
    }
    
    func cacheTreasureData(_ treasure: Treasure) {
        let payload = TreasurePayload(from: treasure)
        guard let data = try? encoder.encode(payload) else { return }
        store(data, forKey: "treasure_\(treasure.id.uuidString)", type: .treasureData, version: 1)
    }
    
    func getCachedTreasureData(id: UUID) -> TreasurePayload? {
        guard let data = retrieve(forKey: "treasure_\(id.uuidString)"),
              let payload = try? decoder.decode(TreasurePayload.self, from: data) else {
            return nil
        }
        return payload
    }
}