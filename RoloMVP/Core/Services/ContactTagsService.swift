//
//  ContactTagsService.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

protocol ContactTagsServiceProtocol {
    func listForContact(contactId: UUID) async throws -> [ContactTag]
    func upsert(_ newContactTag: NewContactTag) async throws -> ContactTag
    func remove(contactId: UUID, tagId: UUID) async throws
}

class ContactTagsService: ContactTagsServiceProtocol {
    private let logger = Logger.services
    let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func listForContact(contactId: UUID) async throws -> [ContactTag] {
        logger.info("listForContact called for contact: \(contactId.uuidString)")
        
        return try await client
            .from("contact_tags")
            .select()
            .eq("contact_id", value: contactId.uuidString)
            .order("priority", ascending: false)
            .execute()
            .value
    }
    
    func upsert(_ newContactTag: NewContactTag) async throws -> ContactTag {
        logger.info("upsert ContactTag for contact: \(newContactTag.contactId.uuidString), tag: \(newContactTag.tagId.uuidString)")
        
        return try await client
            .from("contact_tags")
            .upsert(newContactTag, returning: .representation)
            .single()
            .execute()
            .value
    }
    
    func remove(contactId: UUID, tagId: UUID) async throws {
        logger.info("remove ContactTag for contact: \(contactId.uuidString), tag: \(tagId.uuidString)")
        
        _ = try await client
            .from("contact_tags")
            .delete()
            .eq("contact_id", value: contactId.uuidString)
            .eq("tag_id", value: tagId.uuidString)
            .execute()
    }
}

