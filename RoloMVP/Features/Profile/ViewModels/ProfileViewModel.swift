//
//  ProfileViewModel.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var userName: String = "User"
    @Published var userEmail: String = "user@example.com"
    
    private let logger = Logger.viewModels
    
    init() {
        // TODO: Load user profile from Supabase
        logger.info("ProfileViewModel initialized")
    }
    
    func signOut(appState: AppState) async {
        logger.info("User signing out")
        
        do {
            try await SupabaseClientProvider.shared.client.auth.signOut()
            
            // Update app state
            appState.signOut()
            
            logger.info("User signed out successfully")
        } catch {
            logger.error("Sign out failed: \(error.localizedDescription)")
        }
    }
}

