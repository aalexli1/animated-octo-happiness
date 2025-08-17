import Foundation

enum FirebaseEnvironment: String {
    case development = "dev"
    case staging = "staging"
    case production = "prod"
    
    static var current: FirebaseEnvironment {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }
    
    var configFileName: String {
        switch self {
        case .development:
            return "GoogleService-Info-Dev"
        case .staging:
            return "GoogleService-Info-Staging"
        case .production:
            return "GoogleService-Info"
        }
    }
    
    var firestoreSettings: FirestoreSettings {
        switch self {
        case .development, .staging:
            return FirestoreSettings(
                host: nil,
                isSSLEnabled: true,
                isPersistenceEnabled: true,
                cacheSizeBytes: 100 * 1024 * 1024 // 100MB cache for dev/staging
            )
        case .production:
            return FirestoreSettings(
                host: nil,
                isSSLEnabled: true,
                isPersistenceEnabled: true,
                cacheSizeBytes: 50 * 1024 * 1024 // 50MB cache for production
            )
        }
    }
    
    var authSettings: AuthSettings {
        switch self {
        case .development, .staging:
            return AuthSettings(
                enableAnonymousAuth: true,
                enableEmailAuth: true,
                enableAppleSignIn: true,
                enableGoogleSignIn: false,
                requireEmailVerification: false
            )
        case .production:
            return AuthSettings(
                enableAnonymousAuth: false,
                enableEmailAuth: true,
                enableAppleSignIn: true,
                enableGoogleSignIn: true,
                requireEmailVerification: true
            )
        }
    }
    
    var storageSettings: StorageSettings {
        switch self {
        case .development, .staging:
            return StorageSettings(
                maxUploadSize: 50 * 1024 * 1024, // 50MB
                maxDownloadSize: 50 * 1024 * 1024,
                enableCaching: true,
                cacheExpirationTime: 3600 // 1 hour
            )
        case .production:
            return StorageSettings(
                maxUploadSize: 10 * 1024 * 1024, // 10MB
                maxDownloadSize: 10 * 1024 * 1024,
                enableCaching: true,
                cacheExpirationTime: 86400 // 24 hours
            )
        }
    }
}

// MARK: - Settings Structures

struct FirestoreSettings {
    let host: String?
    let isSSLEnabled: Bool
    let isPersistenceEnabled: Bool
    let cacheSizeBytes: Int64
}

struct AuthSettings {
    let enableAnonymousAuth: Bool
    let enableEmailAuth: Bool
    let enableAppleSignIn: Bool
    let enableGoogleSignIn: Bool
    let requireEmailVerification: Bool
}

struct StorageSettings {
    let maxUploadSize: Int64
    let maxDownloadSize: Int64
    let enableCaching: Bool
    let cacheExpirationTime: TimeInterval
}