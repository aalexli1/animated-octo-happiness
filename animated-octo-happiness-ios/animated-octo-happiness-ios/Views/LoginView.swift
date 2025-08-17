//
//  LoginView.swift
//  animated-octo-happiness-ios
//
//  Created by Auto-Agent on 8/17/25.
//

import SwiftUI
import AuthenticationServices

struct LoginView: View {
    @StateObject private var authService = AuthenticationService()
    @State private var email = ""
    @State private var password = ""
    @State private var showingRegistration = false
    @State private var showingPasswordReset = false
    @State private var showingError = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "map.fill")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
                
                Text("Treasure Hunt")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Sign in to continue")
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
                            focusedField = .password
                        }
                    
                    SecureField("Password", text: $password)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .textContentType(.password)
                        .focused($focusedField, equals: .password)
                        .onSubmit {
                            Task {
                                await signIn()
                            }
                        }
                }
                .padding(.horizontal)
                
                VStack(spacing: 10) {
                    Button(action: {
                        Task {
                            await signIn()
                        }
                    }) {
                        Text("Sign In")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .disabled(authService.isLoading || email.isEmpty || password.isEmpty)
                    
                    Button(action: {
                        showingPasswordReset = true
                    }) {
                        Text("Forgot Password?")
                            .font(.footnote)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                Divider()
                    .padding(.horizontal)
                
                VStack(spacing: 10) {
                    SignInWithAppleButton(
                        .signIn,
                        onRequest: { request in
                            let nonce = authService.prepareSignInWithApple()
                            request.requestedScopes = [.fullName, .email]
                            request.nonce = nonce
                        },
                        onCompletion: { result in
                            Task {
                                await handleSignInWithApple(result)
                            }
                        }
                    )
                    .signInWithAppleButtonStyle(.black)
                    .frame(height: 50)
                    .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await signInAnonymously()
                        }
                    }) {
                        Text("Continue as Guest")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                
                Spacer()
                
                HStack {
                    Text("Don't have an account?")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                    
                    Button(action: {
                        showingRegistration = true
                    }) {
                        Text("Sign Up")
                            .font(.footnote)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.bottom)
            }
            .navigationBarHidden(true)
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
            .sheet(isPresented: $showingRegistration) {
                RegistrationView(authService: authService)
            }
            .sheet(isPresented: $showingPasswordReset) {
                PasswordResetView(authService: authService)
            }
            .onChange(of: authService.errorMessage) { _, newValue in
                showingError = newValue != nil
            }
        }
    }
    
    private func signIn() async {
        do {
            try await authService.login(email: email, password: password)
        } catch {
            authService.errorMessage = error.localizedDescription
        }
    }
    
    private func signInAnonymously() async {
        do {
            try await authService.signInAnonymously()
        } catch {
            authService.errorMessage = error.localizedDescription
        }
    }
    
    private func handleSignInWithApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let authorization):
            do {
                try await authService.handleSignInWithApple(authorization: authorization)
            } catch {
                authService.errorMessage = error.localizedDescription
            }
        case .failure(let error):
            authService.errorMessage = error.localizedDescription
        }
    }
}