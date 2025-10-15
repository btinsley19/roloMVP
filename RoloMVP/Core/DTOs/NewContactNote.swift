//
//  NewContactNote.swift
//  RoloMVP
//

import Foundation

struct NewContactNote: Encodable {
    let contactId: UUID
    let userId: UUID
    let title: String
    let content: String
    let source: String  // 'manual' | 'ai_chat'
    let isMeeting: Bool
    let occurredAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case userId = "user_id"
        case title
        case content
        case source
        case isMeeting = "is_meeting"
        case occurredAt = "occurred_at"
    }
}

