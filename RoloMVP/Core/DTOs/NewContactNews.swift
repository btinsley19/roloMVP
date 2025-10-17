//
//  NewContactNews.swift
//  RoloMVP
//

import Foundation

struct NewContactNews: Encodable {
    let contactId: UUID
    let source: String
    let title: String
    let url: String
    let summary: String
    let publishedAt: Date
    let fetchedAt: Date
    let topics: [String]?
    let imageUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case contactId = "contact_id"
        case source
        case title
        case url
        case summary
        case publishedAt = "published_at"
        case fetchedAt = "fetched_at"
        case topics
        case imageUrl = "image_url"
    }
}

