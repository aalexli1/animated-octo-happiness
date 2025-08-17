//
//  FirebaseConfig.swift
//  animated-octo-happiness-ios
//
//  Backend configuration for Firebase services
//

import Foundation
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage

class FirebaseConfig {
    static let shared = FirebaseConfig()
    
    private init() {}
    
    func configure() {
        FirebaseApp.configure()
        
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = true
        settings.cacheSizeBytes = FirestoreCacheSizeUnlimited
        
        Firestore.firestore().settings = settings
    }
    
    var auth: Auth {
        Auth.auth()
    }
    
    var firestore: Firestore {
        Firestore.firestore()
    }
    
    var storage: Storage {
        Storage.storage()
    }
}

struct FirebaseCollections {
    static let treasures = "treasures"
    static let users = "users"
    static let friendRequests = "friendRequests"
    static let groups = "groups"
}

struct FirebaseStoragePaths {
    static let treasureImages = "treasure_images"
    static let userProfiles = "user_profiles"
}