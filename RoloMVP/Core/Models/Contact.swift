//
//  Contact.swift
//  RoloMVP
//

import Foundation

struct Contact: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let fullName: String
    let photoUrl: String?
    let position: String?
    let companyName: String?
    let linkedinUrl: String?
    let relationshipSummary: String?
    let relationshipPriority: Int
    let lastInteractionAt: Date?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case photoUrl = "photo_url"
        case position
        case companyName = "company_name"
        case linkedinUrl = "linkedin_url"
        case relationshipSummary = "relationship_summary"
        case relationshipPriority = "relationship_priority"
        case lastInteractionAt = "last_interaction_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

