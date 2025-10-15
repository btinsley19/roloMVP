//
//  NewsViewModel.swift
//  RoloMVP
//

import Foundation
import OSLog

@MainActor
class NewsViewModel: ObservableObject {
    @Published var allNews: [ContactNews] = []
    @Published var isLoading = false
    @Published var error: ServiceError?
    
    private let logger = Logger.viewModels
    private let newsService: NewsServiceProtocol
    
    init(newsService: NewsServiceProtocol? = nil) {
        self.newsService = newsService ?? NewsService()
    }
    
    func loadNews(userId: UUID? = nil) async {
        guard let userId = userId else {
            logger.warning("No userId provided, cannot load news")
            return
        }
        
        let startTime = Date()
        isLoading = true
        defer { 
            isLoading = false
            let elapsed = Date().timeIntervalSince(startTime)
            logger.info("⏱️ News load took \(String(format: "%.2f", elapsed))s")
        }
        
        do {
            logger.info("🔄 Starting news fetch from database...")
            self.allNews = try await newsService.listRecent(userId: userId, limit: 50)
            logger.info("✅ Successfully loaded \(self.allNews.count) news items from database")
        } catch let error as ServiceError {
            logger.error("❌ Service error loading news: \(error.localizedDescription)")
            self.error = error
        } catch {
            // Check if cancelled - this is normal during refresh, keep existing data
            if (error as NSError).code == NSURLErrorCancelled {
                logger.warning("⏸️ Database query was cancelled - keeping existing \(self.allNews.count) items")
                // Don't clear allNews - keep showing what we have
            } else {
                logger.error("❌ Unexpected error loading news: \(error.localizedDescription)")
                self.error = .unknown(error.localizedDescription)
            }
        }
    }
}

