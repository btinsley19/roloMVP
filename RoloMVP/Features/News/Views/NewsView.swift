//
//  NewsView.swift
//  RoloMVP
//

import SwiftUI

struct NewsView: View {
    @StateObject private var viewModel = NewsViewModel()
    @EnvironmentObject var appState: AppState
    @State private var hasLoadedInitially = false
    
    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.allNews.isEmpty {
                    LoadingView(message: "Loading news...")
                } else if viewModel.allNews.isEmpty {
                    EmptyStateView(
                        icon: "newspaper",
                        title: "No News Yet",
                        message: "News and updates from your network will appear here. Tap 'Fetch News' on individual contacts to get started."
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.allNews) { news in
                                NewsDetailCard(news: news)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("News")
            .task {
                // Only load once on initial view appearance
                guard !hasLoadedInitially else { 
                    print("📰 NewsView: Already loaded, skipping")
                    return 
                }
                print("📰 NewsView: Initial load starting")
                hasLoadedInitially = true
                await viewModel.loadNews(userId: appState.currentUserId)
            }
            .refreshable {
                print("📰 NewsView: Pull to refresh triggered")
                await viewModel.loadNews(userId: appState.currentUserId)
            }
        }
    }
}

struct NewsDetailCard: View {
    let news: ContactNews
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Source and date
            HStack {
                Label(news.source, systemImage: "newspaper")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(Formatters.shortDateFormatter.string(from: news.publishedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Title
            Text(news.title)
                .font(.headline)
            
            // Summary
            Text(news.summary)
                .font(.body)
                .foregroundColor(.secondary)
            
            // Topics
            if let topics = news.topics, !topics.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(topics, id: \.self) { topic in
                            TagPill(name: topic, color: .blue)
                        }
                    }
                }
            }
            
            // Actions
            HStack {
                if let url = URL(string: news.url) {
                    Link(destination: url) {
                        Label("Read More", systemImage: "arrow.up.right")
                            .font(.caption)
                    }
                }
                
                Spacer()
                
                Button {
                    // TODO: Draft message action
                } label: {
                    Label("Draft Message", systemImage: "message")
                        .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.roloSecondaryBackground)
        .cornerRadius(12)
    }
}

#Preview {
    NewsView()
}

