//
//  ProfileSwitcherView.swift
//  animated-octo-happiness-ios
//
//  Created on 8/17/25.
//

import SwiftUI
import SwiftData

struct ProfileSwitcherView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @Environment(\.dismiss) private var dismiss
    @State private var showingCreateProfile = false
    @State private var profileToDelete: PlayerProfile?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                Section("Active Profile") {
                    if let current = persistenceManager.currentProfile {
                        ProfileRow(profile: current, isActive: true)
                    }
                }
                
                Section("All Profiles") {
                    ForEach(persistenceManager.allProfiles) { profile in
                        ProfileRow(profile: profile, isActive: profile.id == persistenceManager.currentProfile?.id)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                Task {
                                    try? await persistenceManager.switchProfile(to: profile)
                                    dismiss()
                                }
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                if persistenceManager.allProfiles.count > 1 {
                                    Button(role: .destructive) {
                                        profileToDelete = profile
                                        showDeleteConfirmation = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                
                Section {
                    Button(action: { showingCreateProfile = true }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                            Text("Create New Profile")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle("Player Profiles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingCreateProfile) {
                CreateProfileView()
            }
            .alert("Delete Profile?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let profile = profileToDelete {
                        Task {
                            try? await persistenceManager.deleteProfile(profile)
                        }
                    }
                }
            } message: {
                if let profile = profileToDelete {
                    Text("Are you sure you want to delete \(profile.name)? This will also delete all associated game data.")
                }
            }
        }
    }
}

struct ProfileRow: View {
    let profile: PlayerProfile
    let isActive: Bool
    
    var body: some View {
        HStack {
            Text(profile.avatarEmoji)
                .font(.largeTitle)
                .frame(width: 50, height: 50)
                .background(profile.color.opacity(0.2))
                .clipShape(Circle())
            
            VStack(alignment: .leading) {
                Text(profile.name)
                    .font(.headline)
                
                if let stats = profile.statistics {
                    HStack(spacing: 12) {
                        Label("\(stats.totalTreasuresFound)", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Label("\(stats.totalPoints)", systemImage: "trophy.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 4)
    }
}

struct CreateProfileView: View {
    @EnvironmentObject var persistenceManager: PersistenceManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var profileName = ""
    @State private var selectedEmoji = "🧑‍💻"
    @State private var selectedColor = "blue"
    @State private var showingEmojiPicker = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Profile Name") {
                    TextField("Enter name", text: $profileName)
                }
                
                Section("Avatar") {
                    HStack {
                        Text(selectedEmoji)
                            .font(.system(size: 60))
                            .frame(width: 80, height: 80)
                            .background(Color(selectedColor).opacity(0.2))
                            .clipShape(Circle())
                        
                        Spacer()
                        
                        Button("Choose Emoji") {
                            showingEmojiPicker = true
                        }
                    }
                }
                
                Section("Avatar Color") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                        ForEach(PlayerProfile.availableColors, id: \.name) { colorItem in
                            Circle()
                                .fill(colorItem.color)
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Circle()
                                        .stroke(selectedColor == colorItem.name ? Color.primary : Color.clear, lineWidth: 3)
                                )
                                .onTapGesture {
                                    selectedColor = colorItem.name
                                }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("New Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        Task {
                            try? await persistenceManager.createProfile(
                                name: profileName,
                                emoji: selectedEmoji,
                                color: selectedColor
                            )
                            dismiss()
                        }
                    }
                    .disabled(profileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .sheet(isPresented: $showingEmojiPicker) {
                EmojiPickerView(selectedEmoji: $selectedEmoji)
            }
        }
    }
}

struct EmojiPickerView: View {
    @Binding var selectedEmoji: String
    @Environment(\.dismiss) private var dismiss
    
    let columns = Array(repeating: GridItem(.flexible()), count: 6)
    
    var body: some View {
        NavigationView {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(PlayerProfile.availableEmojis, id: \.self) { emoji in
                        Text(emoji)
                            .font(.largeTitle)
                            .frame(width: 50, height: 50)
                            .background(selectedEmoji == emoji ? Color.blue.opacity(0.2) : Color.clear)
                            .clipShape(Circle())
                            .onTapGesture {
                                selectedEmoji = emoji
                                dismiss()
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Choose Avatar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ProfileSwitcherView()
        .environmentObject(PersistenceManager.shared)
}