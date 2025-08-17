//
//  TreasureSyncService.swift
//  animated-octo-happiness-ios
//
//  Handles treasure synchronization with Firebase
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import CoreLocation
import Combine

@MainActor
class TreasureSyncService: ObservableObject {
    @Published var syncStatus: SyncStatus = .idle
    @Published var errorMessage: String?
    @Published var uploadProgress: Double = 0
    
    private let firestore = FirebaseConfig.shared.firestore
    private let storage = FirebaseConfig.shared.storage
    private let authService: AuthenticationService
    
    init(authService: AuthenticationService) {
        self.authService = authService
    }
    
    func createTreasure(_ treasure: CloudTreasure, imageData: Data? = nil) async throws -> String {
        guard let userId = authService.currentUser?.id else {
            throw TreasureSyncError.notAuthenticated
        }
        
        syncStatus = .uploading
        
        var treasureToSave = treasure
        
        if let imageData = imageData {
            let imageURL = try await uploadImage(imageData, treasureId: treasure.id ?? UUID().uuidString)
            treasureToSave.imageURL = imageURL
        }
        
        do {
            let documentRef = try await firestore.collection(FirebaseCollections.treasures)
                .addDocument(from: treasureToSave)
            
            try await updateUserStats(userId: userId, treasuresCreated: 1)
            
            syncStatus = .idle
            return documentRef.documentID
        } catch {
            syncStatus = .error
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func fetchNearbyTreasures(location: CLLocation, radiusKm: Double = 5.0) async throws -> [CloudTreasure] {
        syncStatus = .downloading
        
        let center = location.coordinate
        let lat = 0.009
        let lon = 0.009
        
        let minLat = center.latitude - (lat * radiusKm)
        let maxLat = center.latitude + (lat * radiusKm)
        let minLon = center.longitude - (lon * radiusKm)
        let maxLon = center.longitude + (lon * radiusKm)
        
        do {
            let snapshot = try await firestore.collection(FirebaseCollections.treasures)
                .whereField("latitude", isGreaterThanOrEqualTo: minLat)
                .whereField("latitude", isLessThanOrEqualTo: maxLat)
                .whereField("longitude", isGreaterThanOrEqualTo: minLon)
                .whereField("longitude", isLessThanOrEqualTo: maxLon)
                .getDocuments()
            
            let treasures = try snapshot.documents.compactMap { document in
                try document.data(as: CloudTreasure.self)
            }.filter { treasure in
                guard let userId = authService.currentUser?.id else { return false }
                
                switch treasure.visibility {
                case .public:
                    return true
                case .friends:
                    return treasure.createdBy == userId ||
                           authService.currentUser?.friends.contains(treasure.createdBy) ?? false
                case .private:
                    return treasure.createdBy == userId
                }
            }
            
            syncStatus = .idle
            return treasures
        } catch {
            syncStatus = .error
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func markTreasureAsCollected(treasureId: String) async throws {
        guard let user = authService.currentUser else {
            throw TreasureSyncError.notAuthenticated
        }
        
        do {
            try await firestore.collection(FirebaseCollections.treasures)
                .document(treasureId)
                .updateData([
                    "isCollected": true,
                    "collectedBy": user.id ?? "",
                    "collectedByName": user.displayName,
                    "collectedAt": FieldValue.serverTimestamp()
                ])
            
            try await updateUserStats(userId: user.id ?? "", treasuresFound: 1)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteTreasure(treasureId: String) async throws {
        guard let userId = authService.currentUser?.id else {
            throw TreasureSyncError.notAuthenticated
        }
        
        let document = try await firestore.collection(FirebaseCollections.treasures)
            .document(treasureId)
            .getDocument()
        
        guard let treasure = try? document.data(as: CloudTreasure.self),
              treasure.createdBy == userId else {
            throw TreasureSyncError.unauthorized
        }
        
        if let imageURL = treasure.imageURL {
            try await deleteImage(from: imageURL)
        }
        
        try await firestore.collection(FirebaseCollections.treasures)
            .document(treasureId)
            .delete()
        
        try await updateUserStats(userId: userId, treasuresCreated: -1)
    }
    
    private func uploadImage(_ imageData: Data, treasureId: String) async throws -> String {
        let path = "\(FirebaseStoragePaths.treasureImages)/\(treasureId).jpg"
        let storageRef = storage.reference().child(path)
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        
        let uploadTask = storageRef.putData(imageData, metadata: metadata)
        
        uploadTask.observe(.progress) { [weak self] snapshot in
            guard let progress = snapshot.progress else { return }
            Task { @MainActor in
                self?.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
            }
        }
        
        _ = try await uploadTask.data
        let downloadURL = try await storageRef.downloadURL()
        
        return downloadURL.absoluteString
    }
    
    private func deleteImage(from urlString: String) async throws {
        guard let url = URL(string: urlString) else { return }
        
        let path = url.path
            .replacingOccurrences(of: "/v0/b/", with: "")
            .components(separatedBy: "/o/")[1]
            .components(separatedBy: "?")[0]
            .removingPercentEncoding ?? ""
        
        let storageRef = storage.reference().child(path)
        try await storageRef.delete()
    }
    
    private func updateUserStats(userId: String, treasuresCreated: Int = 0, treasuresFound: Int = 0) async throws {
        var updates: [String: Any] = [:]
        
        if treasuresCreated != 0 {
            updates["treasuresCreated"] = FieldValue.increment(Int64(treasuresCreated))
        }
        
        if treasuresFound != 0 {
            updates["treasuresFound"] = FieldValue.increment(Int64(treasuresFound))
        }
        
        if !updates.isEmpty {
            try await firestore.collection(FirebaseCollections.users)
                .document(userId)
                .updateData(updates)
        }
    }
}

enum SyncStatus {
    case idle
    case uploading
    case downloading
    case syncing
    case error
}

enum TreasureSyncError: LocalizedError {
    case notAuthenticated
    case unauthorized
    case networkError
    case uploadFailed
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to sync treasures"
        case .unauthorized:
            return "You don't have permission to perform this action"
        case .networkError:
            return "Network error. Please check your connection"
        case .uploadFailed:
            return "Failed to upload treasure"
        }
    }
}