//
//  ProfileView.swift
//  RoloMVP
//

import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileViewModel()
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        AvatarView(photoUrl: nil, fullName: viewModel.userName, size: 60)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(viewModel.userName)
                                .font(.headline)
                            
                            Text(viewModel.userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.leading, 8)
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Settings") {
                    NavigationLink {
                        Text("Notifications settings coming soon")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        Text("Preferences coming soon")
                    } label: {
                        Label("Preferences", systemImage: "gear")
                    }
                }
                
                Section("About") {
                    NavigationLink {
                        Text("Help & Support coming soon")
                    } label: {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    NavigationLink {
                        Text("Privacy Policy coming soon")
                    } label: {
                        Label("Privacy Policy", systemImage: "lock.shield")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.signOut(appState: appState)
                        }
                    } label: {
                        HStack {
                            Spacer()
                            Label("Sign Out", systemImage: "arrow.right.square")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Profile")
        }
    }
}

#Preview {
    ProfileView()
}

