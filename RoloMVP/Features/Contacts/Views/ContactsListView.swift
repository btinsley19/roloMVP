//
//  ContactsListView.swift
//  RoloMVP
//

import SwiftUI

struct ContactsListView: View {
    @StateObject private var viewModel: ContactsListViewModel
    @EnvironmentObject var appState: AppState
    @State private var showNewContactSheet = false
    
    init(userId: UUID? = nil) {
        // Use provided userId or create placeholder (will be updated from appState)
        let id = userId ?? UUID()
        _viewModel = StateObject(wrappedValue: ContactsListViewModel(userId: id))
    }
    
    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.contacts.isEmpty {
                LoadingView(message: "Loading contacts...")
            } else if viewModel.filteredContacts.isEmpty {
                EmptyStateView(
                    icon: "person.2.slash",
                    title: "No Contacts Yet",
                    message: "Start building your network by adding your first contact.",
                    actionTitle: "Add Contact",
                    action: { showNewContactSheet = true }
                )
            } else {
                List {
                    ForEach(viewModel.filteredContacts) { contact in
                        NavigationLink {
                            ContactDetailView(contactId: contact.id)
                        } label: {
                            ContactRow(contact: contact)
                        }
                    }
                }
                .listStyle(.plain)
                .searchable(text: $viewModel.searchText, prompt: "Search contacts")
            }
        }
        .navigationTitle("Contacts")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showNewContactSheet = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showNewContactSheet) {
            NewContactSheet {
                await viewModel.loadContacts()
            }
            .environmentObject(appState)
        }
        .onAppear {
            // Update userId from appState if available
            if let userId = appState.currentUserId {
                Task {
                    await viewModel.loadContacts()
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ContactsListView()
    }
    .environmentObject(AppState())
}

