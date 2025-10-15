//
//  ContactRow.swift
//  RoloMVP
//

import SwiftUI

struct ContactRow: View {
    let contact: Contact
    @State private var tags: [(tag: Tag, contactTag: ContactTag)] = []
    @State private var isLoadingTags = false
    
    private func loadTags() {
        Task {
            isLoadingTags = true
            defer { isLoadingTags = false }
            
            do {
                let contactTags = try await ContactTagsService().listForContact(contactId: contact.id)
                var loadedTags: [(tag: Tag, contactTag: ContactTag)] = []
                
                for contactTag in contactTags {
                    let tag = try await TagsService().getTag(id: contactTag.tagId)
                    loadedTags.append((tag: tag, contactTag: contactTag))
                }
                
                // Sort by priority (highest first)
                tags = loadedTags.sorted { $0.contactTag.priority > $1.contactTag.priority }
            } catch {
                // Handle error silently for now
                print("Failed to load tags: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing:12) {
                AvatarView(photoUrl: contact.photoUrl, fullName: contact.fullName, size: 50)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(contact.fullName)
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    if let company = contact.companyName, let position = contact.position {
                        Text("\(position)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(company)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else if let company = contact.companyName {
                        Text(company)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else if let position = contact.position {
                        Text(position)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if !tags.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.tag.id) { item in
                                    Text(item.tag.name)
                                        .font(.caption)
                                        .foregroundColor(Color.blue)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.blue.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            
            // Bottom row with last interaction and priority dots
            HStack {
                if let lastInteraction = contact.lastInteractionAt {
                    Text("Last Interaction • \(Formatters.relativeDateFormatter.localizedString(for: lastInteraction, relativeTo: Date()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Priority dots
                HStack(spacing: 2) {
                    ForEach(0..<10) { index in
                        Circle()
                            .fill(index < contact.relationshipPriority ? Color.blue : Color.blue.opacity(0.3))
                            .frame(width: 6, height: 6)
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onAppear {
            loadTags()
        }
    }
}

#Preview {
    List {
        ContactRow(contact: Contact(
            id: UUID(),
            userId: UUID(),
            fullName: "Sarah Johnson",
            photoUrl: nil,
            position: "VP of Engineering",
            companyName: "TechCorp",
            linkedinUrl: nil,
            relationshipSummary: "Former colleague",
            relationshipPriority: 9,
            lastInteractionAt: Date().addingTimeInterval(-86400 * 7),
            createdAt: Date(),
            updatedAt: Date()
        ))
    }
}

