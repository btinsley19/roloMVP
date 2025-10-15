//
//  NewContactTag.swift
//  RoloMVP
//

import Foundation

struct NewContactTag: Encodable {
    let contactId: UUID
    let tagId: UUID
    let priority: Int16
    let colorOverride: String?
    
    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case tagId = "tag_id"
        case priority
        case colorOverride = "color_override"
    }
}

