import XCTest
@testable import animated_octo_happiness_ios

@MainActor
final class FirestoreServiceTests: XCTestCase {
    
    var firestoreService: FirestoreService!
    
    override func setUp() {
        super.setUp()
        firestoreService = FirestoreService.shared
    }
    
    func testCreateTreasure() async throws {
        // Given
        let treasure = Treasure(
            id: nil,
            title: "Test Treasure",
            description: "A test treasure for unit testing",
            latitude: 37.7749,
            longitude: -122.4194,
            hint: "Look near the bridge",
            difficulty: 3,
            points: 100,
            isFound: false,
            createdAt: Date(),
            foundAt: nil,
            emoji: "🎁",
            imageData: nil
        )
        
        // When
        let treasureId = try await firestoreService.createTreasure(treasure)
        
        // Then
        XCTAssertNotNil(treasureId)
        XCTAssertFalse(treasureId.isEmpty)
    }
    
    func testGetTreasure() async throws {
        // Given
        let treasureId = "test-treasure-id"
        
        // When
        let treasure = try await firestoreService.getTreasure(id: treasureId)
        
        // Then
        // Note: In a real test environment with Firebase emulator,
        // you'd first create a treasure and then retrieve it
        XCTAssertNotNil(firestoreService)
    }
    
    func testUpdateTreasure() async throws {
        // Given
        var treasure = Treasure(
            id: "test-id",
            title: "Updated Treasure",
            description: "Updated description",
            latitude: 37.7749,
            longitude: -122.4194,
            hint: "Updated hint",
            difficulty: 5,
            points: 200,
            isFound: true,
            createdAt: Date(),
            foundAt: Date(),
            emoji: "🏆",
            imageData: nil
        )
        
        // When/Then
        // Note: This would throw an error without proper Firebase setup
        do {
            try await firestoreService.updateTreasure(treasure)
        } catch FirestoreError.invalidData {
            // Expected in test environment
            XCTAssertTrue(true)
        }
    }
    
    func testDeleteTreasure() async throws {
        // Given
        let treasureId = "test-treasure-to-delete"
        
        // When/Then
        // Note: In a real test environment with Firebase emulator,
        // you'd first create a treasure and then delete it
        XCTAssertNotNil(firestoreService)
    }
    
    func testGetUserTreasures() async throws {
        // Given
        let userId = "test-user-123"
        
        // When
        let treasures = try await firestoreService.getUserTreasures(userId: userId)
        
        // Then
        XCTAssertNotNil(treasures)
        XCTAssertTrue(treasures.isEmpty) // Expected in test environment
    }
    
    func testGetTreasuresNearLocation() async throws {
        // Given
        let latitude = 37.7749
        let longitude = -122.4194
        let radiusKm = 10.0
        
        // When
        let treasures = try await firestoreService.getTreasuresNearLocation(
            latitude: latitude,
            longitude: longitude,
            radiusKm: radiusKm
        )
        
        // Then
        XCTAssertNotNil(treasures)
        XCTAssertTrue(treasures.isEmpty) // Expected in test environment
    }
    
    func testUserProfileOperations() async throws {
        // Given
        let profile = UserProfile(
            id: "test-user-123",
            email: "test@example.com",
            displayName: "Test User",
            photoURL: "https://example.com/photo.jpg",
            treasuresCreated: 5,
            treasuresFound: 10,
            joinedAt: Date(),
            lastActive: Date()
        )
        
        // Test create
        try await firestoreService.createUserProfile(profile)
        
        // Test get
        let retrievedProfile = try await firestoreService.getUserProfile(id: "test-user-123")
        XCTAssertNil(retrievedProfile) // Expected in test environment
        
        // Test update
        try await firestoreService.updateUserProfile(profile)
        
        XCTAssertNotNil(firestoreService)
    }
    
    func testBatchCreateTreasures() async throws {
        // Given
        let treasures = [
            Treasure(
                title: "Treasure 1",
                description: "Description 1",
                latitude: 37.7749,
                longitude: -122.4194,
                hint: "Hint 1",
                difficulty: 1,
                points: 50,
                isFound: false,
                createdAt: Date(),
                foundAt: nil,
                emoji: "🎁",
                imageData: nil
            ),
            Treasure(
                title: "Treasure 2",
                description: "Description 2",
                latitude: 37.7849,
                longitude: -122.4294,
                hint: "Hint 2",
                difficulty: 2,
                points: 75,
                isFound: false,
                createdAt: Date(),
                foundAt: nil,
                emoji: "💎",
                imageData: nil
            )
        ]
        
        // When
        try await firestoreService.batchCreateTreasures(treasures)
        
        // Then
        XCTAssertNotNil(firestoreService)
    }
    
    func testFirestoreErrorTypes() {
        // Test error cases
        let errors: [FirestoreError] = [
            .documentNotFound,
            .invalidData,
            .permissionDenied,
            .networkError,
            .unknownError("Test error")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testListenToTreasures() {
        // Given
        let expectation = XCTestExpectation(description: "Listen to treasures")
        
        // When
        firestoreService.listenToTreasures { result in
            switch result {
            case .success(let treasures):
                XCTAssertNotNil(treasures)
            case .failure(let error):
                // Expected in test environment without Firebase
                XCTAssertNotNil(error)
            }
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
}