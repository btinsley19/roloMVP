//
//  ContactDetailView.swift
//  RoloMVP
//

import SwiftUI

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
        Group {
            if viewModel.isLoading {
                LoadingView(message: "Loading contact...")
            } else if let contact = viewModel.contact {
                ScrollView {
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
                        .background(Color.roloSecondaryBackground)
                        
                        // Tab Picker
                        Picker("Tab", selection: $selectedTab) {
                            Text("Info").tag(0)
                            Text("Notes").tag(1)
                            Text("Reminders").tag(2)
                            Text("News").tag(3)
                            Text("AI").tag(4)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        // Tab Content
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
            } else {
                EmptyStateView(
                    icon: "person.slash",
                    title: "Contact Not Found",
                    message: "This contact could not be loaded."
                )
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
            // Tags
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Tags")
                        .font(.headline)
                    Spacer()
                    Button(action: onManageTags) {
                        Image(systemName: "tag")
                        Text("Manage")
                    }
                    .font(.caption)
                }
                
                if tags.isEmpty {
                    Text("No tags yet")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                } else {
                    FlowLayout(spacing: 8) {
                        ForEach(tags, id: \.tag.id) { item in
                            TagPill(
                                name: item.tag.name,
                                color: tagColor(for: item)
                            )
                        }
                    }
                }
            }
            
            Divider()
            
            // Priority
            VStack(alignment: .leading, spacing: 8) {
                Text("Relationship Priority")
                    .font(.headline)
                
                HStack {
                    Text("\(contact.relationshipPriority)")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(Color.priorityColor(for: contact.relationshipPriority))
                    
                    Spacer()
                    
                    // Visual priority indicator
                    ForEach(1...10, id: \.self) { level in
                        Circle()
                            .fill(level <= contact.relationshipPriority ? Color.priorityColor(for: contact.relationshipPriority) : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
            }
            
            Divider()
            
            // Last Interaction
            if let lastInteraction = contact.lastInteractionAt {
                InfoRow(label: "Last Contact", value: Formatters.shortDateFormatter.string(from: lastInteraction))
                Divider()
            }
            
            // LinkedIn
            if let linkedinUrl = contact.linkedinUrl {
                InfoRow(label: "LinkedIn", value: linkedinUrl, isLink: true)
                Divider()
            }
            
            // Relationship Summary
            if let summary = contact.relationshipSummary {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Relationship Summary")
                        .font(.headline)
                    
                    Text(summary)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
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

