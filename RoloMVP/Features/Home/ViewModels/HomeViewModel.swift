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
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        logger.info("Loading home data")
        // TODO: Load recent news and upcoming reminders
    }
}

