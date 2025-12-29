//
//  AccountsView.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AccountsViewModel()
    @State private var showingAddSheet = false
    @State private var editingAccount: SenderAccount?
    @State private var showingDeleteConfirmation = false
    @State private var accountToDelete: SenderAccount?
    @State private var accountToEditSignature: SenderAccount?
    @State private var prefilledWebsiteName: String?
    @State private var prefilledAPIKey: String?

    // Group accounts by website name
    private var groupedAccounts: [(website: String, accounts: [SenderAccount])] {
        let grouped = Dictionary(grouping: viewModel.accounts) { $0.websiteName }
        return grouped.map { (website: $0.key, accounts: $0.value) }
            .sorted { $0.website.lowercased() < $1.website.lowercased() }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Content
            if viewModel.accounts.isEmpty {
                emptyState
            } else {
                accountsList
            }
        }
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .sheet(isPresented: $showingAddSheet) {
            AccountFormView(viewModel: viewModel, prefilledWebsiteName: prefilledWebsiteName)
        }
        .sheet(item: $editingAccount) { account in
            AccountFormView(viewModel: viewModel, editingAccount: account)
        }
        .sheet(item: $accountToEditSignature) { account in
            SignatureEditorView(viewModel: viewModel, account: account)
        }
        .alert("Delete Account", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let account = accountToDelete {
                    viewModel.deleteAccount(account)
                }
            }
        } message: {
            Text("Are you sure you want to delete this account? The API key will also be removed from Keychain.")
        }
        .onChange(of: showingAddSheet) { _, isShowing in
            if !isShowing {
                prefilledWebsiteName = nil
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("Sender Accounts")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: { showingAddSheet = true }) {
                Label("Add Account", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Sender Accounts")
                .font(.title3)
                .fontWeight(.medium)

            Text("Add a sender account to start sending emails.\nYou'll need a Resend API key and a verified email address.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button(action: { showingAddSheet = true }) {
                Label("Add Your First Account", systemImage: "plus.circle")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    // MARK: - Accounts List

    private var accountsList: some View {
        List {
            ForEach(groupedAccounts, id: \.website) { group in
                Section {
                    // Account rows
                    ForEach(group.accounts, id: \.id) { account in
                        AccountRowView(
                            account: account,
                            showWebsiteName: false,
                            accountCount: group.accounts.count,
                            onEdit: { editingAccount = account },
                            onDelete: {
                                accountToDelete = account
                                showingDeleteConfirmation = true
                            },
                            onSetDefault: { viewModel.setAsDefault(account) },
                            onEditSignature: { accountToEditSignature = account }
                        )
                    }

                    // Add another account button
                    Button(action: {
                        prefilledWebsiteName = group.website
                        showingAddSheet = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle")
                                .foregroundColor(.accentColor)
                            Text("Add another account")
                                .font(.subheadline)
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                } header: {
                    WebsiteGroupHeader(
                        websiteName: group.website,
                        accountCount: group.accounts.count
                    )
                }
            }
        }
        .listStyle(.inset)
    }
}

// MARK: - Website Group Header

struct WebsiteGroupHeader: View {
    let websiteName: String
    let accountCount: Int

    var body: some View {
        HStack(spacing: 8) {
            // Website icon
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 28, height: 28)

                Text(String(websiteName.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.accentColor)
            }

            Text(websiteName)
                .font(.headline)
                .foregroundColor(.primary)

            // Account count badge
            if accountCount > 1 {
                Text("\(accountCount) accounts")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.2))
                    .foregroundColor(.secondary)
                    .cornerRadius(10)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Account Row View

struct AccountRowView: View {
    let account: SenderAccount
    var showWebsiteName: Bool = true
    var accountCount: Int = 1
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onSetDefault: () -> Void
    let onEditSignature: () -> Void

    // Extract username from email for display
    private var emailUsername: String {
        account.emailAddress.components(separatedBy: "@").first ?? account.emailAddress
    }

    // Extract domain from email
    private var emailDomain: String {
        account.emailAddress.components(separatedBy: "@").last ?? ""
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon - shows email initial when grouped, website initial when standalone
            ZStack {
                Circle()
                    .fill(account.isDefault ? Color.accentColor : Color.secondary.opacity(0.2))
                    .frame(width: 36, height: 36)

                Text(String(emailUsername.prefix(1)).uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(account.isDefault ? .white : .primary)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    // Show website name only if not grouped
                    if showWebsiteName {
                        Text(account.websiteName)
                            .font(.headline)
                    }

                    // Email address with enhanced styling
                    if showWebsiteName {
                        Text(account.emailAddress)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        // When grouped, show email more prominently
                        HStack(spacing: 0) {
                            Text(emailUsername)
                                .font(.system(.subheadline, weight: .medium))
                                .foregroundColor(.primary)
                            Text("@\(emailDomain)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }

                    if account.isDefault {
                        Text("Default")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .foregroundColor(.accentColor)
                            .cornerRadius(4)
                    }

                    // Visual indicator for multiple accounts
                    if accountCount > 1 && !showWebsiteName {
                        Image(systemName: "person.2.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary.opacity(0.6))
                            .help("This website has \(accountCount) accounts")
                    }
                }

                // API Key status
                HStack(spacing: 4) {
                    Image(systemName: account.apiKey != nil ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(account.apiKey != nil ? .green : .red)
                        .font(.caption2)

                    Text(account.apiKey != nil ? "API Key configured" : "No API Key")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    // Show creation date for better distinction
                    Text("·")
                        .foregroundColor(.secondary)
                    Text("Added \(account.createdAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }

            Spacer()

            // Actions
            HStack(spacing: 8) {
                if !account.isDefault {
                    Button(action: onSetDefault) {
                        Image(systemName: "star")
                    }
                    .buttonStyle(.borderless)
                    .help("Set as Default")
                }

                Button(action: onEdit) {
                    Image(systemName: "pencil")
                }
                .buttonStyle(.borderless)
                .help("Edit")

                Menu {
                    Button("Edit Signature", action: onEditSignature)
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.secondary)
                }
                .menuStyle(.borderlessButton)
                .help("Settings")

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .foregroundColor(.red)
                }
                .buttonStyle(.borderless)
                .help("Delete")
            }
        }
        .padding(.vertical, 6)
    }
}

// MARK: - Account Form View

struct AccountFormView: View {
    @Environment(\.dismiss) private var dismiss
    let viewModel: AccountsViewModel
    var editingAccount: SenderAccount?
    var prefilledWebsiteName: String?

    @State private var websiteName = ""
    @State private var emailAddress = ""
    @State private var apiKey = ""
    @State private var showAPIKey = false

    @FocusState private var focusedField: Field?
    
    enum Field {
        case websiteName
        case emailAddress
        case apiKey
        case signature
    }

    var isEditing: Bool { editingAccount != nil }
    var isAddingToExistingWebsite: Bool { prefilledWebsiteName != nil && !isEditing }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(isEditing ? "Edit Account" : (isAddingToExistingWebsite ? "Add Another Account" : "Add Account"))
                        .font(.title2)
                        .fontWeight(.semibold)

                    if isAddingToExistingWebsite, let website = prefilledWebsiteName {
                        Text("Adding to \(website)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Form
            Form {
                Section {
                    if isAddingToExistingWebsite {
                        // Show website name as read-only when adding to existing
                        HStack {
                            Text(websiteName)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    } else {
                        TextField("Website Name", text: $websiteName)
                            .textFieldStyle(.roundedBorder)
                            .focused($focusedField, equals: .websiteName)
                    }

                    TextField("Email Address", text: $emailAddress)
                        .textFieldStyle(.roundedBorder)
                        .focused($focusedField, equals: .emailAddress)

                    HStack {
                        if showAPIKey {
                            TextField("Resend API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .apiKey)
                        } else {
                            SecureField("Resend API Key", text: $apiKey)
                                .textFieldStyle(.roundedBorder)
                                .focused($focusedField, equals: .apiKey)
                        }

                        Button(action: { showAPIKey.toggle() }) {
                            Image(systemName: showAPIKey ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.borderless)
                    }

                    if !apiKey.isEmpty && !viewModel.validateAPIKeyFormat(apiKey) {
                        Text("API key should start with 're_'")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                } header: {
                    Text("Account Details")
                } footer: {
                    if isAddingToExistingWebsite {
                        Text("You can have multiple email accounts for the same website, each with its own API key.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

            }
            .formStyle(.grouped)
            .frame(minHeight: 200)

            Divider()

            // Footer
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Button(isEditing ? "Save Changes" : "Add Account") {
                    saveAccount()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isFormValid)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 450, height: isAddingToExistingWebsite ? 380 : 350)
        .onAppear {
            if let account = editingAccount {
                websiteName = account.websiteName
                emailAddress = account.emailAddress
                apiKey = account.apiKey ?? ""
            } else if let prefilled = prefilledWebsiteName {
                websiteName = prefilled
                // Pre-fill API key if available
                if let existingKey = viewModel.getExistingAPIKey(for: prefilled) {
                    apiKey = existingKey
                }
                // Pre-fill email domain
                if emailAddress.isEmpty, let domain = viewModel.getExistingDomain(for: prefilled) {
                    emailAddress = "@" + domain
                }
                // Focus on email address since website is prefilled
                focusedField = .emailAddress
            } else {
                // Focus on website name for new account
                focusedField = .websiteName
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            // When focus leaves the website name field
            if oldValue == .websiteName && newValue != .websiteName {
                // Auto-fill API key and email domain if user types a known website name
                if !isEditing, !websiteName.isEmpty {
                    if apiKey.isEmpty, let existingKey = viewModel.getExistingAPIKey(for: websiteName) {
                        apiKey = existingKey
                    }
                    
                    if emailAddress.isEmpty, let domain = viewModel.getExistingDomain(for: websiteName) {
                        emailAddress = "@" + domain
                    }
                }
            }
        }
    }

    private var isFormValid: Bool {
        !websiteName.isEmpty &&
        !emailAddress.isEmpty &&
        !apiKey.isEmpty &&
        viewModel.validateEmailFormat(emailAddress) &&
        viewModel.validateAPIKeyFormat(apiKey)
    }

    private func saveAccount() {
        if let account = editingAccount {
            viewModel.updateAccount(account, websiteName: websiteName, emailAddress: emailAddress, apiKey: apiKey, signature: account.signature)
        } else {
            viewModel.addAccount(websiteName: websiteName, emailAddress: emailAddress, apiKey: apiKey, signature: nil)
            
            AnalyticsService.shared.trackAccountAdded(websiteDomain: websiteName)
        }
        dismiss()
    }
}

#Preview {
    AccountsView()
        .modelContainer(for: [SenderAccount.self, SentEmail.self, StoredAttachment.self], inMemory: true)
}
