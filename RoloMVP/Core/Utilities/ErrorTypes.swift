//
//  ErrorTypes.swift
//  RoloMVP
//

import Foundation

enum ServiceError: Error, LocalizedError {
    case networkError(Error)
    case decodingError(Error)
    case notFound
    case unauthorized
    case badRequest(String)
    case serverError(Int)
    case unknown(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .notFound:
            return "Resource not found"
        case .unauthorized:
            return "Unauthorized access"
        case .badRequest(let message):
            return "Bad request: \(message)"
        case .serverError(let code):
            return "Server error: \(code)"
        case .unknown(let message):
            return "Unknown error: \(message)"
        }
    }
}

