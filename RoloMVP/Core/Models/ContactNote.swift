//
//  ContactNote.swift
//  RoloMVP
//

import Foundation

struct ContactNote: Identifiable, Codable, Equatable {
    let id: UUID
    let contactId: UUID
    let userId: UUID
    let title: String
    let content: String
    let source: NoteSource
    let isMeeting: Bool
    let occurredAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum NoteSource: String, Codable {
        case manual
        case aiChat = "ai_chat"
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case userId = "user_id"
        case title
        case content
        case source
        case isMeeting = "is_meeting"
        case occurredAt = "occurred_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

