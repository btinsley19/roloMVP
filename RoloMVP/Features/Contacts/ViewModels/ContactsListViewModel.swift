//
//  ContactsListViewModel.swift
//  RoloMVP
//

import Foundation
import OSLog

@MainActor
class ContactsListViewModel: ObservableObject {
    @Published var contacts: [Contact] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var error: ServiceError?
    
    private let logger = Logger.viewModels
    private let contactsService: ContactsServiceProtocol
    private let userId: UUID
    
    var filteredContacts: [Contact] {
        if searchText.isEmpty {
            return contacts
        }
        return contacts.filter { contact in
            contact.fullName.localizedCaseInsensitiveContains(searchText) ||
            contact.companyName?.localizedCaseInsensitiveContains(searchText) ?? false ||
            contact.position?.localizedCaseInsensitiveContains(searchText) ?? false
        }
    }
    
    init(userId: UUID,
         contactsService: ContactsServiceProtocol? = nil) {
        self.userId = userId
        self.contactsService = contactsService ?? ContactsService()
    }
    
    func loadContacts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            logger.info("Loading contacts for user: \(self.userId.uuidString)")
            contacts = try await contactsService.fetchContacts(owner: self.userId, search: nil, limit: 50, offset: 0)
        } catch let error as ServiceError {
            logger.error("Failed to load contacts: \(error.localizedDescription)")
            self.error = error
        } catch {
            logger.error("Unexpected error loading contacts: \(error.localizedDescription)")
            self.error = .unknown(error.localizedDescription)
        }
    }
}


