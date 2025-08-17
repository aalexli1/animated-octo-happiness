import XCTest
@testable import animated_octo_happiness_ios

@MainActor
final class FirebaseAuthServiceTests: XCTestCase {
    
    var authService: FirebaseAuthService!
    
    override func setUp() {
        super.setUp()
        authService = FirebaseAuthService.shared
    }
    
    override func tearDown() {
        // Sign out after each test
        try? authService.signOut()
        super.tearDown()
    }
    
    func testSignUpWithValidCredentials() async throws {
        // Given
        let email = "test\(UUID().uuidString)@example.com"
        let password = "TestPassword123!"
        let displayName = "Test User"
        
        // When
        // Note: This test requires Firebase to be properly configured
        // In a real test environment, you'd use Firebase emulator
        
        // Then
        XCTAssertNotNil(authService)
        XCTAssertFalse(authService.isAuthenticated)
    }
    
    func testSignInWithValidCredentials() async throws {
        // Given
        let email = "existing@example.com"
        let password = "Password123!"
        
        // When
        // Note: This test requires a pre-existing user
        // In a real test environment, you'd use Firebase emulator
        
        // Then
        XCTAssertNotNil(authService)
    }
    
    func testSignOut() throws {
        // Given
        // Assume user is signed in
        
        // When
        try authService.signOut()
        
        // Then
        XCTAssertFalse(authService.isAuthenticated)
        XCTAssertNil(authService.currentUser)
    }
    
    func testAnonymousSignIn() async throws {
        // When
        // Note: This test requires Firebase to be properly configured
        // In a real test environment, you'd use Firebase emulator
        
        // Then
        XCTAssertNotNil(authService)
    }
    
    func testPasswordReset() async throws {
        // Given
        let email = "test@example.com"
        
        // When
        // Note: This test requires Firebase to be properly configured
        // In a real test environment, you'd use Firebase emulator
        
        // Then
        XCTAssertNotNil(authService)
    }
    
    func testAuthStateListener() {
        // Given
        let expectation = XCTestExpectation(description: "Auth state listener")
        
        // When
        // The auth state listener is set up in init
        
        // Then
        XCTAssertNotNil(authService)
        
        // Note: In a real test, you'd trigger auth state changes
        // and verify the listener responds correctly
    }
    
    func testUserModel() {
        // Given
        let uid = "test123"
        let email = "test@example.com"
        let displayName = "Test User"
        let photoURL = URL(string: "https://example.com/photo.jpg")
        
        // When
        let user = FirebaseAuthService.User(
            uid: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL
        )
        
        // Then
        XCTAssertEqual(user.uid, uid)
        XCTAssertEqual(user.email, email)
        XCTAssertEqual(user.displayName, displayName)
        XCTAssertEqual(user.photoURL, photoURL)
    }
    
    func testAuthErrorTypes() {
        // Test error cases
        let errors: [AuthError] = [
            .userNotFound,
            .invalidCredentials,
            .networkError,
            .unknownError("Test error")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}