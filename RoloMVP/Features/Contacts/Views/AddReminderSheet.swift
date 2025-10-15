//
//  AddReminderSheet.swift
//  RoloMVP
//

import SwiftUI

struct AddReminderSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let contactId: UUID
    let onSave: () async -> Void
    
    @State private var reminderBody: String = ""
    @State private var hasDueDate: Bool = false
    @State private var dueAt: Date = Date().addingTimeInterval(86400 * 7) // Default 1 week from now
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let remindersService = RemindersService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("What do you want to be reminded about?", text: $reminderBody, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due", selection: $dueAt, displayedComponents: [.date, .hourAndMinute])
                    }
                }
                
                Section {
                    Button("Next Week") {
                        hasDueDate = true
                        dueAt = Date().addingTimeInterval(86400 * 7)
                    }
                    
                    Button("Next Month") {
                        hasDueDate = true
                        dueAt = Calendar.current.date(byAdding: .month, value: 1, to: Date()) ?? Date()
                    }
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Add Reminder")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await saveReminder()
                        }
                    }
                    .disabled(isSaving || reminderBody.isEmpty)
                }
            }
        }
    }
    
    private func saveReminder() async {
        guard let userId = appState.currentUserId else { return }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            let newReminder = NewContactReminder(
                contactId: contactId,
                userId: userId,
                body: reminderBody,
                dueAt: hasDueDate ? dueAt : nil,
                source: "manual",
                originType: nil,
                originId: nil
            )
            
            _ = try await remindersService.create(newReminder)
            
            await onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save reminder: \(error.localizedDescription)"
        }
    }
}

