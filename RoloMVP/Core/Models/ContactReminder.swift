//
//  ContactReminder.swift
//  RoloMVP
//

import Foundation

struct ContactReminder: Identifiable, Codable, Equatable {
    let id: UUID
    let contactId: UUID
    let userId: UUID
    let body: String
    let dueAt: Date?
    let source: ReminderSource
    let originType: OriginType?
    let originId: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    enum ReminderSource: String, Codable {
        case manual
        case aiSuggested = "ai_suggested"
    }
    
    enum OriginType: String, Codable {
        case note
        case chat
        case system
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case userId = "user_id"
        case body
        case dueAt = "due_at"
        case source
        case originType = "origin_type"
        case originId = "origin_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// Reminder with contact information included
struct ContactReminderWithContact: Identifiable, Codable, Equatable {
    let id: UUID
    let contactId: UUID
    let userId: UUID
    let body: String
    let dueAt: Date?
    let source: ContactReminder.ReminderSource
    let originType: ContactReminder.OriginType?
    let originId: UUID?
    let createdAt: Date
    let updatedAt: Date
    
    // Contact info (joined from contacts table)
    let contactName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case userId = "user_id"
        case body
        case dueAt = "due_at"
        case source
        case originType = "origin_type"
        case originId = "origin_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case contactName = "contact_name"
    }
}

