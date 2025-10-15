//
//  AIChatViewModel.swift
//  RoloMVP
//

import Foundation
import OSLog

struct ChatMessage: Identifiable, Equatable {
    let id: UUID
    let text: String
    let isFromUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isFromUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isFromUser = isFromUser
        self.timestamp = timestamp
    }
}

@MainActor
class AIChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var inputText = ""
    @Published var isProcessing = false
    
    private let logger = Logger.viewModels
    
    init() {
        // Welcome message
        messages.append(ChatMessage(
            text: "Hi! I'm your Rolo assistant. I can help you manage your contacts, add notes, set reminders, and more. How can I help you today?",
            isFromUser: false
        ))
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = ChatMessage(text: inputText, isFromUser: true)
        messages.append(userMessage)
        
        let messageToProcess = inputText
        inputText = ""
        
        Task {
            await processMessage(messageToProcess)
        }
    }
    
    private func processMessage(_ text: String) async {
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("Processing message: \(text)")
        
        // TODO: Integrate with AI service (OpenAI, etc.)
        // For now, just echo back
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let response = ChatMessage(
            text: "I received your message: \"\(text)\". This is a placeholder response. AI integration is coming soon!",
            isFromUser: false
        )
        
        messages.append(response)
    }
}

