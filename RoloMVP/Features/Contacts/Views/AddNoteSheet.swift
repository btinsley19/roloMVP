//
//  AddNoteSheet.swift
//  RoloMVP
//

import SwiftUI

struct AddNoteSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let contactId: UUID
    let onSave: () async -> Void
    
    @State private var title: String = ""
    @State private var content: String = ""
    @State private var isMeeting: Bool = false
    @State private var occurredAt: Date = Date()
    @State private var hasOccurredDate: Bool = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let notesService = NotesService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Note Details") {
                    TextField("Title", text: $title)
                    
                    TextField("Content", text: $content, axis: .vertical)
                        .lineLimit(5...10)
                }
                
                Section {
                    Toggle("Meeting Note", isOn: $isMeeting)
                    
                    Toggle("Set Date/Time", isOn: $hasOccurredDate)
                    
                    if hasOccurredDate {
                        DatePicker("When", selection: $occurredAt, displayedComponents: [.date, .hourAndMinute])
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
            .navigationTitle("Add Note")
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
                            await saveNote()
                        }
                    }
                    .disabled(isSaving || title.isEmpty || content.isEmpty)
                }
            }
        }
    }
    
    private func saveNote() async {
        guard let userId = appState.currentUserId else { return }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            let newNote = NewContactNote(
                contactId: contactId,
                userId: userId,
                title: title,
                content: content,
                source: "manual",
                isMeeting: isMeeting,
                occurredAt: hasOccurredDate ? occurredAt : nil
            )
            
            _ = try await notesService.create(newNote)
            
            await onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to save note: \(error.localizedDescription)"
        }
    }
}

