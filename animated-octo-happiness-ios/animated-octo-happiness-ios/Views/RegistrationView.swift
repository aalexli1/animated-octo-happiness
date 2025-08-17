//
//  RegistrationView.swift
//  animated-octo-happiness-ios
//
//  Created by Auto-Agent on 8/17/25.
//

import SwiftUI

struct RegistrationView: View {
    @ObservedObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var showingError = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, displayName, password, confirmPassword
    }
    
    var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        password == confirmPassword &&
        password.count >= 6
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Create Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Join the treasure hunt adventure!")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 15) {
                    TextField("Email", text: $email)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .textContentType(.emailAddress)
                        .focused($focusedField, equals: .email)
                        .onSubmit {
                            focusedField = .displayName
                        }
                    
                    TextField("Display Name (optional)", text: $displayName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.name)
                        .focused($focusedField, equals: .displayName)
                        .onSubmit {
                            focusedField = .password
                        }
                    
                    SecureField("Password (min 6 characters)", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            focusedField = .confirmPassword
                        }
                    
                    SecureField("Confirm Password", text: $confirmPassword)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.newPassword)
                        .focused($focusedField, equals: .confirmPassword)
                        .onSubmit {
                            if isFormValid {
                                Task {
                                    await signUp()
                                }
                            }
                        }
                    
                    if !password.isEmpty && password != confirmPassword && !confirmPassword.isEmpty {
                        Text("Passwords don't match")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    if !password.isEmpty && password.count < 6 {
                        Text("Password must be at least 6 characters")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
                .padding(.horizontal)
                
                Button(action: {
                    Task {
                        await signUp()
                    }
                }) {
                    Text("Sign Up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .disabled(!isFormValid || authService.isLoading)
                .padding(.horizontal)
                
                Spacer()
                
                Text("By creating an account, you agree to our Terms of Service and Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
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
    
    private func signUp() async {
        do {
            try await authService.register(
                email: email,
                password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
            dismiss()
        } catch {
            authService.errorMessage = error.localizedDescription
        }
    }
}