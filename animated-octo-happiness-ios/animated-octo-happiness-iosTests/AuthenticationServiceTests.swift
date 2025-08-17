//
//  AuthenticationServiceTests.swift
//  animated-octo-happiness-iosTests
//
//  Created by Auto-Agent on 8/17/25.
//

import XCTest
import SwiftData
@testable import animated_octo_happiness_ios

@MainActor
final class AuthenticationServiceTests: XCTestCase {
    var authService: AuthenticationService!
    var modelContainer: ModelContainer!
    
    override func setUp() async throws {
        try await super.setUp()
        
        let schema = Schema([
            User.self,
            UserPreferences.self,
            Treasure.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [modelConfiguration])
        
        authService = AuthenticationService(modelContext: modelContainer.mainContext)
    }
    
    override func tearDown() async throws {
        authService.logout()
        authService = nil
        modelContainer = nil
        try await super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertEqual(authService.authState, .unauthenticated)
        XCTAssertNil(authService.currentUser)
        XCTAssertFalse(authService.isLoading)
        XCTAssertNil(authService.errorMessage)
    }
    
    func testUserRegistration() async throws {
        let email = "test@example.com"
        let password = "password123"
        let displayName = "Test User"
        
        try await authService.register(email: email, password: password, displayName: displayName)
        
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, email)
        XCTAssertEqual(authService.currentUser?.displayName, displayName)
        XCTAssertFalse(authService.currentUser?.isAnonymous ?? true)
        
        if case .authenticated(let user) = authService.authState {
            XCTAssertEqual(user.email, email)
        } else {
            XCTFail("Expected authenticated state")
        }
    }
    
    func testInvalidEmailRegistration() async {
        let invalidEmail = "invalid-email"
        let password = "password123"
        
        do {
            try await authService.register(email: invalidEmail, password: password)
            XCTFail("Should have thrown invalid email error")
        } catch {
            if let authError = error as? AuthenticationError {
                XCTAssertEqual(authError, .invalidEmail)
            } else {
                XCTFail("Expected AuthenticationError.invalidEmail")
            }
        }
    }
    
    func testWeakPasswordRegistration() async {
        let email = "test@example.com"
        let weakPassword = "123"
        
        do {
            try await authService.register(email: email, password: weakPassword)
            XCTFail("Should have thrown weak password error")
        } catch {
            if let authError = error as? AuthenticationError {
                XCTAssertEqual(authError, .weakPassword)
            } else {
                XCTFail("Expected AuthenticationError.weakPassword")
            }
        }
    }
    
    func testUserLogin() async throws {
        let email = "test@example.com"
        let password = "password123"
        
        try await authService.register(email: email, password: password)
        authService.logout()
        
        XCTAssertEqual(authService.authState, .unauthenticated)
        
        try await authService.login(email: email, password: password)
        
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, email)
        
        if case .authenticated(let user) = authService.authState {
            XCTAssertEqual(user.email, email)
        } else {
            XCTFail("Expected authenticated state")
        }
    }
    
    func testWrongPasswordLogin() async throws {
        let email = "test@example.com"
        let password = "password123"
        let wrongPassword = "wrongpassword"
        
        try await authService.register(email: email, password: password)
        authService.logout()
        
        do {
            try await authService.login(email: email, password: wrongPassword)
            XCTFail("Should have thrown wrong password error")
        } catch {
            if let authError = error as? AuthenticationError {
                XCTAssertEqual(authError, .wrongPassword)
            } else {
                XCTFail("Expected AuthenticationError.wrongPassword")
            }
        }
    }
    
    func testLogout() async throws {
        let email = "test@example.com"
        let password = "password123"
        
        try await authService.register(email: email, password: password)
        
        XCTAssertNotNil(authService.currentUser)
        
        authService.logout()
        
        XCTAssertNil(authService.currentUser)
        XCTAssertEqual(authService.authState, .unauthenticated)
    }
    
    func testAnonymousSignIn() async throws {
        try await authService.signInAnonymously()
        
        XCTAssertNotNil(authService.currentUser)
        XCTAssertTrue(authService.currentUser?.isAnonymous ?? false)
        
        if case .anonymous(let user) = authService.authState {
            XCTAssertTrue(user.isAnonymous)
            XCTAssertTrue(user.id.hasPrefix("anon_"))
        } else {
            XCTFail("Expected anonymous state")
        }
    }
    
    func testAnonymousToAuthenticatedMigration() async throws {
        try await authService.signInAnonymously()
        
        let anonymousUserId = authService.currentUser?.id
        XCTAssertNotNil(anonymousUserId)
        
        let email = "migrated@example.com"
        let password = "password123"
        
        try await authService.migrateAnonymousUser(to: email, password: password)
        
        XCTAssertNotNil(authService.currentUser)
        XCTAssertEqual(authService.currentUser?.email, email)
        XCTAssertFalse(authService.currentUser?.isAnonymous ?? true)
        XCTAssertEqual(authService.currentUser?.id, anonymousUserId)
        
        if case .authenticated(let user) = authService.authState {
            XCTAssertEqual(user.email, email)
            XCTAssertFalse(user.isAnonymous)
        } else {
            XCTFail("Expected authenticated state after migration")
        }
    }
    
    func testMigrationFailsForAuthenticatedUser() async throws {
        let email = "test@example.com"
        let password = "password123"
        
        try await authService.register(email: email, password: password)
        
        do {
            try await authService.migrateAnonymousUser(to: "other@example.com", password: "password456")
            XCTFail("Should have thrown migration failed error")
        } catch {
            if let authError = error as? AuthenticationError {
                XCTAssertEqual(authError, .migrationFailed)
            } else {
                XCTFail("Expected AuthenticationError.migrationFailed")
            }
        }
    }
    
    func testUpdateUserProfile() async throws {
        let email = "test@example.com"
        let password = "password123"
        
        try await authService.register(email: email, password: password)
        
        let newDisplayName = "Updated Name"
        let newPhotoURL = "https://example.com/photo.jpg"
        
        try await authService.updateUserProfile(displayName: newDisplayName, photoURL: newPhotoURL)
        
        XCTAssertEqual(authService.currentUser?.displayName, newDisplayName)
        XCTAssertEqual(authService.currentUser?.photoURL, newPhotoURL)
    }
    
    func testPasswordResetEmail() async throws {
        let email = "test@example.com"
        
        try await authService.sendPasswordResetEmail(to: email)
        
        XCTAssertNil(authService.errorMessage)
    }
    
    func testInvalidEmailPasswordReset() async {
        let invalidEmail = "invalid-email"
        
        do {
            try await authService.sendPasswordResetEmail(to: invalidEmail)
            XCTFail("Should have thrown invalid email error")
        } catch {
            if let authError = error as? AuthenticationError {
                XCTAssertEqual(authError, .invalidEmail)
            } else {
                XCTFail("Expected AuthenticationError.invalidEmail")
            }
        }
    }
    
    func testSessionPersistence() async throws {
        let email = "test@example.com"
        let password = "password123"
        
        try await authService.register(email: email, password: password)
        
        let userId = authService.currentUser?.id
        XCTAssertNotNil(userId)
        
        let newAuthService = AuthenticationService(modelContext: modelContainer.mainContext)
        
        await Task.yield()
        
        if case .authenticated(let user) = newAuthService.authState {
            XCTAssertEqual(user.id, userId)
            XCTAssertEqual(user.email, email)
        } else {
            XCTFail("Expected session to be persisted")
        }
    }
}