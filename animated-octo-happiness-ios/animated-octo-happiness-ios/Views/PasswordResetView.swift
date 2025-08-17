//
//  PasswordResetView.swift
//  animated-octo-happiness-ios
//
//  Created by Auto-Agent on 8/17/25.
//

import SwiftUI

struct PasswordResetView: View {
    @ObservedObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var showingSuccess = false
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "lock.rotation")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                    .padding(.top, 40)
                
                Text("Reset Password")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Enter your email address and we'll send you instructions to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                TextField("Email", text: $email)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textContentType(.emailAddress)
                    .padding(.horizontal)
                    .onSubmit {
                        Task {
                            await sendResetEmail()
                        }
                    }
                
                Button(action: {
                    Task {
                        await sendResetEmail()
                    }
                }) {
                    Text("Send Reset Email")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(email.isEmpty ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(email.isEmpty || authService.isLoading)
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
            .alert("Success", isPresented: $showingSuccess) {
                Button("OK") {
                    dismiss()
                }
            } message: {
                Text("Password reset instructions have been sent to your email.")
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
        }
    }
    
    private func sendResetEmail() async {
        do {
            try await authService.sendPasswordResetEmail(to: email)
            showingSuccess = true
        } catch {
            authService.errorMessage = error.localizedDescription
        }
    }
}