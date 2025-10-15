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
    func get(id: UUID) async throws -> ContactNews
    func create(_ newNews: NewContactNews) async throws -> ContactNews
    func delete(id: UUID) async throws
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
            .order("published_at", ascending: false)
            .execute()
            .value
    }
    
    func listRecent(userId: UUID, limit: Int = 20) async throws -> [ContactNews] {
        logger.info("listRecent news for user: \(userId.uuidString)")
        
        // Get news for all contacts belonging to the user
        // Note: This requires a join or we can fetch contact IDs first
        // For now, returning all news ordered by published_at
        return try await client
            .from("contact_news")
            .select()
            .order("published_at", ascending: false)
            .limit(limit)
            .execute()
            .value
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
}

