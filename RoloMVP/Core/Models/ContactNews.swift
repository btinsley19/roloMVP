//
//  ContactNews.swift
//  RoloMVP
//

import Foundation

struct ContactNews: Identifiable, Codable, Equatable {
    let id: UUID
    let contactId: UUID
    let source: String
    let title: String
    let url: String
    let summary: String
    let publishedAt: Date
    let fetchedAt: Date
    let topics: [String]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case source
        case title
        case url
        case summary
        case publishedAt = "published_at"
        case fetchedAt = "fetched_at"
        case topics
        case createdAt = "created_at"
    }
}

// News item with contact information included
struct ContactNewsWithContact: Identifiable, Codable, Equatable {
    let id: UUID
    let contactId: UUID
    let source: String
    let title: String
    let url: String
    let summary: String
    let publishedAt: Date
    let fetchedAt: Date
    let topics: [String]?
    let createdAt: Date
    
    // Contact info (joined from contacts table)
    let contactName: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case source
        case title
        case url
        case summary
        case publishedAt = "published_at"
        case fetchedAt = "fetched_at"
        case topics
        case createdAt = "created_at"
        case contactName = "contact_name"
    }
}
