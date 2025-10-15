//
//  NewContact.swift
//  RoloMVP
//

import Foundation

struct NewContact: Encodable {
    let userId: UUID
    let fullName: String
    let photoUrl: String?
    let position: String?
    let companyName: String?
    let linkedinUrl: String?
    let relationshipSummary: String?
    let relationshipPriority: Int
    let lastInteractionAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case fullName = "full_name"
        case photoUrl = "photo_url"
        case position
        case companyName = "company_name"
        case linkedinUrl = "linkedin_url"
        case relationshipSummary = "relationship_summary"
        case relationshipPriority = "relationship_priority"
        case lastInteractionAt = "last_interaction_at"
    }
}

