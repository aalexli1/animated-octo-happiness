//
//  AuthenticationService.swift
//  animated-octo-happiness-ios
//
//  Created by Auto-Agent on 8/17/25.
//

import Foundation
import SwiftUI
import Combine
import SwiftData
import AuthenticationServices
import CryptoKit

enum AuthenticationError: LocalizedError {
    case invalidEmail
    case weakPassword
    case emailAlreadyInUse
    case userNotFound
    case wrongPassword
    case networkError
    case unknownError
    case signInWithAppleFailed
    case migrationFailed
    case sessionExpired
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Please enter a valid email address."
        case .weakPassword:
            return "Password must be at least 6 characters long."
        case .emailAlreadyInUse:
            return "This email is already registered."
        case .userNotFound:
            return "No account found with this email."
        case .wrongPassword:
            return "Incorrect password. Please try again."
        case .networkError:
            return "Network error. Please check your connection."
        case .unknownError:
            return "An unexpected error occurred."
        case .signInWithAppleFailed:
            return "Sign in with Apple failed."
        case .migrationFailed:
            return "Failed to migrate anonymous account."
        case .sessionExpired:
            return "Your session has expired. Please sign in again."
        }
    }
}

enum AuthenticationState {
    case unauthenticated
    case authenticating
    case authenticated(User)
    case anonymous(User)
}

@MainActor
class AuthenticationService: ObservableObject {
    @Published var authState: AuthenticationState = .unauthenticated
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    private let userDefaults = UserDefaults.standard
    private let keychainService = "com.animated-octo-happiness.auth"
    private var currentNonce: String?
    
    private let sessionKey = "user_session"
    private let sessionExpirationKey = "session_expiration"
    
    init(modelContext: ModelContext? = nil) {
        self.modelContext = modelContext
        checkSessionStatus()
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    // MARK: - Session Management
    
    private func checkSessionStatus() {
        guard let sessionData = userDefaults.data(forKey: sessionKey),
              let sessionExpiration = userDefaults.object(forKey: sessionExpirationKey) as? Date,
              sessionExpiration > Date() else {
            authState = .unauthenticated
            return
        }
        
        if let user = try? JSONDecoder().decode(User.self, from: sessionData) {
            currentUser = user
            authState = user.isAnonymous ? .anonymous(user) : .authenticated(user)
            user.recordLogin()
            saveUserToDatabase(user)
        }
    }
    
    private func saveSession(user: User, duration: TimeInterval = 7 * 24 * 60 * 60) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: sessionKey)
            userDefaults.set(Date().addingTimeInterval(duration), forKey: sessionExpirationKey)
        }
    }
    
    private func clearSession() {
        userDefaults.removeObject(forKey: sessionKey)
        userDefaults.removeObject(forKey: sessionExpirationKey)
        deleteCredentialsFromKeychain()
    }
    
    // MARK: - Registration
    
    func register(email: String, password: String, displayName: String? = nil) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthenticationError.weakPassword
        }
        
        // TODO: Integrate with Firebase Auth when SDK is available
        // For now, create a mock user
        let userId = UUID().uuidString
        let user = User(
            id: userId,
            email: email,
            displayName: displayName ?? email.components(separatedBy: "@").first,
            isAnonymous: false,
            createdAt: Date()
        )
        
        saveCredentialsToKeychain(email: email, password: password)
        saveUserToDatabase(user)
        saveSession(user: user)
        
        currentUser = user
        authState = .authenticated(user)
    }
    
    // MARK: - Login
    
    func login(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        // TODO: Integrate with Firebase Auth when SDK is available
        // For now, check against keychain
        guard let storedPassword = getPasswordFromKeychain(for: email),
              storedPassword == password else {
            throw AuthenticationError.wrongPassword
        }
        
        // Fetch or create user
        let userId = UUID().uuidString
        let user = User(
            id: userId,
            email: email,
            displayName: email.components(separatedBy: "@").first,
            isAnonymous: false
        )
        
        user.recordLogin()
        saveUserToDatabase(user)
        saveSession(user: user)
        
        currentUser = user
        authState = .authenticated(user)
    }
    
    // MARK: - Logout
    
    func logout() {
        clearSession()
        currentUser = nil
        authState = .unauthenticated
        errorMessage = nil
    }
    
    // MARK: - Anonymous Authentication
    
    func signInAnonymously() async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // TODO: Integrate with Firebase Auth when SDK is available
        let userId = UUID().uuidString
        let user = User(
            id: "anon_\(userId)",
            isAnonymous: true,
            createdAt: Date()
        )
        
        saveUserToDatabase(user)
        saveSession(user: user)
        
        currentUser = user
        authState = .anonymous(user)
    }
    
    // MARK: - Anonymous to Authenticated Migration
    
    func migrateAnonymousUser(to email: String, password: String) async throws {
        guard case .anonymous(let anonymousUser) = authState else {
            throw AuthenticationError.migrationFailed
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        guard password.count >= 6 else {
            throw AuthenticationError.weakPassword
        }
        
        // TODO: Integrate with Firebase Auth for proper migration
        anonymousUser.migrateFromAnonymous(to: email)
        
        saveCredentialsToKeychain(email: email, password: password)
        saveUserToDatabase(anonymousUser)
        saveSession(user: anonymousUser)
        
        currentUser = anonymousUser
        authState = .authenticated(anonymousUser)
    }
    
    // MARK: - Password Reset
    
    func sendPasswordResetEmail(to email: String) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        // TODO: Integrate with Firebase Auth for password reset
        // For now, just simulate success
        print("Password reset email would be sent to: \(email)")
    }
    
    // MARK: - Apple Sign In
    
    func handleSignInWithApple(authorization: ASAuthorization) async throws {
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthenticationError.signInWithAppleFailed
        }
        
        guard let nonce = currentNonce else {
            throw AuthenticationError.signInWithAppleFailed
        }
        
        guard let appleIDToken = appleIDCredential.identityToken,
              let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
            throw AuthenticationError.signInWithAppleFailed
        }
        
        // TODO: Integrate with Firebase Auth for Apple Sign In
        // For now, create a user from Apple credentials
        let userId = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        var displayName: String?
        if let fullName = fullName {
            let formatter = PersonNameComponentsFormatter()
            displayName = formatter.string(from: fullName)
        }
        
        let user = User(
            id: userId,
            email: email,
            displayName: displayName,
            isAnonymous: false,
            createdAt: Date()
        )
        
        user.recordLogin()
        saveUserToDatabase(user)
        saveSession(user: user)
        
        currentUser = user
        authState = .authenticated(user)
    }
    
    func prepareSignInWithApple() -> String {
        let nonce = randomNonceString()
        currentNonce = nonce
        return sha256(nonce)
    }
    
    // MARK: - Profile Management
    
    func updateUserProfile(displayName: String? = nil, photoURL: String? = nil) async throws {
        guard let user = currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        user.updateProfile(displayName: displayName, photoURL: photoURL)
        saveUserToDatabase(user)
        saveSession(user: user)
        
        objectWillChange.send()
    }
    
    func deleteAccount() async throws {
        guard let user = currentUser else {
            throw AuthenticationError.userNotFound
        }
        
        isLoading = true
        errorMessage = nil
        
        defer { isLoading = false }
        
        // TODO: Integrate with Firebase Auth for account deletion
        if let context = modelContext {
            context.delete(user)
            try context.save()
        }
        
        logout()
    }
    
    // MARK: - Helper Methods
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func saveUserToDatabase(_ user: User) {
        guard let context = modelContext else { return }
        
        context.insert(user)
        
        do {
            try context.save()
        } catch {
            print("Failed to save user: \(error)")
        }
    }
    
    // MARK: - Keychain Methods
    
    private func saveCredentialsToKeychain(email: String, password: String) {
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: email,
            kSecValueData as String: passwordData
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func getPasswordFromKeychain(for email: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: email,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let passwordData = result as? Data,
              let password = String(data: passwordData, encoding: .utf8) else {
            return nil
        }
        
        return password
    }
    
    private func deleteCredentialsFromKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService
        ]
        
        SecItemDelete(query as CFDictionary)
    }
    
    // MARK: - Apple Sign In Helpers
    
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError("Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)")
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}