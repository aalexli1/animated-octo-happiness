import Foundation
// Import FirebaseAuth when package is added
// import FirebaseAuth

enum AuthError: LocalizedError {
    case userNotFound
    case invalidCredentials
    case networkError
    case unknownError(String)
    
    var errorDescription: String? {
        switch self {
        case .userNotFound:
            return "User not found"
        case .invalidCredentials:
            return "Invalid email or password"
        case .networkError:
            return "Network error occurred"
        case .unknownError(let message):
            return message
        }
    }
}

@MainActor
class FirebaseAuthService: ObservableObject {
    static let shared = FirebaseAuthService()
    
    @Published var currentUser: User?
    @Published var isAuthenticated = false
    @Published var isLoading = false
    
    private init() {
        setupAuthStateListener()
    }
    
    struct User {
        let uid: String
        let email: String?
        let displayName: String?
        let photoURL: URL?
    }
    
    private func setupAuthStateListener() {
        // TODO: Uncomment when Firebase is added
        // Auth.auth().addStateDidChangeListener { [weak self] _, user in
        //     if let user = user {
        //         self?.currentUser = User(
        //             uid: user.uid,
        //             email: user.email,
        //             displayName: user.displayName,
        //             photoURL: user.photoURL
        //         )
        //         self?.isAuthenticated = true
        //     } else {
        //         self?.currentUser = nil
        //         self?.isAuthenticated = false
        //     }
        // }
    }
    
    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Uncomment when Firebase is added
        // do {
        //     let result = try await Auth.auth().signIn(withEmail: email, password: password)
        //     currentUser = User(
        //         uid: result.user.uid,
        //         email: result.user.email,
        //         displayName: result.user.displayName,
        //         photoURL: result.user.photoURL
        //     )
        // } catch {
        //     throw mapAuthError(error)
        // }
    }
    
    func signUp(email: String, password: String, displayName: String? = nil) async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Uncomment when Firebase is added
        // do {
        //     let result = try await Auth.auth().createUser(withEmail: email, password: password)
        //     
        //     if let displayName = displayName {
        //         let changeRequest = result.user.createProfileChangeRequest()
        //         changeRequest.displayName = displayName
        //         try await changeRequest.commitChanges()
        //     }
        //     
        //     currentUser = User(
        //         uid: result.user.uid,
        //         email: result.user.email,
        //         displayName: displayName,
        //         photoURL: result.user.photoURL
        //     )
        // } catch {
        //     throw mapAuthError(error)
        // }
    }
    
    func signInAnonymously() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Uncomment when Firebase is added
        // do {
        //     let result = try await Auth.auth().signInAnonymously()
        //     currentUser = User(
        //         uid: result.user.uid,
        //         email: nil,
        //         displayName: nil,
        //         photoURL: nil
        //     )
        // } catch {
        //     throw mapAuthError(error)
        // }
    }
    
    func signOut() throws {
        // TODO: Uncomment when Firebase is added
        // try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
    }
    
    func resetPassword(email: String) async throws {
        // TODO: Uncomment when Firebase is added
        // do {
        //     try await Auth.auth().sendPasswordReset(withEmail: email)
        // } catch {
        //     throw mapAuthError(error)
        // }
    }
    
    func deleteAccount() async throws {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Uncomment when Firebase is added
        // guard let user = Auth.auth().currentUser else {
        //     throw AuthError.userNotFound
        // }
        // 
        // try await user.delete()
        currentUser = nil
        isAuthenticated = false
    }
    
    private func mapAuthError(_ error: Error) -> AuthError {
        // TODO: Uncomment when Firebase is added
        // let nsError = error as NSError
        // let code = AuthErrorCode(_nsError: nsError)
        // 
        // switch code.code {
        // case .userNotFound:
        //     return .userNotFound
        // case .wrongPassword, .invalidEmail:
        //     return .invalidCredentials
        // case .networkError:
        //     return .networkError
        // default:
        //     return .unknownError(error.localizedDescription)
        // }
        return .unknownError(error.localizedDescription)
    }
}