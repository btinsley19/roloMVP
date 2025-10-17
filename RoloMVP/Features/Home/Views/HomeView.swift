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
                    
                    // Reminders Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Upcoming Reminders")
                            .font(.roloHeadline)
                            .padding(.horizontal)
                        
                        if viewModel.upcomingReminders.isEmpty {
                            Text("No upcoming reminders")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        } else {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(viewModel.upcomingReminders) { reminder in
                                        ReminderCardView(reminder: reminder)
                                            .frame(width: 280)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                    
                    // News Preview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent News")
                            .font(.roloHeadline)
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

// News card with contact name for home preview
struct NewsCardView: View {
    let news: ContactNewsWithContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Contact name at the top
            if let contactName = news.contactName {
                Text(contactName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.roloPrimary)
            }
            
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

// Reminder card with contact name for home preview
struct ReminderCardView: View {
    let reminder: ContactReminderWithContact
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Contact name at the top
            if let contactName = reminder.contactName {
                Text(contactName)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.orange)
            }
            
            Text(reminder.body)
                .font(.body)
                .lineLimit(3)
            
            HStack {
                Image(systemName: "bell.fill")
                    .font(.caption2)
                    .foregroundColor(.orange)
                
                if let dueAt = reminder.dueAt {
                    Text(Formatters.shortDateFormatter.string(from: dueAt))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No due date")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
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

