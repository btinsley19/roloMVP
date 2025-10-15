//
//  NewContactSheet.swift
//  RoloMVP
//

import SwiftUI

struct NewContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let onSave: () async -> Void
    
    @State private var fullName: String = ""
    @State private var companyName: String = ""
    @State private var position: String = ""
    @State private var linkedinUrl: String = ""
    @State private var relationshipSummary: String = ""
    @State private var relationshipPriority: Double = 5
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let contactsService = ContactsService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Full Name *", text: $fullName)
                    TextField("Company", text: $companyName)
                    TextField("Position", text: $position)
                }
                
                Section("Professional Links") {
                    TextField("LinkedIn URL", text: $linkedinUrl)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                }
                
                Section("Relationship") {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Priority")
                            Spacer()
                            Text("\(Int(relationshipPriority))")
                                .fontWeight(.semibold)
                                .foregroundColor(Color.priorityColor(for: Int(relationshipPriority)))
                        }
                        Slider(value: $relationshipPriority, in: 1...10, step: 1)
                    }
                    
                    TextField("Relationship Summary", text: $relationshipSummary, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("New Contact")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        Task {
                            await createContact()
                        }
                    }
                    .disabled(isSaving || fullName.isEmpty)
                }
            }
        }
    }
    
    private func createContact() async {
        guard let userId = appState.currentUserId else { return }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            let newContact = NewContact(
                userId: userId,
                fullName: fullName,
                photoUrl: nil,
                position: position.isEmpty ? nil : position,
                companyName: companyName.isEmpty ? nil : companyName,
                linkedinUrl: linkedinUrl.isEmpty ? nil : linkedinUrl,
                relationshipSummary: relationshipSummary.isEmpty ? nil : relationshipSummary,
                relationshipPriority: Int(relationshipPriority),
                lastInteractionAt: nil
            )
            
            _ = try await contactsService.createContact(newContact)
            
            await onSave()
            dismiss()
        } catch {
            errorMessage = "Failed to create contact: \(error.localizedDescription)"
        }
    }
}

