//
//  ManageTagsSheet.swift
//  RoloMVP
//

import SwiftUI

struct ManageTagsSheet: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    let contactId: UUID
    let currentTags: [(tag: Tag, contactTag: ContactTag)]
    let onSave: () async -> Void
    
    @State private var allTags: [Tag] = []
    @State private var selectedTagId: UUID?
    @State private var tagPriority: Int16 = 5
    @State private var newTagName: String = ""
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?
    
    private let tagsService = TagsService()
    private let contactTagsService = ContactTagsService()
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Current Tags") {
                    if currentTags.isEmpty {
                        Text("No tags yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(currentTags, id: \.tag.id) { item in
                            HStack {
                                Text(item.tag.name)
                                Spacer()
                                Text("Priority: \(item.contactTag.priority)")
                                    .foregroundColor(.secondary)
                                    .font(.caption)
                                
                                Button(role: .destructive) {
                                    Task {
                                        await removeTag(tagId: item.tag.id)
                                    }
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
                
                Section("Add Existing Tag") {
                    if isLoading {
                        ProgressView()
                    } else {
                        Picker("Select Tag", selection: $selectedTagId) {
                            Text("Choose a tag...").tag(nil as UUID?)
                            ForEach(availableTags) { tag in
                                Text(tag.name).tag(tag.id as UUID?)
                            }
                        }
                        
                        if selectedTagId != nil {
                            Stepper("Priority: \(tagPriority)", value: $tagPriority, in: 1...10)
                            
                            Button("Add Tag") {
                                Task {
                                    await addExistingTag()
                                }
                            }
                            .disabled(isSaving)
                        }
                    }
                }
                
                Section("Create New Tag") {
                    TextField("Tag Name", text: $newTagName)
                    
                    Stepper("Priority: \(tagPriority)", value: $tagPriority, in: 1...10)
                    
                    Button("Create & Add Tag") {
                        Task {
                            await createAndAddTag()
                        }
                    }
                    .disabled(isSaving || newTagName.isEmpty)
                }
                
                if let errorMessage = errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("Manage Tags")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await loadTags()
            }
        }
    }
    
    private var availableTags: [Tag] {
        let currentTagIds = Set(currentTags.map { $0.tag.id })
        return allTags.filter { !currentTagIds.contains($0.id) }
    }
    
    private func loadTags() async {
        guard let userId = appState.currentUserId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            allTags = try await tagsService.listTags(owner: userId)
        } catch {
            errorMessage = "Failed to load tags: \(error.localizedDescription)"
        }
    }
    
    private func addExistingTag() async {
        guard let tagId = selectedTagId else { return }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            let newContactTag = NewContactTag(
                contactId: contactId,
                tagId: tagId,
                priority: tagPriority,
                colorOverride: nil
            )
            
            _ = try await contactTagsService.upsert(newContactTag)
            
            await onSave()
            selectedTagId = nil
        } catch {
            errorMessage = "Failed to add tag: \(error.localizedDescription)"
        }
    }
    
    private func createAndAddTag() async {
        guard let userId = appState.currentUserId else { return }
        
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }
        
        do {
            // Create new tag
            let newTag = NewTag(
                userId: userId,
                name: newTagName,
                slug: newTagName.lowercased().replacingOccurrences(of: " ", with: "-"),
                description: nil
            )
            
            let createdTag = try await tagsService.createTag(newTag)
            
            // Add to contact
            let newContactTag = NewContactTag(
                contactId: contactId,
                tagId: createdTag.id,
                priority: tagPriority,
                colorOverride: nil
            )
            
            _ = try await contactTagsService.upsert(newContactTag)
            
            await onSave()
            newTagName = ""
            
            // Refresh tag list
            await loadTags()
        } catch {
            errorMessage = "Failed to create tag: \(error.localizedDescription)"
        }
    }
    
    private func removeTag(tagId: UUID) async {
        do {
            try await contactTagsService.remove(contactId: contactId, tagId: tagId)
            await onSave()
        } catch {
            errorMessage = "Failed to remove tag: \(error.localizedDescription)"
        }
    }
}

