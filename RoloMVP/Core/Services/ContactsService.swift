//
//  ContactsService.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

protocol ContactsServiceProtocol {
    func fetchContacts(owner: UUID, search: String?, limit: Int, offset: Int) async throws -> [Contact]
    func getContact(id: UUID) async throws -> Contact
    func createContact(_ newContact: NewContact) async throws -> Contact
    func updateContactBasicInfo(id: UUID, fullName: String?, companyName: String?, position: String?, linkedinUrl: String?) async throws -> Contact
    func updateContactRelationship(id: UUID, relationshipSummary: String?, relationshipPriority: Int?) async throws -> Contact
    func deleteContact(id: UUID) async throws
}

class ContactsService: ContactsServiceProtocol {
    private let logger = Logger.services
    let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func fetchContacts(owner: UUID, search: String?, limit: Int = 50, offset: Int = 0) async throws -> [Contact] {
        logger.info("fetchContacts called for owner: \(owner.uuidString), search: \(search ?? "nil")")
        
        var query = client
            .from("contacts")
            .select()
            .eq("user_id", value: owner.uuidString)
            .order("updated_at", ascending: false)
            .range(from: offset, to: offset + limit - 1)
        
        // Note: Complex search filters can be added when needed
        // For now, basic filtering works with multiple .eq() or .like() calls
        
        return try await query.execute().value
    }
    
    func getContact(id: UUID) async throws -> Contact {
        logger.info("getContact called for id: \(id.uuidString)")
        
        return try await client
            .from("contacts")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func createContact(_ newContact: NewContact) async throws -> Contact {
        logger.info("createContact called for: \(newContact.fullName)")
        
        return try await client
            .from("contacts")
            .insert(newContact, returning: .representation)
            .single()
            .execute()
            .value
    }
    
    func updateContactBasicInfo(id: UUID, fullName: String?, companyName: String?, position: String?, linkedinUrl: String?) async throws -> Contact {
        logger.info("updateContactBasicInfo called for id: \(id.uuidString)")
        
        let updates = UpdateContactBasicInfo(
            fullName: fullName,
            companyName: companyName,
            position: position,
            linkedinUrl: linkedinUrl,
            updatedAt: Date().ISO8601Format()
        )
        
        return try await client
            .from("contacts")
            .update(updates, returning: .representation)
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func updateContactRelationship(id: UUID, relationshipSummary: String?, relationshipPriority: Int?) async throws -> Contact {
        logger.info("updateContactRelationship called for id: \(id.uuidString)")
        
        let updates = UpdateContactRelationship(
            relationshipSummary: relationshipSummary,
            relationshipPriority: relationshipPriority,
            updatedAt: Date().ISO8601Format()
        )
        
        return try await client
            .from("contacts")
            .update(updates, returning: .representation)
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func deleteContact(id: UUID) async throws {
        logger.info("deleteContact called for id: \(id.uuidString)")
        
        _ = try await client
            .from("contacts")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

