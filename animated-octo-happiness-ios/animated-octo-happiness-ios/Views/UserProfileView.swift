//
//  UserProfileView.swift
//  animated-octo-happiness-ios
//
//  Created by Auto-Agent on 8/17/25.
//

import SwiftUI
import PhotosUI

struct UserProfileView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var isEditingProfile = false
    @State private var displayName = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoImage: Image?
    @State private var showingDeleteConfirmation = false
    @State private var showingLogoutConfirmation = false
    @State private var showingMigrationView = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        if let photoImage = photoImage {
                            photoImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 80, height: 80)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.gray)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authService.currentUser?.displayName ?? "Guest User")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            if let email = authService.currentUser?.email {
                                Text(email)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else if authService.currentUser?.isAnonymous == true {
                                Text("Anonymous User")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
                
                if authService.currentUser?.isAnonymous == true {
                    Section {
                        Button(action: {
                            showingMigrationView = true
                        }) {
                            Label("Create Account", systemImage: "person.badge.plus")
                                .foregroundColor(.blue)
                        }
                    } header: {
                        Text("Account")
                    } footer: {
                        Text("Create an account to save your progress and sync across devices")
                            .font(.caption)
                    }
                }
                
                Section("Statistics") {
                    HStack {
                        Label("Total Score", systemImage: "star.fill")
                        Spacer()
                        Text("\(authService.currentUser?.totalScore ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Treasures Created", systemImage: "plus.circle.fill")
                        Spacer()
                        Text("\(authService.currentUser?.treasuresCreated?.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Treasures Found", systemImage: "checkmark.circle.fill")
                        Spacer()
                        Text("\(authService.currentUser?.treasuresFound?.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("Achievements", systemImage: "trophy.fill")
                        Spacer()
                        Text("\(authService.currentUser?.achievements.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                }
                
                if let achievements = authService.currentUser?.achievements,
                   !achievements.isEmpty {
                    Section("Achievements") {
                        ForEach(achievements, id: \.self) { achievement in
                            HStack {
                                Image(systemName: "rosette")
                                    .foregroundColor(.yellow)
                                Text(achievement)
                                Spacer()
                            }
                        }
                    }
                }
                
                Section("Preferences") {
                    NavigationLink(destination: UserPreferencesView(authService: authService)) {
                        Label("Settings", systemImage: "gearshape")
                    }
                    
                    NavigationLink(destination: Text("Privacy Policy")) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    
                    NavigationLink(destination: Text("Terms of Service")) {
                        Label("Terms of Service", systemImage: "doc.text")
                    }
                }
                
                Section {
                    Button(action: {
                        showingLogoutConfirmation = true
                    }) {
                        Label("Sign Out", systemImage: "arrow.right.square")
                            .foregroundColor(.red)
                    }
                    
                    if authService.currentUser?.isAnonymous == false {
                        Button(action: {
                            showingDeleteConfirmation = true
                        }) {
                            Label("Delete Account", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarItems(
                trailing: authService.currentUser?.isAnonymous == false ?
                Button("Edit") {
                    isEditingProfile = true
                    displayName = authService.currentUser?.displayName ?? ""
                } : nil
            )
            .sheet(isPresented: $isEditingProfile) {
                EditProfileView(
                    authService: authService,
                    displayName: $displayName,
                    selectedPhoto: $selectedPhoto,
                    photoImage: $photoImage
                )
            }
            .sheet(isPresented: $showingMigrationView) {
                MigrateAnonymousUserView(authService: authService)
            }
            .confirmationDialog("Sign Out", isPresented: $showingLogoutConfirmation) {
                Button("Sign Out", role: .destructive) {
                    authService.logout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to sign out?")
            }
            .confirmationDialog("Delete Account", isPresented: $showingDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        try await authService.deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. All your data will be permanently deleted.")
            }
        }
    }
}

struct EditProfileView: View {
    @ObservedObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    @Binding var displayName: String
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var photoImage: Image?
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Profile Photo") {
                    HStack {
                        if let photoImage = photoImage {
                            photoImage
                                .resizable()
                                .scaledToFill()
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 100, height: 100)
                                .foregroundColor(.gray)
                        }
                        
                        Spacer()
                        
                        PhotosPicker(selection: $selectedPhoto,
                                    matching: .images,
                                    photoLibrary: .shared()) {
                            Text("Change Photo")
                                .foregroundColor(.blue)
                        }
                        .onChange(of: selectedPhoto) { _, newItem in
                            Task {
                                if let data = try? await newItem?.loadTransferable(type: Data.self),
                                   let uiImage = UIImage(data: data) {
                                    photoImage = Image(uiImage: uiImage)
                                }
                            }
                        }
                    }
                }
                
                Section("Display Name") {
                    TextField("Display Name", text: $displayName)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                },
                trailing: Button("Save") {
                    Task {
                        try await authService.updateUserProfile(
                            displayName: displayName.isEmpty ? nil : displayName
                        )
                        dismiss()
                    }
                }
                .disabled(authService.isLoading)
            )
        }
    }
}

struct UserPreferencesView: View {
    @ObservedObject var authService: AuthenticationService
    @State private var notificationsEnabled = true
    @State private var locationSharingEnabled = true
    @State private var soundEnabled = true
    @State private var hapticFeedbackEnabled = true
    
    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("Push Notifications", isOn: $notificationsEnabled)
                Toggle("Sound Effects", isOn: $soundEnabled)
                Toggle("Haptic Feedback", isOn: $hapticFeedbackEnabled)
            }
            
            Section("Privacy") {
                Toggle("Share Location", isOn: $locationSharingEnabled)
            }
        }
        .navigationTitle("Settings")
        .onAppear {
            if let preferences = authService.currentUser?.preferences {
                notificationsEnabled = preferences.notificationsEnabled
                locationSharingEnabled = preferences.locationSharingEnabled
                soundEnabled = preferences.soundEnabled
                hapticFeedbackEnabled = preferences.hapticFeedbackEnabled
            }
        }
    }
}

struct MigrateAnonymousUserView: View {
    @ObservedObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var showingError = false
    
    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "person.badge.plus")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Create Your Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Keep all your progress and sync across devices")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                    
                    SecureField("Password (min 6 characters)", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                    
                    if !password.isEmpty && password != confirmPassword && !confirmPassword.isEmpty {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await migrateAccount()
                    }
                }) {
                    Text("Create Account")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid || authService.isLoading)
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
            .overlay {
                if authService.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") {
                    authService.errorMessage = nil
                }
            } message: {
                Text(authService.errorMessage ?? "An error occurred")
            }
            .onChange(of: authService.errorMessage) { _, newValue in
                showingError = newValue != nil
            }
            .onChange(of: authService.authState) { _, newState in
                if case .authenticated = newState {
                    dismiss()
                }
            }
        }
    }
    
    private func migrateAccount() async {
        do {
            try await authService.migrateAnonymousUser(to: email, password: password)
            dismiss()
        } catch {
            authService.errorMessage = error.localizedDescription
        }
    }
}