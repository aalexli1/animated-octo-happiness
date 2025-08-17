//
//  animated_octo_happiness_iosApp.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/16/25.
//

import SwiftUI
import SwiftData
// Import Firebase when package is added
// import FirebaseCore
// import FirebaseAuth

@main
struct animated_octo_happiness_iosApp: App {
    @StateObject private var locationManager = LocationManager()
    @StateObject private var notificationManager = NotificationManager.shared
    let modelContainer: ModelContainer
    
    init() {
        // Initialize Firebase before any other setup
        configureFirebase()
        
        do {
            let schema = Schema([
                Treasure.self,
                User.self,
                UserPreferences.self,
                NotificationPreferences.self
            ])
            let modelConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
            modelContainer = try ModelContainer(
                for: schema,
                configurations: [modelConfiguration]
            )
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func configureFirebase() {
        // TODO: Uncomment when Firebase is added and GoogleService-Info.plist is configured
        // guard let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") else {
        //     print("⚠️ GoogleService-Info.plist not found. Firebase will not be initialized.")
        //     print("Please add GoogleService-Info.plist to your project.")
        //     print("You can get this file from the Firebase Console.")
        //     return
        // }
        // 
        // guard let options = FirebaseOptions(contentsOfFile: filePath) else {
        //     print("⚠️ Could not load Firebase configuration from GoogleService-Info.plist")
        //     return
        // }
        // 
        // FirebaseApp.configure(options: options)
        // 
        // // Enable Firebase Auth persistence
        // Auth.auth().useAppLanguage()
        // 
        // print("✅ Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .environmentObject(notificationManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task { @MainActor in
                        notificationManager.checkAuthorizationStatus()
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowTreasureDetail"))) { _ in
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowAchievements"))) { _ in
                }
                .onReceive(NotificationCenter.default.publisher(for: Notification.Name("StartTreasureHunt"))) { _ in
                }
        }
        .modelContainer(modelContainer)
    }
}