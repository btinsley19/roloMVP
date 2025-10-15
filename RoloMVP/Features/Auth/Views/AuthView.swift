//
//  AuthView.swift
//  RoloMVP
//

import SwiftUI
import Supabase

struct AuthView: View {
    @StateObject private var viewModel = AuthViewModel()
    @EnvironmentObject var appState: AppState
    @State private var isSignUpMode = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Logo/Icon
                    VStack(spacing: 16) {
                        Image(systemName: "person.2.crop.square.stack.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.roloPrimary)
                        
                        Text("Welcome to Rolo")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(isSignUpMode ? "Create your account" : "Sign in to continue")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Form
                    VStack(spacing: 16) {
                        // Email
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Email")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            TextField("your@email.com", text: $viewModel.email)
                                .textFieldStyle(.plain)
                                .keyboardType(.emailAddress)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding()
                                .background(Color.roloSecondaryBackground)
                                .cornerRadius(10)
                                .focused($focusedField, equals: .email)
                        }
                        
                        // Password
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Password")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            SecureField("Enter your password", text: $viewModel.password)
                                .textFieldStyle(.plain)
                                .textInputAutocapitalization(.never)
                                .padding()
                                .background(Color.roloSecondaryBackground)
                                .cornerRadius(10)
                                .focused($focusedField, equals: .password)
                        }
                        
                        // Error Message
                        if let errorMessage = viewModel.errorMessage {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(errorMessage.contains("Check your email") || errorMessage.contains("reset email sent") ? .green : .red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        
                        // Main Action Button
                        PrimaryButton(
                            title: isSignUpMode ? "Sign Up" : "Sign In",
                            action: {
                                Task {
                                    if isSignUpMode {
                                        await viewModel.signUp()
                                    } else {
                                        await viewModel.signIn()
                                    }
                                    
                                    if viewModel.isAuthenticated {
                                        // Get the current user ID from Supabase
                                        if let userId = try? await SupabaseClientProvider.shared.client.auth.session.user.id {
                                            appState.signIn(userId: userId)
                                        }
                                    }
                                }
                            },
                            isLoading: viewModel.isLoading,
                            fullWidth: true
                        )
                        .padding(.top, 8)
                        
                        // Forgot Password (only in sign in mode)
                        if !isSignUpMode {
                            Button {
                                Task {
                                    await viewModel.resetPassword()
                                }
                            } label: {
                                Text("Forgot Password?")
                                    .font(.subheadline)
                                    .foregroundColor(.roloPrimary)
                            }
                            .disabled(viewModel.isLoading)
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    // Toggle Sign Up / Sign In
                    VStack(spacing: 8) {
                        Text(isSignUpMode ? "Already have an account?" : "Don't have an account?")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Button {
                            withAnimation {
                                isSignUpMode.toggle()
                                viewModel.errorMessage = nil
                            }
                        } label: {
                            Text(isSignUpMode ? "Sign In" : "Sign Up")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.roloPrimary)
                        }
                    }
                    .padding(.top, 16)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .onChange(of: viewModel.isAuthenticated) { _, isAuth in
            if isAuth {
                // Authentication successful, AppState will handle navigation
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AppState())
}

