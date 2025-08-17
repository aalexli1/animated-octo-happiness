import SwiftUI
import SwiftData

struct NotificationSettingsView: View {
    @StateObject private var notificationManager = NotificationManager.shared
    @Environment(\.modelContext) private var modelContext
    @Query private var preferences: [NotificationPreferences]
    @State private var showingPermissionAlert = false
    
    private var currentPreferences: NotificationPreferences {
        preferences.first ?? NotificationPreferences.default
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Notification Permissions") {
                    HStack {
                        Text("Notifications")
                        Spacer()
                        if notificationManager.isAuthorized {
                            Label("Enabled", systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                        } else {
                            Button("Enable") {
                                Task {
                                    let granted = await notificationManager.requestAuthorization()
                                    if !granted {
                                        showingPermissionAlert = true
                                    }
                                }
                            }
                            .buttonStyle(BorderlessButtonStyle())
                        }
                    }
                }
                
                if notificationManager.isAuthorized {
                    Section("Notification Types") {
                        Toggle("Achievement Unlocked", isOn: Binding(
                            get: { currentPreferences.achievementNotifications },
                            set: { currentPreferences.achievementNotifications = $0; savePreferences() }
                        ))
                        
                        Toggle("Treasure Found", isOn: Binding(
                            get: { currentPreferences.treasureFoundNotifications },
                            set: { currentPreferences.treasureFoundNotifications = $0; savePreferences() }
                        ))
                        
                        Toggle("Nearby Treasure Reminders", isOn: Binding(
                            get: { currentPreferences.nearbyTreasureReminders },
                            set: { currentPreferences.nearbyTreasureReminders = $0; savePreferences() }
                        ))
                    }
                    
                    Section("Reminder Settings") {
                        if currentPreferences.nearbyTreasureReminders {
                            Picker("Reminder Frequency", selection: Binding(
                                get: { currentPreferences.reminderInterval },
                                set: { currentPreferences.reminderInterval = $0; savePreferences() }
                            )) {
                                Text("Every 30 minutes").tag(TimeInterval(1800))
                                Text("Every hour").tag(TimeInterval(3600))
                                Text("Every 2 hours").tag(TimeInterval(7200))
                                Text("Every 4 hours").tag(TimeInterval(14400))
                                Text("Once daily").tag(TimeInterval(86400))
                            }
                        }
                    }
                    
                    Section("Notification Settings") {
                        Toggle("Sound", isOn: Binding(
                            get: { currentPreferences.soundEnabled },
                            set: { currentPreferences.soundEnabled = $0; savePreferences() }
                        ))
                        
                        Toggle("Badge App Icon", isOn: Binding(
                            get: { currentPreferences.badgeEnabled },
                            set: { currentPreferences.badgeEnabled = $0; savePreferences() }
                        ))
                    }
                    
                    Section("Quiet Hours") {
                        Toggle("Enable Quiet Hours", isOn: Binding(
                            get: { currentPreferences.quietHoursEnabled },
                            set: { currentPreferences.quietHoursEnabled = $0; savePreferences() }
                        ))
                        
                        if currentPreferences.quietHoursEnabled {
                            DatePicker("Start Time", selection: Binding(
                                get: { currentPreferences.quietHoursStart },
                                set: { currentPreferences.quietHoursStart = $0; savePreferences() }
                            ), displayedComponents: .hourAndMinute)
                            
                            DatePicker("End Time", selection: Binding(
                                get: { currentPreferences.quietHoursEnd },
                                set: { currentPreferences.quietHoursEnd = $0; savePreferences() }
                            ), displayedComponents: .hourAndMinute)
                            
                            Text("No notifications will be sent during quiet hours")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section {
                    Button("Clear Badge") {
                        notificationManager.clearBadge()
                    }
                    
                    Button("Test Achievement Notification") {
                        notificationManager.scheduleAchievementNotification(
                            achievement: "Test Achievement",
                            description: "This is a test notification"
                        )
                    }
                    
                    Button("Test Treasure Found Notification") {
                        notificationManager.scheduleTreasureFoundNotification(
                            treasureName: "Test Treasure",
                            emoji: "💎"
                        )
                    }
                } header: {
                    Text("Actions")
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.large)
            .alert("Permission Required", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive treasure hunt alerts.")
            }
        }
        .onAppear {
            notificationManager.checkAuthorizationStatus()
            setupPreferences()
        }
    }
    
    private func setupPreferences() {
        if preferences.isEmpty {
            let newPreferences = NotificationPreferences()
            modelContext.insert(newPreferences)
            savePreferences()
        }
        
        if let prefs = preferences.first {
            notificationManager.preferences = prefs
        }
    }
    
    private func savePreferences() {
        do {
            try modelContext.save()
            if let prefs = preferences.first {
                notificationManager.preferences = prefs
            }
        } catch {
            print("Error saving preferences: \(error)")
        }
    }
}