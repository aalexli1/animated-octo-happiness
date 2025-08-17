//
//  AuthenticationService.swift
//  animated-octo-happiness-ios
//
//  Handles user authentication and session management
//

import Foundation
import FirebaseAuth
import FirebaseFirestore
import Combine
import AuthenticationServices

@MainActor
class AuthenticationService: ObservableObject {
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authStateHandle: AuthStateDidChangeListenerHandle?
    private let auth = FirebaseConfig.shared.auth
    private let firestore = FirebaseConfig.shared.firestore
    
    init() {
        setupAuthStateListener()
    }
    
    deinit {
        if let handle = authStateHandle {
            auth.removeStateDidChangeListener(handle)
        }
    }
    
    private func setupAuthStateListener() {
        authStateHandle = auth.addStateDidChangeListener { [weak self] _, user in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                
                if let user = user {
                    self.isAuthenticated = true
                    await self.fetchUserProfile(userId: user.uid)
                } else {
                    self.isAuthenticated = false
                    self.currentUser = nil
                }
            }
        }
    }
    
    func signUp(email: String, password: String, displayName: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.createUser(withEmail: email, password: password)
            
            let newUser = User(
                email: email,
                displayName: displayName
            )
            
            try await firestore.collection(FirebaseCollections.users)
                .document(result.user.uid)
                .setData(from: newUser)
            
            self.currentUser = newUser
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            await fetchUserProfile(userId: result.user.uid)
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func signOut() throws {
        do {
            try auth.signOut()
            currentUser = nil
            isAuthenticated = false
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    func deleteAccount() async throws {
        guard let user = auth.currentUser else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        
        do {
            try await firestore.collection(FirebaseCollections.users)
                .document(user.uid)
                .delete()
            
            try await user.delete()
            
            currentUser = nil
            isAuthenticated = false
            isLoading = false
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    private func fetchUserProfile(userId: String) async {
        do {
            let document = try await firestore.collection(FirebaseCollections.users)
                .document(userId)
                .getDocument()
            
            if document.exists {
                self.currentUser = try document.data(as: User.self)
            }
        } catch {
            print("Error fetching user profile: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    func updateProfile(displayName: String? = nil, profileImageURL: String? = nil) async throws {
        guard let userId = auth.currentUser?.uid else {
            throw AuthError.notAuthenticated
        }
        
        var updates: [String: Any] = ["updatedAt": FieldValue.serverTimestamp()]
        
        if let displayName = displayName {
            updates["displayName"] = displayName
        }
        
        if let profileImageURL = profileImageURL {
            updates["profileImageURL"] = profileImageURL
        }
        
        try await firestore.collection(FirebaseCollections.users)
            .document(userId)
            .updateData(updates)
        
        await fetchUserProfile(userId: userId)
    }
}

enum AuthError: LocalizedError {
    case notAuthenticated
    case invalidCredentials
    case networkError
    case unknown
    
    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "You must be signed in to perform this action"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error. Please check your connection"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}