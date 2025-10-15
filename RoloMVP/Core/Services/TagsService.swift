//
//  TagsService.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

protocol TagsServiceProtocol {
    func listTags(owner: UUID) async throws -> [Tag]
    func getTag(id: UUID) async throws -> Tag
    func createTag(_ newTag: NewTag) async throws -> Tag
    func deleteTag(id: UUID) async throws
}

class TagsService: TagsServiceProtocol {
    private let logger = Logger.services
    let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func listTags(owner: UUID) async throws -> [Tag] {
        logger.info("listTags called for owner: \(owner.uuidString)")
        
        return try await client
            .from("tags")
            .select()
            .eq("user_id", value: owner.uuidString)
            .order("name", ascending: true)
            .execute()
            .value
    }
    
    func getTag(id: UUID) async throws -> Tag {
        logger.info("getTag called for id: \(id.uuidString)")
        
        return try await client
            .from("tags")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func createTag(_ newTag: NewTag) async throws -> Tag {
        logger.info("createTag called for: \(newTag.name)")
        
        return try await client
            .from("tags")
            .insert(newTag, returning: .representation)
            .single()
            .execute()
            .value
    }
    
    func deleteTag(id: UUID) async throws {
        logger.info("deleteTag called for id: \(id.uuidString)")
        
        _ = try await client
            .from("tags")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

