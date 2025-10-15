//
//  AppState.swift
//  RoloMVP
//

import Foundation
import SwiftUI
import Supabase

@MainActor
class AppState: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var isOnboardingComplete: Bool = false
    @Published var deepLinkedContactId: UUID?
    @Published var currentUserId: UUID?
    
    init() {
        // Load onboarding state from UserDefaults
        self.isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboardingComplete")
        
        // Check if user has active Supabase session on app launch
        Task { @MainActor in
            do {
                let session = try await SupabaseClientProvider.shared.client.auth.session
                self.isAuthenticated = true
                self.currentUserId = session.user.id
            } catch {
                // No active session, user needs to log in
                self.isAuthenticated = false
            }
        }
    }
    
    func signIn(userId: UUID) {
        self.isAuthenticated = true
        self.currentUserId = userId
        
        // Complete onboarding on first sign in
        if !isOnboardingComplete {
            completeOnboarding()
        }
    }
    
    func signOut() {
        self.isAuthenticated = false
        self.currentUserId = nil
        // Don't reset onboarding - user already knows how to use the app
    }
    
    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboardingComplete")
    }
    
    func handleDeepLink(contactId: UUID) {
        deepLinkedContactId = contactId
    }
}

