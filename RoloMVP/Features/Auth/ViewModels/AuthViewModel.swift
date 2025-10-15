//
//  AuthViewModel.swift
//  RoloMVP
//

import Foundation
import SwiftUI
import OSLog
import Supabase

@MainActor
class AuthViewModel: ObservableObject {
    @Published var email = ""
    @Published var password = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var isAuthenticated = false
    
    private let logger = Logger.viewModels
    private let supabase = SupabaseClientProvider.shared.client
    
    func signUp() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            logger.info("Signing up user: \(self.email)")
            
            let response = try await supabase.auth.signUp(
                email: email,
                password: password
            )
            
            logger.info("Sign up successful for user: \(response.user.id.uuidString)")
            
            // Check if email confirmation is required
            if response.session != nil {
                // User can sign in immediately (email confirmation disabled)
                isAuthenticated = true
                errorMessage = "Account created successfully!"
            } else {
                // Email confirmation required
                errorMessage = "Check your email to confirm your account!"
            }
        } catch {
            logger.error("Sign up failed: \(error.localizedDescription)")
            errorMessage = "Sign up failed: \(error.localizedDescription)"
        }
    }
    
    func signIn() async {
        guard validateInput() else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            logger.info("Signing in user: \(self.email)")
            
            let session = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            
            logger.info("Sign in successful for user: \(session.user.id.uuidString)")
            
            isAuthenticated = true
        } catch {
            logger.error("Sign in failed: \(error.localizedDescription)")
            errorMessage = "Sign in failed. Please check your credentials."
        }
    }
    
    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            logger.info("Signing out user")
            
            try await supabase.auth.signOut()
            
            isAuthenticated = false
            email = ""
            password = ""
            
            logger.info("Sign out successful")
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
            errorMessage = "Sign out failed: \(error.localizedDescription)"
        }
    }
    
    func resetPassword() async {
        guard !email.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        do {
            logger.info("Sending password reset email to: \(self.email)")
            
            try await supabase.auth.resetPasswordForEmail(email)
            
            errorMessage = "Password reset email sent! Check your inbox."
            
            logger.info("Password reset email sent")
        } catch {
            logger.error("Password reset failed: \(error.localizedDescription)")
            errorMessage = "Failed to send reset email: \(error.localizedDescription)"
        }
    }
    
    private func validateInput() -> Bool {
        if email.isEmpty {
            errorMessage = "Please enter your email"
            return false
        }
        
        if !email.contains("@") || !email.contains(".") {
            errorMessage = "Please enter a valid email address"
            return false
        }
        
        if password.isEmpty {
            errorMessage = "Please enter your password"
            return false
        }
        
        if password.count < 6 {
            errorMessage = "Password must be at least 6 characters"
            return false
        }
        
        return true
    }
}

