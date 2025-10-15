//
//  ContactChatViewModel.swift
//  RoloMVP
//

import Foundation
import OSLog

@MainActor
class ContactChatViewModel: ObservableObject {
    @Published var userMessage = ""
    @Published var assistantReply: String?
    @Published var isLoading = false
    @Published var error: ServiceError?
    @Published var showSuccessToast = false
    @Published var successMessage = ""
    
    private let logger = Logger.viewModels
    private let contactId: UUID
    private let userId: UUID
    private let aiChatService: AIChatServiceProtocol
    private let notesService: NotesServiceProtocol
    private let remindersService: RemindersServiceProtocol
    
    init(contactId: UUID,
         userId: UUID,
         aiChatService: AIChatServiceProtocol? = nil,
         notesService: NotesServiceProtocol? = nil,
         remindersService: RemindersServiceProtocol? = nil) {
        self.contactId = contactId
        self.userId = userId
        self.aiChatService = aiChatService ?? AIChatService()
        self.notesService = notesService ?? NotesService()
        self.remindersService = remindersService ?? RemindersService()
    }
    
    func sendMessage() async {
        guard !userMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        let messageToSend = userMessage
        userMessage = "" // Clear input immediately for better UX
        
        do {
            logger.info("Sending message for contact: \(self.contactId.uuidString)")
            let reply = try await aiChatService.sendMessage(contactId: contactId, message: messageToSend)
            assistantReply = reply
            logger.info("Received reply from AI")
        } catch let error as ServiceError {
            logger.error("Failed to send message: \(error.localizedDescription)")
            self.error = error
            userMessage = messageToSend // Restore message on error
        } catch {
            logger.error("Unexpected error: \(error.localizedDescription)")
            self.error = .unknown(error.localizedDescription)
            userMessage = messageToSend
        }
    }
    
    func saveAsNote() async {
        guard let reply = assistantReply else { return }
        
        do {
            let newNote = NewContactNote(
                contactId: contactId,
                userId: userId,
                title: "AI Chat Summary",
                content: reply,
                source: "ai_chat",
                isMeeting: false,
                occurredAt: nil
            )
            
            _ = try await notesService.create(newNote)
            logger.info("Note created from AI reply")
            
            successMessage = "Note saved successfully"
            showSuccessToast = true
            
            // Hide toast after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSuccessToast = false
            
        } catch {
            logger.error("Failed to save note: \(error.localizedDescription)")
            self.error = .unknown("Failed to save note")
        }
    }
    
    func createReminder(body: String, dueAt: Date?) async {
        do {
            let newReminder = NewContactReminder(
                contactId: contactId,
                userId: userId,
                body: body,
                dueAt: dueAt,
                source: "manual",
                originType: "chat",
                originId: nil
            )
            
            _ = try await remindersService.create(newReminder)
            logger.info("Reminder created from AI chat")
            
            successMessage = "Reminder created successfully"
            showSuccessToast = true
            
            // Hide toast after 2 seconds
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            showSuccessToast = false
            
        } catch {
            logger.error("Failed to create reminder: \(error.localizedDescription)")
            self.error = .unknown("Failed to create reminder")
        }
    }
}

