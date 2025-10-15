//
//  UpdateContactRelationship.swift
//  RoloMVP
//

import Foundation

struct UpdateContactRelationship: Encodable {
    let relationshipSummary: String?
    let relationshipPriority: Int?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case relationshipSummary = "relationship_summary"
        case relationshipPriority = "relationship_priority"
        case updatedAt = "updated_at"
    }
}

