//
//  NewContactReminder.swift
//  RoloMVP
//

import Foundation

struct NewContactReminder: Encodable {
    let contactId: UUID
    let userId: UUID
    let body: String
    let dueAt: Date?
    let source: String  // 'manual' | 'ai_suggested'
    let originType: String?  // 'note' | 'chat' | 'system'
    let originId: UUID?
    
    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case userId = "user_id"
        case body
        case dueAt = "due_at"
        case source
        case originType = "origin_type"
        case originId = "origin_id"
    }
}

