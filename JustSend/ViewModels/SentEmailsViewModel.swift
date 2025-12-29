//
//  SentEmailsViewModel.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import SwiftData
import Observation

@Observable
final class SentEmailsViewModel {
    var emails: [SentEmail] = []
    var isLoading = false
    var errorMessage: String?
    var searchText = ""

    private var modelContext: ModelContext?

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchEmails()
    }

    // MARK: - Fetch Operations

    func fetchEmails() {
        guard let modelContext else { return }

        isLoading = true
        errorMessage = nil

        do {
            var descriptor = FetchDescriptor<SentEmail>(
                sortBy: [SortDescriptor(\.sentAt, order: .reverse)]
            )

            if !searchText.isEmpty {
                descriptor.predicate = #Predicate<SentEmail> { email in
                    email.subject.localizedStandardContains(searchText) ||
                    email.from.localizedStandardContains(searchText)
                }
            }

            emails = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch emails: \(error.localizedDescription)"
        }

        isLoading = false
    }

    // MARK: - Delete Operations

    func deleteEmail(_ email: SentEmail) {
        guard let modelContext else { return }

        // Delete attachment files from disk
        email.deleteAttachmentFiles()

        modelContext.delete(email)

        do {
            try modelContext.save()
            fetchEmails()
        } catch {
            errorMessage = "Failed to delete email: \(error.localizedDescription)"
        }
    }

    func deleteEmails(at offsets: IndexSet) {
        for index in offsets {
            deleteEmail(emails[index])
        }
    }

    func deleteAllEmails() {
        guard let modelContext else { return }

        for email in emails {
            email.deleteAttachmentFiles()
            modelContext.delete(email)
        }

        do {
            try modelContext.save()
            fetchEmails()
        } catch {
            errorMessage = "Failed to delete all emails: \(error.localizedDescription)"
        }
    }

    // MARK: - Computed Properties

    var filteredEmails: [SentEmail] {
        if searchText.isEmpty {
            return emails
        }
        return emails.filter { email in
            email.subject.localizedCaseInsensitiveContains(searchText) ||
            email.from.localizedCaseInsensitiveContains(searchText) ||
            email.to.joined().localizedCaseInsensitiveContains(searchText)
        }
    }

    var emailsByDate: [Date: [SentEmail]] {
        Dictionary(grouping: emails) { email in
            Calendar.current.startOfDay(for: email.sentAt)
        }
    }

    var sortedDates: [Date] {
        emailsByDate.keys.sorted(by: >)
    }

    // MARK: - Statistics

    var totalEmailsSent: Int {
        emails.count
    }

    var totalAttachments: Int {
        emails.reduce(0) { $0 + ($1.attachments?.count ?? 0) }
    }

    var storageUsed: String {
        AttachmentStorageService.shared.formattedStorageUsed()
    }
}
