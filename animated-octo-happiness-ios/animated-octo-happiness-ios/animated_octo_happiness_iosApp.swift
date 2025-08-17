//
//  animated_octo_happiness_iosApp.swift
//  animated-octo-happiness-ios
//
//  Created by Alex on 8/16/25.
//

import SwiftUI
import SwiftData

@main
struct animated_octo_happiness_iosApp: App {
    @StateObject private var locationManager = LocationManager()
    let modelContainer: ModelContainer
    
    init() {
        do {
            let schema = Schema([
                Treasure.self,
                User.self,
                UserPreferences.self
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
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(locationManager)
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    Task { @MainActor in
                        locationManager.checkLocationServicesStatus()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}