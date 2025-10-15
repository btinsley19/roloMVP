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
    
    func loadNews() async {
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Loading all news")
        // TODO: Implement fetching news across all contacts
        // For now, return empty
        allNews = []
    }
}

