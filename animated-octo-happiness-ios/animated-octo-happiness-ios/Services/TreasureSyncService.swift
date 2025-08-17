//
//  TreasureSyncService.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import Foundation
import CoreLocation
import Combine
import UIKit

enum SyncError: LocalizedError {
    case noInternetConnection
    case serverError(String)
    case conflictResolutionFailed
    case imageUploadFailed
    case authenticationRequired
    case quotaExceeded
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection available"
        case .serverError(let message):
            return "Server error: \(message)"
        case .conflictResolutionFailed:
            return "Failed to resolve conflict between local and remote data"
        case .imageUploadFailed:
            return "Failed to upload image to storage"
        case .authenticationRequired:
            return "Authentication required to sync"
        case .quotaExceeded:
            return "Storage quota exceeded"
        case .invalidData:
            return "Invalid data format"
        }
    }
}

enum SyncStatus {
    case idle
    case syncing
    case uploading(progress: Double)
    case downloading(progress: Double)
    case completed
    case failed(Error)
}

struct TreasureDocument: Codable {
    let id: String
    let title: String
    let description: String
    let latitude: Double
    let longitude: Double
    let timestamp: Date
    let isCollected: Bool
    let notes: String?
    let imageURL: String?
    let emoji: String?
    let createdBy: String?
    let lastModified: Date
    let version: Int
    
    var location: GeoPoint {
        GeoPoint(latitude: latitude, longitude: longitude)
    }
}

struct GeoPoint: Codable {
    let latitude: Double
    let longitude: Double
}

protocol FirestoreProtocol {
    func collection(_ name: String) -> CollectionReferenceProtocol
    func batch() -> WriteBatchProtocol
}

protocol CollectionReferenceProtocol {
    func document(_ documentID: String?) -> DocumentReferenceProtocol
    func whereField(_ field: String, isEqualTo value: Any) -> QueryProtocol
    func whereField(_ field: String, isGreaterThan value: Any) -> QueryProtocol
    func whereField(_ field: String, isLessThan value: Any) -> QueryProtocol
    func order(by field: String, descending: Bool) -> QueryProtocol
    func limit(to limit: Int) -> QueryProtocol
}

protocol DocumentReferenceProtocol {
    var documentID: String { get }
    func setData(_ data: [String: Any], merge: Bool) async throws
    func getDocument() async throws -> DocumentSnapshotProtocol?
    func delete() async throws
    func updateData(_ fields: [String: Any]) async throws
}

protocol DocumentSnapshotProtocol {
    var exists: Bool { get }
    func data() -> [String: Any]?
}

protocol QueryProtocol {
    func getDocuments() async throws -> QuerySnapshotProtocol
}

protocol QuerySnapshotProtocol {
    var documents: [DocumentSnapshotProtocol] { get }
}

protocol WriteBatchProtocol {
    func setData(_ data: [String: Any], forDocument document: DocumentReferenceProtocol, merge: Bool)
    func updateData(_ fields: [String: Any], forDocument document: DocumentReferenceProtocol)
    func deleteDocument(_ document: DocumentReferenceProtocol)
    func commit() async throws
}

protocol StorageProtocol {
    func reference() -> StorageReferenceProtocol
}

protocol StorageReferenceProtocol {
    func child(_ path: String) -> StorageReferenceProtocol
    func putData(_ uploadData: Data, metadata: StorageMetadataProtocol?) async throws -> StorageMetadataProtocol
    func downloadURL() async throws -> URL
    func getData(maxSize: Int64) async throws -> Data
    func delete() async throws
}

protocol StorageMetadataProtocol {
    var contentType: String? { get set }
}

@MainActor
final class TreasureSyncService: ObservableObject {
    @Published private(set) var syncStatus: SyncStatus = .idle
    @Published private(set) var lastSyncDate: Date?
    @Published private(set) var pendingUploads: Int = 0
    @Published private(set) var pendingDownloads: Int = 0
    
    private var firestore: FirestoreProtocol?
    private var storage: StorageProtocol?
    private var treasureService: TreasureService
    private var currentUserID: String?
    
    private let collectionName = "treasures"
    private let imageBucketName = "treasure-images"
    private let maxImageSize: Int64 = 10 * 1024 * 1024 // 10MB
    private let maxRetries = 3
    private let retryDelay: TimeInterval = 2.0
    
    private var syncQueue = DispatchQueue(label: "com.app.treasuresync", qos: .background)
    private var cancellables = Set<AnyCancellable>()
    
    init(treasureService: TreasureService) {
        self.treasureService = treasureService
        loadLastSyncDate()
    }
    
    func configure(firestore: FirestoreProtocol, storage: StorageProtocol, userID: String) {
        self.firestore = firestore
        self.storage = storage
        self.currentUserID = userID
    }
    
    // MARK: - Public Methods
    
    func syncAll() async throws {
        guard let firestore = firestore else {
            throw SyncError.authenticationRequired
        }
        
        syncStatus = .syncing
        
        do {
            try await downloadNearbyTreasures()
            try await uploadLocalTreasures()
            try await syncCollectionStatus()
            
            lastSyncDate = Date()
            saveLastSyncDate()
            syncStatus = .completed
        } catch {
            syncStatus = .failed(error)
            throw error
        }
    }
    
    func uploadTreasure(_ treasure: Treasure) async throws {
        guard let firestore = firestore else {
            throw SyncError.authenticationRequired
        }
        
        pendingUploads += 1
        defer { pendingUploads -= 1 }
        
        var imageURL: String?
        if let imageData = treasure.imageData {
            syncStatus = .uploading(progress: 0.0)
            imageURL = try await uploadImage(imageData, treasureID: treasure.id.uuidString)
            syncStatus = .uploading(progress: 0.5)
        }
        
        let document = createDocument(from: treasure, imageURL: imageURL)
        let data = try encodeDocument(document)
        
        let collection = firestore.collection(collectionName)
        let docRef = collection.document(treasure.id.uuidString)
        
        try await withRetry(maxAttempts: maxRetries) {
            try await docRef.setData(data, merge: true)
        }
        
        syncStatus = .uploading(progress: 1.0)
    }
    
    func downloadTreasure(by id: String) async throws -> Treasure? {
        guard let firestore = firestore else {
            throw SyncError.authenticationRequired
        }
        
        pendingDownloads += 1
        defer { pendingDownloads -= 1 }
        
        syncStatus = .downloading(progress: 0.0)
        
        let collection = firestore.collection(collectionName)
        let docRef = collection.document(id)
        
        guard let snapshot = try await docRef.getDocument(),
              snapshot.exists,
              let data = snapshot.data() else {
            return nil
        }
        
        syncStatus = .downloading(progress: 0.5)
        
        let document = try decodeDocument(from: data)
        var imageData: Data?
        
        if let imageURL = document.imageURL {
            imageData = try await downloadImage(from: imageURL)
        }
        
        syncStatus = .downloading(progress: 1.0)
        
        return createTreasure(from: document, imageData: imageData)
    }
    
    func downloadNearbyTreasures(center: CLLocationCoordinate2D? = nil, radiusKm: Double = 10) async throws {
        guard let firestore = firestore else {
            throw SyncError.authenticationRequired
        }
        
        let currentLocation = center ?? CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        
        let minLat = currentLocation.latitude - (radiusKm / 111.0)
        let maxLat = currentLocation.latitude + (radiusKm / 111.0)
        let minLon = currentLocation.longitude - (radiusKm / (111.0 * cos(currentLocation.latitude * .pi / 180)))
        let maxLon = currentLocation.longitude + (radiusKm / (111.0 * cos(currentLocation.latitude * .pi / 180)))
        
        let collection = firestore.collection(collectionName)
        
        let querySnapshot = try await collection
            .whereField("latitude", isGreaterThan: minLat)
            .whereField("latitude", isLessThan: maxLat)
            .limit(to: 100)
            .getDocuments()
        
        let documents = querySnapshot.documents.compactMap { snapshot -> TreasureDocument? in
            guard let data = snapshot.data() else { return nil }
            return try? decodeDocument(from: data)
        }.filter { document in
            document.longitude >= minLon && document.longitude <= maxLon
        }
        
        for document in documents {
            await syncTreasureFromCloud(document)
        }
    }
    
    func deleteTreasure(_ treasureID: String) async throws {
        guard let firestore = firestore, let storage = storage else {
            throw SyncError.authenticationRequired
        }
        
        let collection = firestore.collection(collectionName)
        let docRef = collection.document(treasureID)
        
        if let snapshot = try await docRef.getDocument(),
           snapshot.exists,
           let data = snapshot.data(),
           let document = try? decodeDocument(from: data),
           let imageURL = document.imageURL {
            try await deleteImage(at: imageURL)
        }
        
        try await docRef.delete()
    }
    
    // MARK: - Private Methods
    
    private func uploadLocalTreasures() async throws {
        let localTreasures = try treasureService.fetchAllTreasures()
        
        for treasure in localTreasures {
            if shouldUploadTreasure(treasure) {
                try await uploadTreasure(treasure)
            }
        }
    }
    
    private func syncCollectionStatus() async throws {
        guard let firestore = firestore else { return }
        
        let collectedTreasures = try treasureService.fetchCollectedTreasures()
        let batch = firestore.batch()
        
        for treasure in collectedTreasures {
            let docRef = firestore.collection(collectionName).document(treasure.id.uuidString)
            batch.updateData(["isCollected": true, "lastModified": Date()], forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    private func syncTreasureFromCloud(_ document: TreasureDocument) async {
        do {
            if let existingTreasure = try treasureService.fetchTreasure(by: UUID(uuidString: document.id)!) {
                try await resolveConflict(local: existingTreasure, remote: document)
            } else {
                var imageData: Data?
                if let imageURL = document.imageURL {
                    imageData = try await downloadImage(from: imageURL)
                }
                
                let treasure = createTreasure(from: document, imageData: imageData)
                try treasureService.createTreasure(
                    title: treasure.title,
                    description: treasure.treasureDescription,
                    coordinate: treasure.coordinate,
                    notes: treasure.notes,
                    imageData: imageData
                )
            }
        } catch {
            print("Failed to sync treasure \(document.id): \(error)")
        }
    }
    
    private func resolveConflict(local: Treasure, remote: TreasureDocument) async throws {
        let localModified = local.timestamp
        let remoteModified = remote.lastModified
        
        if remoteModified > localModified {
            var imageData: Data?
            if let imageURL = remote.imageURL, imageURL != treasureImageURL(for: local.id.uuidString) {
                imageData = try await downloadImage(from: imageURL)
            }
            
            try treasureService.updateTreasure(
                local,
                title: remote.title,
                description: remote.description,
                coordinate: CLLocationCoordinate2D(latitude: remote.latitude, longitude: remote.longitude),
                isCollected: remote.isCollected,
                notes: remote.notes,
                imageData: imageData
            )
        } else if localModified > remoteModified {
            try await uploadTreasure(local)
        }
    }
    
    // MARK: - Image Handling
    
    private func uploadImage(_ imageData: Data, treasureID: String) async throws -> String {
        guard let storage = storage else {
            throw SyncError.authenticationRequired
        }
        
        let compressedData = compressImage(imageData)
        let imagePath = "\(imageBucketName)/\(treasureID).jpg"
        let storageRef = storage.reference().child(imagePath)
        
        let metadata = MockStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        _ = try await storageRef.putData(compressedData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    private func downloadImage(from urlString: String) async throws -> Data? {
        guard let storage = storage,
              let url = URL(string: urlString) else {
            return nil
        }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 2 else { return nil }
        
        let imagePath = pathComponents.suffix(2).joined(separator: "/")
        let storageRef = storage.reference().child(imagePath)
        
        return try await storageRef.getData(maxSize: maxImageSize)
    }
    
    private func deleteImage(at urlString: String) async throws {
        guard let storage = storage,
              let url = URL(string: urlString) else {
            return
        }
        
        let pathComponents = url.pathComponents
        guard pathComponents.count >= 2 else { return }
        
        let imagePath = pathComponents.suffix(2).joined(separator: "/")
        let storageRef = storage.reference().child(imagePath)
        
        try await storageRef.delete()
    }
    
    private func compressImage(_ imageData: Data) -> Data {
        guard let image = UIImage(data: imageData) else {
            return imageData
        }
        
        let maxDimension: CGFloat = 1024
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height)
        
        if scale < 1 {
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return resizedImage?.jpegData(compressionQuality: 0.8) ?? imageData
        }
        
        return image.jpegData(compressionQuality: 0.8) ?? imageData
    }
    
    // MARK: - Helper Methods
    
    private func createDocument(from treasure: Treasure, imageURL: String?) -> TreasureDocument {
        TreasureDocument(
            id: treasure.id.uuidString,
            title: treasure.title,
            description: treasure.treasureDescription,
            latitude: treasure.latitude,
            longitude: treasure.longitude,
            timestamp: treasure.timestamp,
            isCollected: treasure.isCollected,
            notes: treasure.notes,
            imageURL: imageURL,
            emoji: treasure.emoji,
            createdBy: treasure.createdBy ?? currentUserID,
            lastModified: Date(),
            version: 1
        )
    }
    
    private func createTreasure(from document: TreasureDocument, imageData: Data?) -> Treasure {
        Treasure(
            title: document.title,
            description: document.description,
            latitude: document.latitude,
            longitude: document.longitude,
            timestamp: document.timestamp,
            isCollected: document.isCollected,
            notes: document.notes,
            imageData: imageData,
            emoji: document.emoji,
            createdBy: document.createdBy
        )
    }
    
    private func encodeDocument(_ document: TreasureDocument) throws -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(document)
        guard let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw SyncError.invalidData
        }
        return dictionary
    }
    
    private func decodeDocument(from data: [String: Any]) throws -> TreasureDocument {
        let jsonData = try JSONSerialization.data(withJSONObject: data)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(TreasureDocument.self, from: jsonData)
    }
    
    private func shouldUploadTreasure(_ treasure: Treasure) -> Bool {
        return treasure.createdBy == nil || treasure.createdBy == currentUserID
    }
    
    private func treasureImageURL(for treasureID: String) -> String {
        return "https://storage.googleapis.com/\(imageBucketName)/\(treasureID).jpg"
    }
    
    private func withRetry<T>(maxAttempts: Int, delay: TimeInterval = 2.0, operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * Double(attempt) * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? SyncError.serverError("Unknown error after \(maxAttempts) attempts")
    }
    
    // MARK: - Persistence
    
    private func loadLastSyncDate() {
        lastSyncDate = UserDefaults.standard.object(forKey: "lastTreasureSyncDate") as? Date
    }
    
    private func saveLastSyncDate() {
        UserDefaults.standard.set(lastSyncDate, forKey: "lastTreasureSyncDate")
    }
}

// MARK: - Mock Implementations for Testing

class MockStorageMetadata: StorageMetadataProtocol {
    var contentType: String?
}

extension TreasureSyncService {
    static func mockForTesting(treasureService: TreasureService) -> TreasureSyncService {
        let service = TreasureSyncService(treasureService: treasureService)
        return service
    }
}