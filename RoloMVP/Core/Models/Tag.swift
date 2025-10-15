//
//  Tag.swift
//  RoloMVP
//

import Foundation

struct Tag: Identifiable, Codable, Equatable {
    let id: UUID
    let userId: UUID
    let name: String
    let slug: String?
    let description: String?
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case slug
        case description
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

