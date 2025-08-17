//
//  TreasureSyncServiceTests.swift
//  animated-octo-happiness-iosTests
//
//  Created on 8/17/25.
//

import XCTest
import CoreLocation
import SwiftData
@testable import animated_octo_happiness_ios

// MARK: - Mock Implementations

class MockFirestore: FirestoreProtocol {
    var collections: [String: MockCollectionReference] = [:]
    var shouldFail = false
    var failureError: Error?
    
    func collection(_ name: String) -> CollectionReferenceProtocol {
        if collections[name] == nil {
            collections[name] = MockCollectionReference()
        }
        return collections[name]!
    }
    
    func batch() -> WriteBatchProtocol {
        return MockWriteBatch(firestore: self)
    }
}

class MockCollectionReference: CollectionReferenceProtocol {
    var documents: [String: MockDocumentReference] = [:]
    var queries: [MockQuery] = []
    
    func document(_ documentID: String?) -> DocumentReferenceProtocol {
        let id = documentID ?? UUID().uuidString
        if documents[id] == nil {
            documents[id] = MockDocumentReference(documentID: id)
        }
        return documents[id]!
    }
    
    func whereField(_ field: String, isEqualTo value: Any) -> QueryProtocol {
        let query = MockQuery()
        queries.append(query)
        return query
    }
    
    func whereField(_ field: String, isGreaterThan value: Any) -> QueryProtocol {
        let query = MockQuery()
        queries.append(query)
        return query
    }
    
    func whereField(_ field: String, isLessThan value: Any) -> QueryProtocol {
        let query = MockQuery()
        queries.append(query)
        return query
    }
    
    func order(by field: String, descending: Bool) -> QueryProtocol {
        let query = MockQuery()
        queries.append(query)
        return query
    }
    
    func limit(to limit: Int) -> QueryProtocol {
        let query = MockQuery()
        queries.append(query)
        return query
    }
}

class MockDocumentReference: DocumentReferenceProtocol {
    let documentID: String
    var data: [String: Any]?
    var exists = false
    
    init(documentID: String) {
        self.documentID = documentID
    }
    
    func setData(_ data: [String: Any], merge: Bool) async throws {
        self.data = data
        self.exists = true
    }
    
    func getDocument() async throws -> DocumentSnapshotProtocol? {
        return MockDocumentSnapshot(exists: exists, data: data)
    }
    
    func delete() async throws {
        self.data = nil
        self.exists = false
    }
    
    func updateData(_ fields: [String: Any]) async throws {
        if data == nil {
            data = [:]
        }
        for (key, value) in fields {
            data?[key] = value
        }
    }
}

class MockDocumentSnapshot: DocumentSnapshotProtocol {
    let exists: Bool
    private let _data: [String: Any]?
    
    init(exists: Bool, data: [String: Any]?) {
        self.exists = exists
        self._data = data
    }
    
    func data() -> [String: Any]? {
        return _data
    }
}

class MockQuery: QueryProtocol {
    var documents: [MockDocumentSnapshot] = []
    
    func getDocuments() async throws -> QuerySnapshotProtocol {
        return MockQuerySnapshot(documents: documents)
    }
    
    func limit(to limit: Int) -> QueryProtocol {
        return self
    }
}

class MockQuerySnapshot: QuerySnapshotProtocol {
    let documents: [DocumentSnapshotProtocol]
    
    init(documents: [DocumentSnapshotProtocol]) {
        self.documents = documents
    }
}

class MockWriteBatch: WriteBatchProtocol {
    var operations: [(type: String, data: [String: Any]?, document: DocumentReferenceProtocol)] = []
    let firestore: MockFirestore
    
    init(firestore: MockFirestore) {
        self.firestore = firestore
    }
    
    func setData(_ data: [String: Any], forDocument document: DocumentReferenceProtocol, merge: Bool) {
        operations.append((type: "set", data: data, document: document))
    }
    
    func updateData(_ fields: [String: Any], forDocument document: DocumentReferenceProtocol) {
        operations.append((type: "update", data: fields, document: document))
    }
    
    func deleteDocument(_ document: DocumentReferenceProtocol) {
        operations.append((type: "delete", data: nil, document: document))
    }
    
    func commit() async throws {
        if firestore.shouldFail {
            throw firestore.failureError ?? SyncError.serverError("Mock failure")
        }
        
        for operation in operations {
            switch operation.type {
            case "set":
                if let data = operation.data {
                    try await operation.document.setData(data, merge: true)
                }
            case "update":
                if let fields = operation.data {
                    try await operation.document.updateData(fields)
                }
            case "delete":
                try await operation.document.delete()
            default:
                break
            }
        }
    }
}

class MockStorage: StorageProtocol {
    var files: [String: Data] = [:]
    var shouldFail = false
    
    func reference() -> StorageReferenceProtocol {
        return MockStorageReference(storage: self, path: "")
    }
}

class MockStorageReference: StorageReferenceProtocol {
    let storage: MockStorage
    let path: String
    
    init(storage: MockStorage, path: String) {
        self.storage = storage
        self.path = path
    }
    
    func child(_ childPath: String) -> StorageReferenceProtocol {
        let newPath = path.isEmpty ? childPath : "\(path)/\(childPath)"
        return MockStorageReference(storage: storage, path: newPath)
    }
    
    func putData(_ uploadData: Data, metadata: StorageMetadataProtocol?) async throws -> StorageMetadataProtocol {
        if storage.shouldFail {
            throw SyncError.imageUploadFailed
        }
        storage.files[path] = uploadData
        return MockStorageMetadata()
    }
    
    func downloadURL() async throws -> URL {
        guard storage.files[path] != nil else {
            throw SyncError.imageUploadFailed
        }
        return URL(string: "https://storage.mock.com/\(path)")!
    }
    
    func getData(maxSize: Int64) async throws -> Data {
        guard let data = storage.files[path] else {
            throw SyncError.serverError("File not found")
        }
        return data
    }
    
    func delete() async throws {
        storage.files.removeValue(forKey: path)
    }
}

// MARK: - Tests

@MainActor
final class TreasureSyncServiceTests: XCTestCase {
    var syncService: TreasureSyncService!
    var treasureService: TreasureService!
    var mockFirestore: MockFirestore!
    var mockStorage: MockStorage!
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([Treasure.self])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        modelContext = modelContainer.mainContext
        
        treasureService = TreasureService(modelContext: modelContext)
        syncService = TreasureSyncService(treasureService: treasureService)
        
        mockFirestore = MockFirestore()
        mockStorage = MockStorage()
        
        syncService.configure(
            firestore: mockFirestore,
            storage: mockStorage,
            userID: "testUser123"
        )
    }
    
    override func tearDown() async throws {
        syncService = nil
        treasureService = nil
        mockFirestore = nil
        mockStorage = nil
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    func testUploadTreasure() async throws {
        let treasure = try treasureService.createTreasure(
            title: "Test Treasure",
            description: "A test treasure for unit testing",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            notes: "Test notes",
            imageData: Data("test image".utf8)
        )
        
        try await syncService.uploadTreasure(treasure)
        
        let collection = mockFirestore.collections["treasures"]
        XCTAssertNotNil(collection)
        
        let document = collection?.documents[treasure.id.uuidString] as? MockDocumentReference
        XCTAssertNotNil(document)
        XCTAssertTrue(document?.exists ?? false)
        
        let data = document?.data
        XCTAssertNotNil(data)
        XCTAssertEqual(data?["title"] as? String, "Test Treasure")
        XCTAssertEqual(data?["description"] as? String, "A test treasure for unit testing")
        
        let imagePath = "treasure-images/\(treasure.id.uuidString).jpg"
        XCTAssertNotNil(mockStorage.files[imagePath])
    }
    
    func testDownloadTreasure() async throws {
        let treasureID = UUID().uuidString
        let collection = mockFirestore.collection("treasures") as! MockCollectionReference
        let document = collection.document(treasureID) as! MockDocumentReference
        
        let treasureData: [String: Any] = [
            "id": treasureID,
            "title": "Downloaded Treasure",
            "description": "A treasure from the cloud",
            "latitude": 37.7849,
            "longitude": -122.4094,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "isCollected": false,
            "lastModified": ISO8601DateFormatter().string(from: Date()),
            "version": 1
        ]
        
        try await document.setData(treasureData, merge: false)
        
        let downloadedTreasure = try await syncService.downloadTreasure(by: treasureID)
        
        XCTAssertNotNil(downloadedTreasure)
        XCTAssertEqual(downloadedTreasure?.title, "Downloaded Treasure")
        XCTAssertEqual(downloadedTreasure?.treasureDescription, "A treasure from the cloud")
        XCTAssertEqual(downloadedTreasure?.latitude, 37.7849, accuracy: 0.0001)
        XCTAssertEqual(downloadedTreasure?.longitude, -122.4094, accuracy: 0.0001)
    }
    
    func testLocationBasedQuery() async throws {
        let collection = mockFirestore.collection("treasures") as! MockCollectionReference
        
        let treasures = [
            ("Near Treasure 1", 37.775, -122.420),
            ("Near Treasure 2", 37.776, -122.419),
            ("Far Treasure", 40.7128, -74.0060)
        ]
        
        for (index, (title, lat, lon)) in treasures.enumerated() {
            let treasureData: [String: Any] = [
                "id": UUID().uuidString,
                "title": title,
                "description": "Test treasure",
                "latitude": lat,
                "longitude": lon,
                "timestamp": ISO8601DateFormatter().string(from: Date()),
                "isCollected": false,
                "lastModified": ISO8601DateFormatter().string(from: Date()),
                "version": 1
            ]
            
            let document = MockDocumentSnapshot(exists: true, data: treasureData)
            collection.queries.forEach { query in
                query.documents.append(document)
            }
        }
        
        let center = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        try await syncService.downloadNearbyTreasures(center: center, radiusKm: 5)
        
        XCTAssertFalse(collection.queries.isEmpty)
    }
    
    func testConflictResolution() async throws {
        let localTreasure = try treasureService.createTreasure(
            title: "Local Version",
            description: "Local description",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        let remoteData: [String: Any] = [
            "id": localTreasure.id.uuidString,
            "title": "Remote Version",
            "description": "Remote description",
            "latitude": 37.7749,
            "longitude": -122.4194,
            "timestamp": ISO8601DateFormatter().string(from: Date().addingTimeInterval(-3600)),
            "isCollected": true,
            "lastModified": ISO8601DateFormatter().string(from: Date().addingTimeInterval(3600)),
            "version": 2
        ]
        
        let collection = mockFirestore.collection("treasures") as! MockCollectionReference
        let document = collection.document(localTreasure.id.uuidString) as! MockDocumentReference
        try await document.setData(remoteData, merge: false)
        
        try await syncService.syncAll()
        
        let updatedTreasure = try treasureService.fetchTreasure(by: localTreasure.id)
        XCTAssertNotNil(updatedTreasure)
        XCTAssertEqual(updatedTreasure?.title, "Remote Version")
        XCTAssertEqual(updatedTreasure?.treasureDescription, "Remote description")
        XCTAssertTrue(updatedTreasure?.isCollected ?? false)
    }
    
    func testRetryLogic() async throws {
        mockFirestore.shouldFail = true
        mockFirestore.failureError = SyncError.serverError("Temporary failure")
        
        let treasure = try treasureService.createTreasure(
            title: "Test Treasure",
            description: "Testing retry logic",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        do {
            try await syncService.uploadTreasure(treasure)
            XCTFail("Expected upload to fail")
        } catch {
            XCTAssertTrue(error is SyncError)
        }
        
        mockFirestore.shouldFail = false
        
        try await syncService.uploadTreasure(treasure)
        
        let collection = mockFirestore.collections["treasures"]
        let document = collection?.documents[treasure.id.uuidString] as? MockDocumentReference
        XCTAssertNotNil(document)
        XCTAssertTrue(document?.exists ?? false)
    }
    
    func testImageCompression() async throws {
        let largeImageData = Data(repeating: 0xFF, count: 5 * 1024 * 1024)
        
        let treasure = try treasureService.createTreasure(
            title: "Image Test",
            description: "Testing image compression",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            imageData: largeImageData
        )
        
        try await syncService.uploadTreasure(treasure)
        
        let imagePath = "treasure-images/\(treasure.id.uuidString).jpg"
        let uploadedImageData = mockStorage.files[imagePath]
        
        XCTAssertNotNil(uploadedImageData)
        XCTAssertLessThan(uploadedImageData?.count ?? 0, largeImageData.count)
    }
    
    func testBatchOperations() async throws {
        let treasures = try (0..<5).map { index in
            try treasureService.createTreasure(
                title: "Batch Treasure \(index)",
                description: "Batch test treasure",
                coordinate: CLLocationCoordinate2D(
                    latitude: 37.7749 + Double(index) * 0.001,
                    longitude: -122.4194
                )
            )
        }
        
        for treasure in treasures {
            try treasureService.markAsCollected(treasure)
        }
        
        try await syncService.syncAll()
        
        let batch = mockFirestore.batch() as! MockWriteBatch
        XCTAssertFalse(batch.operations.isEmpty)
    }
    
    func testSyncStatusUpdates() async throws {
        let expectation = XCTestExpectation(description: "Sync status updated")
        var statusUpdates: [SyncStatus] = []
        
        let cancellable = syncService.$syncStatus.sink { status in
            statusUpdates.append(status)
            if case .completed = status {
                expectation.fulfill()
            }
        }
        
        let treasure = try treasureService.createTreasure(
            title: "Status Test",
            description: "Testing status updates",
            coordinate: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
        )
        
        try await syncService.uploadTreasure(treasure)
        
        await fulfillment(of: [expectation], timeout: 5.0)
        
        XCTAssertTrue(statusUpdates.contains { status in
            if case .uploading = status { return true }
            return false
        })
        
        XCTAssertTrue(statusUpdates.contains { status in
            if case .completed = status { return true }
            return false
        })
        
        cancellable.cancel()
    }
    
    func testDeleteTreasureWithImage() async throws {
        let treasureID = UUID().uuidString
        let imagePath = "treasure-images/\(treasureID).jpg"
        
        mockStorage.files[imagePath] = Data("test image".utf8)
        
        let collection = mockFirestore.collection("treasures") as! MockCollectionReference
        let document = collection.document(treasureID) as! MockDocumentReference
        
        let treasureData: [String: Any] = [
            "id": treasureID,
            "title": "Delete Test",
            "description": "To be deleted",
            "latitude": 37.7749,
            "longitude": -122.4194,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "isCollected": false,
            "imageURL": "https://storage.mock.com/\(imagePath)",
            "lastModified": ISO8601DateFormatter().string(from: Date()),
            "version": 1
        ]
        
        try await document.setData(treasureData, merge: false)
        
        try await syncService.deleteTreasure(treasureID)
        
        XCTAssertFalse(document.exists)
        XCTAssertNil(mockStorage.files[imagePath])
    }
}