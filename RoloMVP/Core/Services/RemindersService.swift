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
    func listUpcomingWithContacts(userId: UUID, limit: Int) async throws -> [ContactReminderWithContact]
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
    
    func listUpcomingWithContacts(userId: UUID, limit: Int = 10) async throws -> [ContactReminderWithContact] {
        logger.info("🔔 listUpcomingWithContacts for user: \(userId.uuidString)")
        
        // Use regular query with standard Supabase decoding
        do {
            // Get start of today to include all of today's reminders
            let calendar = Calendar.current
            let startOfToday = calendar.startOfDay(for: Date())
            
            // Fetch ALL reminders for user, then filter in Swift
            let allReminders: [ContactReminder] = try await client
                .from("contact_reminders")
                .select()
                .eq("user_id", value: userId.uuidString)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            // Separate into dated (upcoming) and undated reminders
            let upcomingReminders = allReminders
                .filter { reminder in
                    guard let dueDate = reminder.dueAt else { return false }
                    return dueDate >= startOfToday
                }
                .sorted { ($0.dueAt ?? Date.distantFuture) < ($1.dueAt ?? Date.distantFuture) }
            
            let noDueDateReminders = allReminders
                .filter { $0.dueAt == nil }
                .sorted { $0.createdAt > $1.createdAt }
            
            // Combine: dated reminders first (sorted by due date), then no-date reminders (sorted by creation)
            let combinedReminders = upcomingReminders + noDueDateReminders
            let reminders = Array(combinedReminders.prefix(limit))
            
            logger.info("   Found \(upcomingReminders.count) dated + \(noDueDateReminders.count) undated = \(reminders.count) total reminders")
            
            guard !reminders.isEmpty else {
                logger.info("   No reminders found, returning empty array")
                return []
            }
            
            // Fetch contact names for these reminders
            let uniqueContactIds = Array(Set(reminders.map { $0.contactId.uuidString }))
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
            
            // Map to ContactReminderWithContact
            let remindersWithContacts = reminders.map { reminder -> ContactReminderWithContact in
                ContactReminderWithContact(
                    id: reminder.id,
                    contactId: reminder.contactId,
                    userId: reminder.userId,
                    body: reminder.body,
                    dueAt: reminder.dueAt,
                    source: reminder.source,
                    originType: reminder.originType,
                    originId: reminder.originId,
                    createdAt: reminder.createdAt,
                    updatedAt: reminder.updatedAt,
                    contactName: contactNameMap[reminder.contactId]
                )
            }
            
            logger.info("   ✅ Found \(remindersWithContacts.count) reminders with contacts")
            return remindersWithContacts
        } catch {
            if (error as NSError).code == NSURLErrorCancelled {
                logger.info("   ⏸️ Request cancelled")
                throw error
            }
            logger.error("   ❌ Failed to fetch reminders: \(error)")
            return []
        }
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

