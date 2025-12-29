//
//  AccountsViewModel.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import SwiftData
import Observation

@Observable
final class AccountsViewModel {
    var accounts: [SenderAccount] = []
    var isLoading = false
    var errorMessage: String?

    private var modelContext: ModelContext?

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        fetchAccounts()
    }

    // MARK: - CRUD Operations

    func fetchAccounts() {
        guard let modelContext else { return }

        isLoading = true
        errorMessage = nil

        do {
            let descriptor = FetchDescriptor<SenderAccount>(
                sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
            )
            accounts = try modelContext.fetch(descriptor)
        } catch {
            errorMessage = "Failed to fetch accounts: \(error.localizedDescription)"
        }

        isLoading = false
    }

    func addAccount(websiteName: String, emailAddress: String, apiKey: String, signature: String?) {
        guard let modelContext else { return }

        let account = SenderAccount(
            websiteName: websiteName,
            emailAddress: emailAddress,
            signature: signature,
            isDefault: accounts.isEmpty
        )

        modelContext.insert(account)
        account.apiKey = apiKey

        do {
            try modelContext.save()
            fetchAccounts()
        } catch {
            errorMessage = "Failed to save account: \(error.localizedDescription)"
        }
    }

    func updateAccount(_ account: SenderAccount, websiteName: String, emailAddress: String, apiKey: String, signature: String?) {
        account.websiteName = websiteName
        account.emailAddress = emailAddress
        account.apiKey = apiKey
        account.signature = signature

        do {
            try modelContext?.save()
            fetchAccounts()
        } catch {
            errorMessage = "Failed to update account: \(error.localizedDescription)"
        }
    }

    func deleteAccount(_ account: SenderAccount) {
        guard let modelContext else { return }

        // Delete API key from Keychain
        account.deleteAPIKey()

        modelContext.delete(account)

        do {
            try modelContext.save()
            fetchAccounts()

            // Set new default if needed
            if account.isDefault, let firstAccount = accounts.first {
                setAsDefault(firstAccount)
            }
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
        }
    }

    func setAsDefault(_ account: SenderAccount) {
        guard let modelContext else { return }

        // Remove default from all accounts
        for acc in accounts {
            acc.isDefault = false
        }

        // Set new default
        account.isDefault = true

        do {
            try modelContext.save()
            fetchAccounts()
        } catch {
            errorMessage = "Failed to set default account: \(error.localizedDescription)"
        }
    }

    // MARK: - Helpers

    var defaultAccount: SenderAccount? {
        accounts.first { $0.isDefault } ?? accounts.first
    }

    func validateAPIKeyFormat(_ apiKey: String) -> Bool {
        // Resend API keys start with "re_"
        apiKey.hasPrefix("re_") && apiKey.count > 10
    }

    func validateEmailFormat(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    func getExistingAPIKey(for websiteName: String) -> String? {
        accounts.first { $0.websiteName.localizedCaseInsensitiveCompare(websiteName) == .orderedSame }?.apiKey
    }

    func getExistingDomain(for websiteName: String) -> String? {
        guard let account = accounts.first(where: { $0.websiteName.localizedCaseInsensitiveCompare(websiteName) == .orderedSame }) else {
            return nil
        }
        let components = account.emailAddress.components(separatedBy: "@")
        return components.count > 1 ? components.last : nil
    }
}
