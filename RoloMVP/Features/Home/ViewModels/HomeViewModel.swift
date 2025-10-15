//
//  HomeViewModel.swift
//  RoloMVP
//

import Foundation
import OSLog

@MainActor
class HomeViewModel: ObservableObject {
    @Published var recentNews: [ContactNews] = []
    @Published var upcomingReminders: [ContactReminder] = []
    @Published var isLoading = false
    
    private let logger = Logger.viewModels
    private let newsService: NewsServiceProtocol
    private let remindersService: RemindersServiceProtocol
    
    init(newsService: NewsServiceProtocol? = nil,
         remindersService: RemindersServiceProtocol? = nil) {
        self.newsService = newsService ?? NewsService()
        self.remindersService = remindersService ?? RemindersService()
    }
    
    func loadData(userId: UUID? = nil) async {
        guard let userId = userId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Loading home data")
        
        // Load data in parallel
        async let newsTask = loadRecentNews(userId: userId)
        async let remindersTask = loadUpcomingReminders(userId: userId)
        
        await newsTask
        await remindersTask
    }
    
    private func loadRecentNews(userId: UUID) async {
        do {
            // Get recent news from last 7 days (limit 20)
            let allNews = try await newsService.listRecent(userId: userId, limit: 20)
            
            // Filter for news from last 7 days
            let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
            self.recentNews = allNews.filter { $0.publishedAt >= sevenDaysAgo }
            
            logger.info("✅ Loaded \(self.recentNews.count) recent news items")
        } catch {
            // Check if cancelled - keep existing data
            if (error as NSError).code == NSURLErrorCancelled {
                logger.info("⏸️ News load cancelled, keeping existing data")
                // Don't clear recentNews - keep showing what we have
            } else {
                logger.error("Failed to load recent news: \(error.localizedDescription)")
                self.recentNews = []
            }
        }
    }
    
    private func loadUpcomingReminders(userId: UUID) async {
        do {
            self.upcomingReminders = try await remindersService.listUpcoming(userId: userId, limit: 5)
            logger.info("✅ Loaded \(self.upcomingReminders.count) upcoming reminders")
        } catch {
            // Check if cancelled - keep existing data
            if (error as NSError).code == NSURLErrorCancelled {
                logger.info("⏸️ Reminders load cancelled, keeping existing data")
                // Don't clear upcomingReminders - keep showing what we have
            } else {
                logger.error("Failed to load upcoming reminders: \(error.localizedDescription)")
            }
        }
    }
}

