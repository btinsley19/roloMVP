//
//  HomeView.swift
//  RoloMVP
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @EnvironmentObject var appState: AppState
    @State private var hasLoadedInitially = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Welcome to Rolo")
                            .font(.roloTitle)
                        
                        Text("Stay connected with your network")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Quick Actions
                    VStack(spacing: 12) {
                        NavigationLink {
                            ContactsListView()
                        } label: {
                            HStack {
                                Image(systemName: "person.2.fill")
                                    .font(.title2)
                                    .foregroundColor(.white)
                                    .frame(width: 50, height: 50)
                                    .background(Color.roloPrimary)
                                    .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Open Contacts")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("View and manage your network")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.roloSecondaryBackground)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // News Preview
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent News")
                                .font(.roloHeadline)
                            
                            Spacer()
                            
                            NavigationLink {
                                NewsView()
                            } label: {
                                Text("See All")
                                    .font(.caption)
                                    .foregroundColor(.roloPrimary)
                            }
                        }
                        .padding(.horizontal)
                        
                        if viewModel.recentNews.isEmpty {
                            Text("No recent news")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.recentNews) { news in
                                        NewsCardView(news: news)
                                            .frame(width: 280)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                // Only load once on initial view appearance
                guard !hasLoadedInitially else { return }
                hasLoadedInitially = true
                await viewModel.loadData(userId: appState.currentUserId)
            }
            .refreshable {
                await viewModel.loadData(userId: appState.currentUserId)
            }
        }
    }
}

// Simple news card for home preview
struct NewsCardView: View {
    let news: ContactNews
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.title)
                .font(.headline)
                .lineLimit(2)
            
            Text(news.summary)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(3)
            
            HStack {
                Text(news.source)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(Formatters.shortDateFormatter.string(from: news.publishedAt))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color.roloSecondaryBackground)
        .cornerRadius(12)
    }
}

#Preview {
    HomeView()
        .environmentObject(AppState())
}

