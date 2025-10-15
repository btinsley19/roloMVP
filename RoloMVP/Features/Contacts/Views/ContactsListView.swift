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
                VStack(spacing: 0) {
                    HStack(spacing: 12) {
                        ForEach(ContactsListViewModel.ContactListTab.allCases, id: \.self) { tab in
                            Button {
                                viewModel.selectedTab = tab
                            } label: {
                                Text(tab.rawValue)
                                    .font(.subheadline)
                                    .fontWeight(viewModel.selectedTab == tab ? .regular : .regular)
                                    .foregroundColor(viewModel.selectedTab == tab ? .black : .primary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(
                                        viewModel.selectedTab == tab ?
                                        Color.gray.opacity(0.5) :
                                            Color.gray.opacity(0.2)
                                    )
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(
                                                viewModel.selectedTab == tab ?
                                                Color.gray.opacity(0.5) :
                                                    Color.gray.opacity(0.3),
                                                lineWidth: 1
                                            )
                                    )
                            }
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    
                    
                    List {
                        ForEach(viewModel.filteredContacts) { contact in
                            ContactRow(contact: contact)
                                .listRowSeparator(.hidden)
                                .listRowInsets(EdgeInsets())
                                .background(
                                    NavigationLink("", destination: ContactDetailView(contactId: contact.id))
                                        .opacity(0)
                                    )
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20) //FIX- sometimes doesn't show up
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

