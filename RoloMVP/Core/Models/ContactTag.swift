//
//  ContactTag.swift
//  RoloMVP
//

import Foundation

struct ContactTag: Codable, Equatable, Hashable {
    let contactId: UUID
    let tagId: UUID
    let priority: Int16
    let colorOverride: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case tagId = "tag_id"
        case priority
        case colorOverride = "color_override"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

