//
//  NewsService.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

protocol NewsServiceProtocol {
    func list(contactId: UUID) async throws -> [ContactNews]
    func listRecent(userId: UUID, limit: Int) async throws -> [ContactNews]
    func listRecentWithContacts(userId: UUID, limit: Int) async throws -> [ContactNewsWithContact]
    func get(id: UUID) async throws -> ContactNews
    func create(_ newNews: NewContactNews) async throws -> ContactNews
    func delete(id: UUID) async throws
    func fetchNews(contactId: UUID) async throws -> [ContactNews]
}

class NewsService: NewsServiceProtocol {
    private let logger = Logger.services
    let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func list(contactId: UUID) async throws -> [ContactNews] {
        logger.info("list news for contact: \(contactId.uuidString)")
        
        return try await client
            .from("contact_news")
            .select()
            .eq("contact_id", value: contactId.uuidString)
            .order("fetched_at", ascending: false)
            .execute()
            .value
    }
    
    func listRecent(userId: UUID, limit: Int = 20) async throws -> [ContactNews] {
        logger.info("📰 listRecent news for user: \(userId.uuidString)")
        
        // Lightweight struct just for getting contact IDs
        struct ContactId: Codable {
            let id: UUID
        }
        
        // Step 1: Get user's contact IDs
        let contactsResponse: [ContactId]
        do {
            contactsResponse = try await client
                .from("contacts")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            logger.info("   Found \(contactsResponse.count) contacts")
        } catch {
            // Check if request was cancelled - throw it so ViewModel can handle
            if (error as NSError).code == NSURLErrorCancelled {
                logger.info("   ⏸️ Request cancelled (likely due to refresh)")
                throw error
            }
            logger.error("   ❌ Failed to fetch contacts: \(error)")
            return []
        }
        
        guard !contactsResponse.isEmpty else {
            logger.info("   No contacts found, returning empty array")
            return []
        }
        
        let contactIds = contactsResponse.map { $0.id.uuidString }
        logger.info("   Contact IDs: \(contactIds.joined(separator: ", "))")
        
        // Step 2: Get news for those contacts
        do {
            let news: [ContactNews] = try await client
                .from("contact_news")
                .select("*")
                .in("contact_id", values: contactIds)
                .order("published_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            logger.info("   ✅ Found \(news.count) news items")
            return news
        } catch {
            // Check if request was cancelled - throw it so ViewModel can handle
            if (error as NSError).code == NSURLErrorCancelled {
                logger.info("   ⏸️ Request cancelled (likely due to refresh)")
                throw error
            }
            logger.error("   ❌ Failed to fetch news: \(error)")
            // This might just mean no news exists yet
            return []
        }
    }
    
    func listRecentWithContacts(userId: UUID, limit: Int = 20) async throws -> [ContactNewsWithContact] {
        logger.info("📰 listRecentWithContacts for user: \(userId.uuidString)")
        
        // Use regular query with standard Supabase decoding
        do {
            // Get user's contact IDs first
            struct ContactId: Codable {
                let id: UUID
            }
            
            let contactsResponse: [ContactId] = try await client
                .from("contacts")
                .select("id")
                .eq("user_id", value: userId.uuidString)
                .execute()
                .value
            
            guard !contactsResponse.isEmpty else {
                logger.info("   No contacts found, returning empty array")
                return []
            }
            
            let contactIds = contactsResponse.map { $0.id.uuidString }
            logger.info("   Found \(contactIds.count) contacts")
            
            // Fetch news with standard decoding
            let news: [ContactNews] = try await client
                .from("contact_news")
                .select()
                .in("contact_id", values: contactIds)
                .order("published_at", ascending: false)
                .limit(limit)
                .execute()
                .value
            
            logger.info("   Found \(news.count) news items, now fetching contact names...")
            
            // Fetch contact names for these news items
            let uniqueContactIds = Array(Set(news.map { $0.contactId.uuidString }))
            struct ContactNameInfo: Codable {
                let id: UUID
                let full_name: String
            }
            
            let contacts: [ContactNameInfo] = try await client
                .from("contacts")
                .select("id, full_name")
                .in("id", values: uniqueContactIds)
                .execute()
                .value
            
            // Create lookup dictionary
            let contactNameMap = Dictionary(uniqueKeysWithValues: contacts.map { ($0.id, $0.full_name) })
            
            // Map to ContactNewsWithContact
            let newsWithContacts = news.map { newsItem -> ContactNewsWithContact in
                ContactNewsWithContact(
                    id: newsItem.id,
                    contactId: newsItem.contactId,
                    source: newsItem.source,
                    title: newsItem.title,
                    url: newsItem.url,
                    summary: newsItem.summary,
                    publishedAt: newsItem.publishedAt,
                    fetchedAt: newsItem.fetchedAt,
                    topics: newsItem.topics,
                    createdAt: newsItem.createdAt,
                    contactName: contactNameMap[newsItem.contactId]
                )
            }
            
            logger.info("   ✅ Found \(newsWithContacts.count) news items with contacts")
            return newsWithContacts
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                logger.info("   ⏸️ Request cancelled")
                throw error
            }
            logger.error("   ❌ Failed to fetch news: \(error)")
            return []
        }
    }
    
    func get(id: UUID) async throws -> ContactNews {
        logger.info("get news for id: \(id.uuidString)")
        
        return try await client
            .from("contact_news")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func create(_ newNews: NewContactNews) async throws -> ContactNews {
        logger.info("create news for contact: \(newNews.contactId.uuidString)")
        
        return try await client
            .from("contact_news")
            .insert(newNews, returning: .representation)
            .single()
            .execute()
            .value
    }
    
    func delete(id: UUID) async throws {
        logger.info("delete news for id: \(id.uuidString)")
        
        _ = try await client
            .from("contact_news")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
    
    func fetchNews(contactId: UUID) async throws -> [ContactNews] {
        logger.info("fetchNews from NewsAPI for contact: \(contactId.uuidString)")
        
        // Get the function URL from environment
        let supabaseURL = Config.supabaseURL
        
        // Build edge function URL
        let functionURL = supabaseURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        
        guard let edgeFunctionURL = URL(string: "https://\(functionURL)/functions/v1/fetch-contact-news") else {
            throw ServiceError.badRequest("Invalid Supabase URL")
        }
        
        // Get auth session (same as AIChatService)
        let session = try await client.auth.session
        let accessToken = session.accessToken
        
        logger.info("Got access token for news fetch")
        
        // Prepare request body - use snake_case to match edge function
        let body: [String: Any] = [
            "contactId": contactId.uuidString
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        // Create request
        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        request.timeoutInterval = 30
        
        logger.info("Calling Edge Function: \(edgeFunctionURL)")
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.unknown("Invalid HTTP response")
        }
        
        logger.info("Edge Function response status: \(httpResponse.statusCode)")
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("Edge function error (\(httpResponse.statusCode)): \(errorMessage)")
            throw ServiceError.serverError(httpResponse.statusCode)
        }
        
        // Parse response
        struct FetchNewsResponse: Decodable {
            let success: Bool
            let articlesSaved: Int?
        }
        
        let decoded = try JSONDecoder().decode(FetchNewsResponse.self, from: data)
        
        guard decoded.success else {
            throw ServiceError.badRequest("Failed to fetch news")
        }
        
        logger.info("Successfully fetched \(decoded.articlesSaved ?? 0) articles")
        
        // Return empty array, caller will reload from database
        return []
    }
}

