//
//  NotesService.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

protocol NotesServiceProtocol {
    func list(contactId: UUID) async throws -> [ContactNote]
    func get(id: UUID) async throws -> ContactNote
    func create(_ newNote: NewContactNote) async throws -> ContactNote
    func delete(id: UUID) async throws
}

class NotesService: NotesServiceProtocol {
    private let logger = Logger.services
    let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func list(contactId: UUID) async throws -> [ContactNote] {
        logger.info("list notes for contact: \(contactId.uuidString)")
        
        return try await client
            .from("contact_notes")
            .select()
            .eq("contact_id", value: contactId.uuidString)
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    func get(id: UUID) async throws -> ContactNote {
        logger.info("get note for id: \(id.uuidString)")
        
        return try await client
            .from("contact_notes")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func create(_ newNote: NewContactNote) async throws -> ContactNote {
        logger.info("create note for contact: \(newNote.contactId.uuidString)")
        
        return try await client
            .from("contact_notes")
            .insert(newNote, returning: .representation)
            .single()
            .execute()
            .value
    }
    
    func delete(id: UUID) async throws {
        logger.info("delete note for id: \(id.uuidString)")
        
        _ = try await client
            .from("contact_notes")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

