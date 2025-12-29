//
//  SentEmailsView.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import SwiftUI
import SwiftData

struct SentEmailsView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = SentEmailsViewModel()
    @State private var selectedEmail: SentEmail?
    @State private var showingDeleteConfirmation = false
    @State private var emailToDelete: SentEmail?

    var body: some View {
        HStack(spacing: 0) {
            // Email list
            emailListPanel
                .frame(width: 350)

            Divider()

            // Detail view
            detailPanel
                .frame(minWidth: 400, maxWidth: .infinity)
        }
        .frame(minWidth: 750, minHeight: 500)
        .onAppear {
            viewModel.setModelContext(modelContext)
        }
        .alert("Delete Email", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let email = emailToDelete {
                    viewModel.deleteEmail(email)
                    if selectedEmail?.id == email.id {
                        selectedEmail = nil
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this email? Attachments will also be deleted from storage.")
        }
    }

    // MARK: - Email List Panel

    private var emailListPanel: some View {
        VStack(spacing: 0) {
            // Header with search
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "paperplane.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)

                    Text("Sent Emails")
                        .font(.title2)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(viewModel.emails.count)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(8)
                }

                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)

                    TextField("Search emails...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .onSubmit {
                            viewModel.fetchEmails()
                        }

                    if !viewModel.searchText.isEmpty {
                        Button(action: {
                            viewModel.searchText = ""
                            viewModel.fetchEmails()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Email list
            if viewModel.emails.isEmpty {
                emptyState
            } else {
                List(selection: $selectedEmail) {
                    ForEach(viewModel.filteredEmails, id: \.id) { email in
                        EmailRowView(email: email, isSelected: selectedEmail?.id == email.id)
                            .tag(email)
                            .contextMenu {
                                Button(action: {
                                    emailToDelete = email
                                    showingDeleteConfirmation = true
                                }) {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                    }
                    .onDelete { offsets in
                        for index in offsets {
                            let email = viewModel.filteredEmails[index]
                            emailToDelete = email
                            showingDeleteConfirmation = true
                        }
                    }
                }
                .listStyle(.inset)
            }

            // Footer with stats
            Divider()

            HStack {
                Text("Storage: \(viewModel.storageUsed)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !viewModel.emails.isEmpty {
                    Button(action: { viewModel.fetchEmails() }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.borderless)
                    .help("Refresh")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }

    // MARK: - Detail Panel

    private var detailPanel: some View {
        Group {
            if let email = selectedEmail {
                EmailDetailView(email: email)
            } else {
                VStack {
                    Spacer()
                    Image(systemName: "envelope.open")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("Select an email to view details")
                        .font(.body)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No Sent Emails")
                .font(.title3)
                .fontWeight(.medium)

            Text("Emails you send will appear here.")
                .font(.body)
                .foregroundColor(.secondary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Email Row View

struct EmailRowView: View {
    let email: SentEmail
    let isSelected: Bool

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(email.recipientsSummary)
                    .font(.headline)
                    .lineLimit(1)

                Spacer()

                Text(dateFormatter.string(from: email.sentAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(email.subject)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack(spacing: 8) {
                if email.hasAttachments {
                    HStack(spacing: 2) {
                        Image(systemName: "paperclip")
                        Text("\(email.attachmentCount)")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }

                if email.cc != nil || email.bcc != nil {
                    Text("Cc/Bcc")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.2))
                        .cornerRadius(3)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Email Detail View

struct EmailDetailView: View {
    let email: SentEmail

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .medium
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text(email.subject)
                        .font(.title2)
                        .fontWeight(.semibold)

                    Text(dateFormatter.string(from: email.sentAt))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Divider()

                // Email metadata
                VStack(alignment: .leading, spacing: 8) {
                    metadataRow(label: "From", value: email.from)
                    metadataRow(label: "To", value: email.recipientsSummary)

                    if let cc = email.cc, !cc.isEmpty {
                        metadataRow(label: "Cc", value: cc.joined(separator: ", "))
                    }

                    if let bcc = email.bcc, !bcc.isEmpty {
                        metadataRow(label: "Bcc", value: bcc.joined(separator: ", "))
                    }

                    if let resendId = email.resendId {
                        metadataRow(label: "Resend ID", value: resendId)
                    }
                }

                Divider()

                // Attachments
                if email.hasAttachments, let attachments = email.attachments {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Attachments (\(attachments.count))")
                            .font(.headline)

                        ForEach(attachments, id: \.id) { attachment in
                            HStack {
                                Image(systemName: iconForContentType(attachment.contentType))
                                    .foregroundColor(.accentColor)

                                Text(attachment.filename)
                                    .font(.body)

                                Spacer()

                                Text(formatFileSize(attachment.fileSize))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(8)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }

                    Divider()
                }

                // HTML Content Preview
                VStack(alignment: .leading, spacing: 8) {
                    Text("Content")
                        .font(.headline)

                    if let textContent = email.textContent, !textContent.isEmpty {
                        Text(textContent)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(20)
                    } else {
                        Text("(HTML content)")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .italic()
                    }
                }
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
    }

    private func metadataRow(label: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text("\(label):")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .trailing)

            Text(value)
                .font(.subheadline)
                .textSelection(.enabled)
        }
    }

    private func iconForContentType(_ contentType: String?) -> String {
        guard let type = contentType else { return "doc" }
        if type.hasPrefix("image/") { return "photo" }
        if type.contains("pdf") { return "doc.text" }
        if type.contains("zip") { return "archivebox" }
        return "doc"
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

#Preview {
    SentEmailsView()
        .modelContainer(for: [SenderAccount.self, SentEmail.self, StoredAttachment.self], inMemory: true)
}
