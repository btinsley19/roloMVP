//
//  ContactRow.swift
//  RoloMVP
//

import SwiftUI

struct ContactRow: View {
    let contact: Contact
    
    var body: some View {
        HStack(spacing: 12) {
            AvatarView(photoUrl: contact.photoUrl, fullName: contact.fullName, size: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(contact.fullName)
                        .font(.headline)
                    
                    Circle()
                        .fill(Color.priorityColor(for: contact.relationshipPriority))
                        .frame(width: 8, height: 8)
                }
                
                if let company = contact.companyName, let position = contact.position {
                    Text("\(position) at \(company)")
                        .font(.subheadline)
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
                
                if let lastInteraction = contact.lastInteractionAt {
                    Text("Last contact: \(Formatters.relativeDateFormatter.localizedString(for: lastInteraction, relativeTo: Date()))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
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

