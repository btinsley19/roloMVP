//
//  RemindersService.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

protocol RemindersServiceProtocol {
    func list(contactId: UUID, includeNoDate: Bool) async throws -> [ContactReminder]
    func listUpcoming(userId: UUID, limit: Int) async throws -> [ContactReminder]
    func get(id: UUID) async throws -> ContactReminder
    func create(_ newReminder: NewContactReminder) async throws -> ContactReminder
    func delete(id: UUID) async throws
}

class RemindersService: RemindersServiceProtocol {
    private let logger = Logger.services
    let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func list(contactId: UUID, includeNoDate: Bool) async throws -> [ContactReminder] {
        logger.info("list reminders for contact: \(contactId.uuidString), includeNoDate: \(includeNoDate)")
        
        var query = client
            .from("contact_reminders")
            .select()
            .eq("contact_id", value: contactId.uuidString)
        
        if !includeNoDate {
            query = query.not("due_at", operator: .is, value: "null")
        }
        
        return try await query
            .order("due_at", ascending: true, nullsFirst: false)
            .execute()
            .value
    }
    
    func listUpcoming(userId: UUID, limit: Int = 10) async throws -> [ContactReminder] {
        logger.info("listUpcoming reminders for user: \(userId.uuidString)")
        
        return try await client
            .from("contact_reminders")
            .select()
            .eq("user_id", value: userId.uuidString)
            .not("due_at", operator: .is, value: "null")
            .gte("due_at", value: Date().ISO8601Format())
            .order("due_at", ascending: true)
            .limit(limit)
            .execute()
            .value
    }
    
    func get(id: UUID) async throws -> ContactReminder {
        logger.info("get reminder for id: \(id.uuidString)")
        
        return try await client
            .from("contact_reminders")
            .select()
            .eq("id", value: id.uuidString)
            .single()
            .execute()
            .value
    }
    
    func create(_ newReminder: NewContactReminder) async throws -> ContactReminder {
        logger.info("create reminder for contact: \(newReminder.contactId.uuidString)")
        
        return try await client
            .from("contact_reminders")
            .insert(newReminder, returning: .representation)
            .single()
            .execute()
            .value
    }
    
    func delete(id: UUID) async throws {
        logger.info("delete reminder for id: \(id.uuidString)")
        
        _ = try await client
            .from("contact_reminders")
            .delete()
            .eq("id", value: id.uuidString)
            .execute()
    }
}

