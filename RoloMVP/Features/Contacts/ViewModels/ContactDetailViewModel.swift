//
//  ContactDetailViewModel.swift
//  RoloMVP
//

import Foundation
import OSLog

@MainActor
class ContactDetailViewModel: ObservableObject {
    @Published var contact: Contact?
    @Published var tags: [(tag: Tag, contactTag: ContactTag)] = []
    @Published var notes: [ContactNote] = []
    @Published var reminders: [ContactReminder] = []
    @Published var news: [ContactNews] = []
    @Published var isLoading = false
    @Published var isFetchingNews = false
    @Published var error: ServiceError?
    
    private let logger = Logger.viewModels
    private let contactId: UUID
    let contactsService: ContactsServiceProtocol  // Made internal for EditContactSheet
    private let tagsService: TagsServiceProtocol
    private let contactTagsService: ContactTagsServiceProtocol
    private let notesService: NotesServiceProtocol
    private let remindersService: RemindersServiceProtocol
    private let newsService: NewsServiceProtocol
    
    init(contactId: UUID,
         contactsService: ContactsServiceProtocol? = nil,
         tagsService: TagsServiceProtocol? = nil,
         contactTagsService: ContactTagsServiceProtocol? = nil,
         notesService: NotesServiceProtocol? = nil,
         remindersService: RemindersServiceProtocol? = nil,
         newsService: NewsServiceProtocol? = nil) {
        self.contactId = contactId
        self.contactsService = contactsService ?? ContactsService()
        self.tagsService = tagsService ?? TagsService()
        self.contactTagsService = contactTagsService ?? ContactTagsService()
        self.notesService = notesService ?? NotesService()
        self.remindersService = remindersService ?? RemindersService()
        self.newsService = newsService ?? NewsService()
    }
    
    func loadContact() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            logger.info("Loading contact: \(self.contactId.uuidString)")
            contact = try await contactsService.getContact(id: self.contactId)
        } catch let error as ServiceError {
            logger.error("Failed to load contact: \(error.localizedDescription)")
            self.error = error
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            self.error = .unknown(error.localizedDescription)
        }
    }
    
    func loadTags() async {
        do {
            let contactTags = try await contactTagsService.listForContact(contactId: self.contactId)
            
            // Fetch full tag details for each contact_tag
            var loadedTags: [(tag: Tag, contactTag: ContactTag)] = []
            for contactTag in contactTags {
                do {
                    let tag = try await tagsService.getTag(id: contactTag.tagId)
                    loadedTags.append((tag: tag, contactTag: contactTag))
                } catch {
                    logger.error("Failed to load tag \(contactTag.tagId.uuidString): \(error.localizedDescription)")
                }
            }
            
            // Sort by priority (highest first)
            tags = loadedTags.sorted { $0.contactTag.priority > $1.contactTag.priority }
        } catch {
            logger.error("Failed to load tags: \(error.localizedDescription)")
        }
    }
    
    func loadNotes() async {
        do {
            notes = try await notesService.list(contactId: self.contactId)
        } catch {
            logger.error("Failed to load notes: \(error.localizedDescription)")
        }
    }
    
    func loadReminders() async {
        do {
            reminders = try await remindersService.list(contactId: self.contactId, includeNoDate: true)
        } catch {
            logger.error("Failed to load reminders: \(error.localizedDescription)")
        }
    }
    
    func loadNews() async {
        do {
            news = try await newsService.list(contactId: self.contactId)
        } catch {
            logger.error("Failed to load news: \(error.localizedDescription)")
        }
    }
    
    func fetchNews() async {
        isFetchingNews = true
        defer { isFetchingNews = false }
        
        do {
            logger.info("Fetching news from NewsAPI for contact: \(self.contactId.uuidString)")
            let fetchedNews = try await newsService.fetchNews(contactId: self.contactId)
            // Reload news from database to get complete list
            await loadNews()
            logger.info("Successfully fetched \(fetchedNews.count) news articles")
        } catch let error as ServiceError {
            logger.error("Failed to fetch news: \(error.localizedDescription)")
            self.error = error
        } catch {
            logger.error("Unexpected error fetching news: \(error.localizedDescription)")
            self.error = .unknown(error.localizedDescription)
        }
    }
}


