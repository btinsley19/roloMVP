//
//  AIChatService.swift
//  RoloMVP
//

import Foundation
import OSLog
import Supabase

protocol AIChatServiceProtocol {
    func sendMessage(contactId: UUID, message: String) async throws -> String
}

class AIChatService: AIChatServiceProtocol {
    private let logger = Logger.services
    let client: SupabaseClient
    
    init(client: SupabaseClient = SupabaseClientProvider.shared.client) {
        self.client = client
    }
    
    func sendMessage(contactId: UUID, message: String) async throws -> String {
        logger.info("sendMessage called for contact: \(contactId.uuidString)")
        
        // Get the function URL from environment
        let supabaseURL = Config.supabaseURL
        
        // Build edge function URL
        let functionURL = supabaseURL
            .replacingOccurrences(of: "https://", with: "")
            .replacingOccurrences(of: "http://", with: "")
        
        guard let edgeFunctionURL = URL(string: "https://\(functionURL)/functions/v1/contact-chat") else {
            throw ServiceError.badRequest("Invalid Supabase URL")
        }
        
        // Get auth session
        let session = try await client.auth.session
        let accessToken = session.accessToken
        
        // Prepare request body
        let body: [String: Any] = [
            "contact_id": contactId.uuidString,
            "message": message
        ]
        
        let jsonData = try JSONSerialization.data(withJSONObject: body)
        
        // Create request
        var request = URLRequest(url: edgeFunctionURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(Config.supabaseAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        // Make request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ServiceError.unknown("Invalid HTTP response")
        }
        
        guard httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            logger.error("Edge function error: \(errorMessage)")
            throw ServiceError.serverError(httpResponse.statusCode)
        }
        
        // Parse response
        struct ChatResponse: Codable {
            let assistant_message: String
        }
        
        let chatResponse = try JSONDecoder().decode(ChatResponse.self, from: data)
        logger.info("Received assistant message: \(chatResponse.assistant_message.prefix(50))...")
        
        return chatResponse.assistant_message
    }
}

