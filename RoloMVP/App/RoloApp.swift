//
//  RoloApp.swift
//  RoloMVP
//
//  Created by Brian Tinsley on 10/9/25.
//

import SwiftUI

@main
struct RoloApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            if !appState.isAuthenticated {
                // Show auth screen if not authenticated
                AuthView()
                    .environmentObject(appState)
            } else if !appState.isOnboardingComplete {
                // Show onboarding after first sign up
                OnboardingView()
                    .environmentObject(appState)
            } else {
                // Show main app
                MainTabView()
                    .environmentObject(appState)
            }
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)
            .environmentObject(appState)
            
            NavigationStack {
                ContactsListView(userId: appState.currentUserId)
            }
            .tabItem {
                Label("Contacts", systemImage: "person.2.fill")
            }
            .tag(1)
            .environmentObject(appState)
            
            AIChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(2)
            
            NewsView()
                .tabItem {
                    Label("News", systemImage: "newspaper.fill")
                }
                .tag(3)
            
            ProfileView() 
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
                .tag(4)
        }
    }
}

// Placeholder onboarding view
struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.2.crop.square.stack.fill")
                .font(.system(size: 80))
                .foregroundColor(.roloPrimary)
            
            Text("Welcome to Rolo")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your personal CRM for meaningful connections")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
            
            PrimaryButton(title: "Get Started", action: {
                appState.completeOnboarding()
            }, fullWidth: true)
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}

