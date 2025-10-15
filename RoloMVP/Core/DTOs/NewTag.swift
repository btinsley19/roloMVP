//
//  NewTag.swift
//  RoloMVP
//

import Foundation

struct NewTag: Encodable {
    let userId: UUID
    let name: String
    let slug: String?
    let description: String?
    
    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case name
        case slug
        case description
    }
}

