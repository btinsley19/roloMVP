//
//  UpdateContactBasicInfo.swift
//  RoloMVP
//

import Foundation

struct UpdateContactBasicInfo: Encodable {
    let fullName: String?
    let companyName: String?
    let position: String?
    let linkedinUrl: String?
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case fullName = "full_name"
        case companyName = "company_name"
        case position
        case linkedinUrl = "linkedin_url"
        case updatedAt = "updated_at"
    }
}

