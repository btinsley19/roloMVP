//
//  EditContactSheet.swift
//  RoloMVP
//

import SwiftUI

struct EditContactSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: ContactDetailViewModel
    
    @State private var fullName: String
    @State private var companyName: String
    @State private var position: String
    @State private var linkedinUrl: String
    @State private var relationshipSummary: String
    @State private var relationshipPriority: Double
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    let contact: Contact
    
    init(contact: Contact, viewModel: ContactDetailViewModel) {
        self.contact = contact
        self.viewModel = viewModel
        _fullName = State(initialValue: contact.fullName)
        _companyName = State(initialValue: contact.companyName ?? "")
        _position = State(initialValue: contact.position ?? "")
        _linkedinUrl = State(initialValue: contact.linkedinUrl ?? "")
        _relationshipSummary = State(initialValue: contact.relationshipSummary ?? "")
        _relationshipPriority = State(initialValue: Double(contact.relationshipPriority))
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Full Name", text: $fullName)
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
            .navigationTitle("Edit Contact")
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
                            await saveChanges()
                        }
                    }
                    .disabled(isSaving || fullName.isEmpty)
                }
            }
        }
    }
    
    private func saveChanges() async {
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            // Update basic info
            _ = try await viewModel.contactsService.updateContactBasicInfo(
                id: contact.id,
                fullName: fullName,
                companyName: companyName.isEmpty ? nil : companyName,
                position: position.isEmpty ? nil : position,
                linkedinUrl: linkedinUrl.isEmpty ? nil : linkedinUrl
            )
            
            // Update relationship info
            _ = try await viewModel.contactsService.updateContactRelationship(
                id: contact.id,
                relationshipSummary: relationshipSummary.isEmpty ? nil : relationshipSummary,
                relationshipPriority: Int(relationshipPriority)
            )
            
            // Reload contact
            await viewModel.loadContact()
            
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }
    }
}

