//
//  ContactDetailView.swift
//  RoloMVP
//

import SwiftUI

// MARK: - Tab Bar Item Component
struct TabBarItem: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .primary : .secondary)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .primary : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(isSelected ? Color.primary : Color.clear)
                        .frame(height: 2)
                }
            )
        }
    }
}

struct ContactDetailView: View {
    @StateObject private var viewModel: ContactDetailViewModel
    @EnvironmentObject var appState: AppState
    @State private var selectedTab = 0
    @State private var showEditSheet = false
    @State private var showManageTagsSheet = false
    @State private var showAddNoteSheet = false
    @State private var showAddReminderSheet = false
    
    let contactId: UUID
    
    init(contactId: UUID) {
        self.contactId = contactId
        _viewModel = StateObject(wrappedValue: ContactDetailViewModel(contactId: contactId))
    }
    
    var body: some View {
        ZStack {
            Group {
                if viewModel.isLoading {
                    LoadingView(message: "Loading contact...")
                } else if let contact = viewModel.contact {
                    VStack(spacing: 0) {
                        // Header
                        VStack(spacing: 16) {
                            AvatarView(photoUrl: contact.photoUrl, fullName: contact.fullName, size: 100)
                            
                            Text(contact.fullName)
                                .font(.title)
                                .fontWeight(.bold)
                            
                            if let company = contact.companyName, let position = contact.position {
                                Text("\(position) at \(company)")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.white)
                        
                        // Custom Tab Bar
                        HStack(spacing: 0) {
                            TabBarItem(
                                title: "Contact",
                                icon: "person.fill",
                                isSelected: selectedTab == 0,
                                action: { selectedTab = 0 }
                            )
                            
                            TabBarItem(
                                title: "News",
                                icon: "newspaper.fill",
                                isSelected: selectedTab == 3,
                                action: { selectedTab = 3 }
                            )
                            
                            TabBarItem(
                                title: "Notes",
                                icon: "note.text",
                                isSelected: selectedTab == 1,
                                action: { selectedTab = 1 }
                            )
                            
                            TabBarItem(
                                title: "Reminders",
                                icon: "bell.fill",
                                isSelected: selectedTab == 2,
                                action: { selectedTab = 2 }
                            )
                        }
                        .padding(.horizontal)
                        .background(Color.white)
                        
                        // Tab Content
                        //TO DO: Changes images to match designs
                        ScrollView {
                            Group {
                                switch selectedTab {
                                case 0:
                                    ContactInfoTab(contact: contact, tags: viewModel.tags) {
                                        showManageTagsSheet = true
                                    }
                                case 1:
                                    ContactNotesTab(notes: viewModel.notes) {
                                        showAddNoteSheet = true
                                    }
                                case 2:
                                    ContactRemindersTab(reminders: viewModel.reminders) {
                                        showAddReminderSheet = true
                                    }
                                case 3:
                                    ContactNewsTab(news: viewModel.news, isFetchingNews: viewModel.isFetchingNews) {
                                        await viewModel.fetchNews()
                                    }
                                case 4:
                                    if let userId = appState.currentUserId {
                                        ContactChatContainer(
                                            contactId: contactId,
                                            userId: userId,
                                            onNoteAdded: {
                                                await viewModel.loadNotes()
                                            },
                                            onReminderAdded: {
                                                await viewModel.loadReminders()
                                            }
                                        )
                                    } else {
                                        EmptyStateView(
                                            icon: "exclamationmark.triangle",
                                            title: "Error",
                                            message: "User not authenticated"
                                        )
                                    }
                                default:
                                    EmptyView()
                                }
                            }
                            .padding()
                        }
                    }
                    .background(Color.gray.opacity(0.05))
                } else {
                    EmptyStateView(
                        icon: "person.slash",
                        title: "Contact Not Found",
                        message: "This contact could not be loaded."
                    )
                }
            }
            // Floating Message Button
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        // Add your message/chat action here
                        print("Message button tapped")
                    } label: {
                        Image(systemName: "message.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                            .frame(width: 56, height: 56)
                            .background(Color.blue)
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                    .padding(.bottom, 20)
                    .padding(.trailing, 20)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if viewModel.contact != nil {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Edit") {
                        showEditSheet = true
                    }
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            if let contact = viewModel.contact {
                EditContactSheet(contact: contact, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $showManageTagsSheet) {
            ManageTagsSheet(contactId: contactId, currentTags: viewModel.tags) {
                await viewModel.loadTags()
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $showAddNoteSheet) {
            AddNoteSheet(contactId: contactId) {
                await viewModel.loadNotes()
            }
            .environmentObject(appState)
        }
        .sheet(isPresented: $showAddReminderSheet) {
            AddReminderSheet(contactId: contactId) {
                await viewModel.loadReminders()
            }
            .environmentObject(appState)
        }
        .task {
            await viewModel.loadContact()
            await viewModel.loadTags()
            await viewModel.loadNotes()
            await viewModel.loadReminders()
            await viewModel.loadNews()
        }
    }
}

// MARK: - Info Tab
    struct ContactInfoTab: View {
        let contact: Contact
        let tags: [(tag: Tag, contactTag: ContactTag)]
        let onManageTags: () -> Void
        
        var body: some View {
            VStack(alignment: .leading, spacing: 20) {
                // Job Title Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Job title")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .fontWeight(.medium)
                    
                    Text(contact.position ?? "No position specified")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                )
                
                // Company Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Company")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .fontWeight(.medium)
                    
                    Text(contact.companyName ?? "No company specified")
                        .font(.body)
                        .foregroundColor(.primary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                )
                
                // Last Interaction Section
                if let lastInteraction = contact.lastInteractionAt {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last interaction")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .fontWeight(.medium)
                        
                        Text(Formatters.shortDateFormatter.string(from: lastInteraction))
                            .font(.body)
                            .foregroundColor(.primary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                }
                
                // Labels Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Labels")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: onManageTags) {
                            Image(systemName: "pencil")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    if tags.isEmpty {
                        Text("No labels yet")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(tags, id: \.tag.id) { item in
                                    Text(item.tag.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.gray.opacity(0.2))
                                        .cornerRadius(16)
                                }
                            }
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white)
                )
                
                // Socials Section
                if let linkedinUrl = contact.linkedinUrl {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Socials")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .textCase(.uppercase)
                            .fontWeight(.medium)
                        HStack(spacing: 16) {
                            Image(systemName: "link") // Change to linkedin icon
                                .resizable()
                                .frame(width: 20, height: 20)
                                .foregroundColor(.blue)
                            
                            if let url = URL(string: linkedinUrl) {
                                Link("LinkedIn Profile", destination: url)
                                    .font(.body)
                                    .foregroundColor(.blue)
                            }
                        }
                        
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white)
                    )
                }
                Spacer()
            }
        }
        
        private func tagColor(for item: (tag: Tag, contactTag: ContactTag)) -> Color {
            // Use color_override if set, otherwise use priority-based color
            if let colorOverride = item.contactTag.colorOverride {
                // Parse hex color (simplified - just return a default color for now)
                return .blue
            } else {
                return Color.priorityColor(for: Int(item.contactTag.priority))
            }
        }
}

// Simple flow layout for tags
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x, y: bounds.minY + result.positions[index].y), proposal: .unspecified)
        }
    }
    
    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []
        
        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0
            
            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)
                
                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }
                
                positions.append(CGPoint(x: currentX, y: currentY))
                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }
            
            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var isLink: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if isLink, let url = URL(string: value) {
                Link(value, destination: url)
                    .font(.body)
            } else {
                Text(value)
                    .font(.body)
            }
        }
    }
}

// MARK: - Notes Tab
struct ContactNotesTab: View {
    let notes: [ContactNote]
    let onAddNote: () -> Void
    
    var body: some View {
        VStack {
            if notes.isEmpty {
                EmptyStateView(
                    icon: "note.text",
                    title: "No Notes",
                    message: "Add notes to remember important details about your interactions.",
                    actionTitle: "Add Note",
                    action: onAddNote
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(notes) { note in
                        NoteCard(note: note)
                    }
                    
                    PrimaryButton(title: "Add Note", action: onAddNote)
                        .padding(.top)
                }
            }
        }
    }
}

struct NoteCard: View {
    let note: ContactNote
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(note.title)
                    .font(.headline)
                
                Spacer()
                
                if note.isMeeting {
                    Image(systemName: "video.fill")
                        .foregroundColor(.blue)
                        .font(.caption)
                }
            }
            
            Text(note.content)
                .font(.body)
                .foregroundColor(.secondary)
            
            Text(Formatters.shortDateFormatter.string(from: note.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.roloSecondaryBackground)
        .cornerRadius(10)
    }
}

// MARK: - Reminders Tab
struct ContactRemindersTab: View {
    let reminders: [ContactReminder]
    let onAddReminder: () -> Void
    
    var body: some View {
        VStack {
            if reminders.isEmpty {
                EmptyStateView(
                    icon: "bell",
                    title: "No Reminders",
                    message: "Set reminders to stay in touch with this contact.",
                    actionTitle: "Add Reminder",
                    action: onAddReminder
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(reminders) { reminder in
                        ReminderCard(reminder: reminder)
                    }
                    
                    PrimaryButton(title: "Add Reminder", action: onAddReminder)
                        .padding(.top)
                }
            }
        }
    }
}

struct ReminderCard: View {
    let reminder: ContactReminder
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(reminder.body)
                    .font(.body)
                
                if let dueAt = reminder.dueAt {
                    Text(Formatters.shortDateFormatter.string(from: dueAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "bell.fill")
                .foregroundColor(.orange)
        }
        .padding()
        .background(Color.roloSecondaryBackground)
        .cornerRadius(10)
    }
}

// MARK: - News Tab
struct ContactNewsTab: View {
    let news: [ContactNews]
    let isFetchingNews: Bool
    let onFetchNews: () async -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            if news.isEmpty {
                EmptyStateView(
                    icon: "newspaper",
                    title: "No News",
                    message: "Fetch recent news and updates about this contact from the web.",
                    actionTitle: isFetchingNews ? "Fetching..." : "Fetch News",
                    action: {
                        Task {
                            await onFetchNews()
                        }
                    }
                )
            } else {
                VStack(spacing: 12) {
                    ForEach(news) { item in
                        NewsItemCard(news: item)
                    }
                    
                    Button(action: {
                        Task {
                            await onFetchNews()
                        }
                    }) {
                        HStack {
                            if isFetchingNews {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "arrow.clockwise")
                            }
                            Text(isFetchingNews ? "Fetching News..." : "Refresh News")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.roloPrimary.opacity(0.1))
                        .foregroundColor(.roloPrimary)
                        .cornerRadius(10)
                    }
                    .disabled(isFetchingNews)
                    .padding(.top)
                }
            }
        }
    }
}

struct NewsItemCard: View {
    let news: ContactNews
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(news.title)
                .font(.headline)
            
            Text(news.summary)
                .font(.body)
                .foregroundColor(.secondary)
            
            HStack {
                Text(news.source)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(Formatters.shortDateFormatter.string(from: news.publishedAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let url = URL(string: news.url) {
                Link("Read More", destination: url)
                    .font(.caption)
                    .foregroundColor(.roloPrimary)
            }
        }
        .padding()
        .background(Color.roloSecondaryBackground)
        .cornerRadius(10)
    }
}

// MARK: - Chat Container
// This wrapper manages the @StateObject lifecycle for ContactChatViewModel
// so it persists across tab switches
struct ContactChatContainer: View {
    @StateObject private var chatViewModel: ContactChatViewModel
    
    let onNoteAdded: () async -> Void
    let onReminderAdded: () async -> Void
    
    init(contactId: UUID, userId: UUID, onNoteAdded: @escaping () async -> Void, onReminderAdded: @escaping () async -> Void) {
        _chatViewModel = StateObject(wrappedValue: ContactChatViewModel(contactId: contactId, userId: userId))
        self.onNoteAdded = onNoteAdded
        self.onReminderAdded = onReminderAdded
    }
    
    var body: some View {
        ContactChatView(
            viewModel: chatViewModel,
            onNoteAdded: onNoteAdded,
            onReminderAdded: onReminderAdded
        )
    }
}

#Preview {
    NavigationStack {
        ContactDetailView(contactId: UUID())
    }
}

