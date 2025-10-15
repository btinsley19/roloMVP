//
//  ContactChatMessage.swift
//  RoloMVP
//

import Foundation

struct ContactChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let contactId: UUID
    let userId: UUID
    let role: String // 'user' | 'assistant'
    let content: String
    let contextSnapshot: [String: AnyCodable]?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case contactId = "contact_id"
        case userId = "user_id"
        case role
        case content
        case contextSnapshot = "context_snapshot"
        case createdAt = "created_at"
    }
}

// Helper to decode arbitrary JSON
struct AnyCodable: Codable, Equatable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let string = try? container.decode(String.self) {
            value = string
        } else if let array = try? container.decode([AnyCodable].self) {
            value = array.map { $0.value }
        } else if let dictionary = try? container.decode([String: AnyCodable].self) {
            value = dictionary.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let bool as Bool:
            try container.encode(bool)
        case let int as Int:
            try container.encode(int)
        case let double as Double:
            try container.encode(double)
        case let string as String:
            try container.encode(string)
        case let array as [Any]:
            try container.encode(array.map { AnyCodable($0) })
        case let dictionary as [String: Any]:
            try container.encode(dictionary.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
    
    static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
        // Simple equality check for common types
        return String(describing: lhs.value) == String(describing: rhs.value)
    }
}

