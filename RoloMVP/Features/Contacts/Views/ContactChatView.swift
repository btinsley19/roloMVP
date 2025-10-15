//
//  ContactChatView.swift
//  RoloMVP
//

import SwiftUI

struct ContactChatView: View {
    @ObservedObject var viewModel: ContactChatViewModel
    @EnvironmentObject var appState: AppState
    @State private var showReminderSheet = false
    
    let onNoteAdded: () async -> Void
    let onReminderAdded: () async -> Void
    
    init(viewModel: ContactChatViewModel, onNoteAdded: @escaping () async -> Void, onReminderAdded: @escaping () async -> Void) {
        self.viewModel = viewModel
        self.onNoteAdded = onNoteAdded
        self.onReminderAdded = onReminderAdded
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Chat content
            ScrollView {
                VStack(spacing: 16) {
                    if viewModel.isLoading {
                        VStack(spacing: 12) {
                            ProgressView()
                            Text("Thinking...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    
                    if let reply = viewModel.assistantReply {
                        VStack(alignment: .leading, spacing: 16) {
                            // Assistant message bubble
                            HStack(alignment: .top, spacing: 12) {
                                Image(systemName: "brain")
                                    .foregroundColor(.roloPrimary)
                                    .font(.title2)
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("AI Assistant")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    Text(reply)
                                        .font(.body)
                                        .padding(12)
                                        .background(Color.roloSecondaryBackground)
                                        .cornerRadius(12)
                                }
                            }
                            
                            // Action buttons
                            HStack(spacing: 12) {
                                Button(action: {
                                    Task {
                                        await viewModel.saveAsNote()
                                        await onNoteAdded()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "note.text")
                                        Text("Add as Note")
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.roloPrimary.opacity(0.1))
                                    .foregroundColor(.roloPrimary)
                                    .cornerRadius(8)
                                }
                                
                                Button(action: {
                                    showReminderSheet = true
                                }) {
                                    HStack {
                                        Image(systemName: "bell")
                                        Text("Create Reminder")
                                    }
                                    .font(.subheadline)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .background(Color.orange.opacity(0.1))
                                    .foregroundColor(.orange)
                                    .cornerRadius(8)
                                }
                            }
                            .padding(.top, 8)
                        }
                        .padding()
                    }
                    
                    if viewModel.assistantReply == nil && !viewModel.isLoading {
                        VStack(spacing: 16) {
                            Image(systemName: "bubble.left.and.bubble.right")
                                .font(.system(size: 48))
                                .foregroundColor(.secondary.opacity(0.5))
                            
                            Text("Ask about this contact")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("Get insights, draft messages, or plan your next interaction")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding()
                    }
                }
            }
            
            // Success toast
            if viewModel.showSuccessToast {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(viewModel.successMessage)
                        .font(.subheadline)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .padding()
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
            
            // Input area
            HStack(spacing: 12) {
                TextField("Ask about this contact...", text: $viewModel.userMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(1...4)
                    .disabled(viewModel.isLoading)
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(viewModel.userMessage.isEmpty ? .gray : .roloPrimary)
                }
                .disabled(viewModel.userMessage.isEmpty || viewModel.isLoading)
            }
            .padding()
            .background(Color.roloSecondaryBackground.opacity(0.5))
        }
        .sheet(isPresented: $showReminderSheet) {
            CreateReminderFromChatSheet(
                initialText: viewModel.assistantReply ?? "",
                onSave: { body, dueAt in
                    Task {
                        await viewModel.createReminder(body: body, dueAt: dueAt)
                        await onReminderAdded()
                    }
                }
            )
        }
        .alert("Error", isPresented: .constant(viewModel.error != nil)) {
            Button("OK") {
                viewModel.error = nil
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
    }
}

// Simple sheet for creating reminder from chat
struct CreateReminderFromChatSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let initialText: String
    let onSave: (String, Date?) async -> Void
    
    @State private var reminderBody: String
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    
    init(initialText: String, onSave: @escaping (String, Date?) async -> Void) {
        self.initialText = initialText
        self.onSave = onSave
        _reminderBody = State(initialValue: initialText)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Reminder") {
                    TextField("What do you want to remember?", text: $reminderBody, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section {
                    Toggle("Set Due Date", isOn: $hasDueDate)
                    
                    if hasDueDate {
                        DatePicker("Due Date", selection: $dueDate, displayedComponents: [.date, .hourAndMinute])
                    }
                }
            }
            .navigationTitle("Create Reminder")
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
                            await onSave(reminderBody, hasDueDate ? dueDate : nil)
                            dismiss()
                        }
                    }
                    .disabled(reminderBody.isEmpty)
                }
            }
        }
    }
}

#Preview {
    ContactChatView(
        viewModel: ContactChatViewModel(contactId: UUID(), userId: UUID()),
        onNoteAdded: {},
        onReminderAdded: {}
    )
    .environmentObject(AppState())
}

