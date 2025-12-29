//
//  EmailComposerView.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import SwiftUI
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct EmailComposerView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SenderAccount.createdAt, order: .reverse) private var accounts: [SenderAccount]

    @State private var viewModel = EmailComposerViewModel()
    @State private var selectedAccountId: UUID?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection

            Divider()

            // Email fields
            emailFieldsSection

            Divider()

            // Attachment bar
            attachmentBar

            Divider()

            // Rich text editor (includes its own formatting toolbar)
            RichTextEditor(htmlContent: $viewModel.htmlContent)
                .frame(minHeight: 100)
                .clipped()
                .layoutPriority(-1)

            Divider()

            // Attachments section
            if !viewModel.attachments.isEmpty {
                attachmentsSection
                Divider()
            }

            // Footer with send button
            footerSection
        }
        .frame(minWidth: 650, minHeight: 600)
        .onAppear {
            viewModel.setModelContext(modelContext)
            if let defaultAccount = accounts.first(where: { $0.isDefault }) ?? accounts.first {
                selectedAccountId = defaultAccount.id
                viewModel.setSelectedAccount(defaultAccount)
            }
        }
        .onChange(of: selectedAccountId) { _, newId in
            if let account = accounts.first(where: { $0.id == newId }) {
                viewModel.setSelectedAccount(account)
            }
        }
        .alert(viewModel.alertTitle, isPresented: $viewModel.showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.alertMessage)
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            Image(systemName: "envelope.fill")
                .font(.title2)
                .foregroundColor(.accentColor)

            Text("Compose Email")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            if viewModel.isSending {
                ProgressView()
                    .scaleEffect(0.8)
                    .padding(.trailing, 8)
                Text("Sending...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Email Fields Section
    private var emailFieldsSection: some View {
        VStack(spacing: 10) {
            // Account picker
            HStack {
                Text("Account:")
                    .frame(width: 70, alignment: .trailing)
                    .foregroundColor(.secondary)

                if accounts.isEmpty {
                    Text("No accounts configured")
                        .foregroundColor(.orange)
                        .font(.subheadline)

                    Spacer()

                    Text("Go to Accounts to add one")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Picker("", selection: $selectedAccountId) {
                        Text("Select an account")
                            .tag(nil as UUID?)
                        ForEach(accounts, id: \.id) { account in
                            Text("\(account.websiteName) (\(account.emailAddress))")
                                .tag(account.id as UUID?)
                        }
                    }
                    .labelsHidden()
                }
            }

            // From field (read-only, based on account)
            HStack {
                Text("From:")
                    .frame(width: 70, alignment: .trailing)
                    .foregroundColor(.secondary)

                TextField("sender@yourdomain.com", text: $viewModel.fromEmail)
                    .textFieldStyle(.roundedBorder)
                    .disabled(true)
                    .foregroundColor(.secondary)
            }

            // To field
            HStack {
                Text("To:")
                    .frame(width: 70, alignment: .trailing)
                    .foregroundColor(.secondary)

                TextField("recipient@example.com", text: $viewModel.toEmail)
                    .textFieldStyle(.roundedBorder)

                Button(action: { viewModel.showCcBcc.toggle() }) {
                    Text(viewModel.showCcBcc ? "Hide Cc/Bcc" : "Cc/Bcc")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }

            // CC/BCC fields (collapsible)
            if viewModel.showCcBcc {
                HStack {
                    Text("Cc:")
                        .frame(width: 70, alignment: .trailing)
                        .foregroundColor(.secondary)

                    TextField("cc@example.com", text: $viewModel.ccEmail)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Bcc:")
                        .frame(width: 70, alignment: .trailing)
                        .foregroundColor(.secondary)

                    TextField("bcc@example.com", text: $viewModel.bccEmail)
                        .textFieldStyle(.roundedBorder)
                }

                HStack {
                    Text("Reply-To:")
                        .frame(width: 70, alignment: .trailing)
                        .foregroundColor(.secondary)

                    TextField("reply@example.com", text: $viewModel.replyToEmail)
                        .textFieldStyle(.roundedBorder)
                }
            }

            // Subject field
            HStack {
                Text("Subject:")
                    .frame(width: 70, alignment: .trailing)
                    .foregroundColor(.secondary)

                TextField("Enter subject", text: $viewModel.subject)
                    .textFieldStyle(.roundedBorder)
            }
        }
        .padding()
    }

    // MARK: - Attachment Bar
    private var attachmentBar: some View {
        HStack {
            Button(action: addAttachment) {
                Label("Attach File", systemImage: "paperclip")
                    .font(.caption)
            }
            .buttonStyle(.bordered)

            if !viewModel.attachments.isEmpty {
                Text("\(viewModel.attachments.count) file(s) attached")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(action: loadHTMLFile) {
                Label("Load HTML", systemImage: "doc.text")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(NSColor.controlBackgroundColor))
    }

    // MARK: - Attachments Section
    private var attachmentsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Attachments")
                .font(.caption)
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(viewModel.attachments.indices, id: \.self) { index in
                        attachmentChip(for: viewModel.attachments[index], at: index)
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
    }

    private func attachmentChip(for attachment: EmailAttachment, at index: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: iconForAttachment(attachment))
                .font(.caption)

            Text(attachment.filename)
                .font(.caption)
                .lineLimit(1)

            Button(action: { viewModel.removeAttachment(at: index) }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color(NSColor.controlColor))
        .cornerRadius(4)
    }

    private func iconForAttachment(_ attachment: EmailAttachment) -> String {
        guard let contentType = attachment.contentType else {
            return "doc"
        }
        if contentType.hasPrefix("image/") { return "photo" }
        if contentType.contains("pdf") { return "doc.text" }
        if contentType.contains("zip") { return "archivebox" }
        return "doc"
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        HStack {
            Spacer()

            // Clear button
            Button(action: { viewModel.clearForm() }) {
                Label("Clear", systemImage: "trash")
            }
            .buttonStyle(.bordered)

            // Send button
            Button(action: {
                Task {
                    await viewModel.sendEmail()
                }
            }) {
                Label("Send Email", systemImage: "paperplane.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(!viewModel.isValidEmail || viewModel.isSending || accounts.isEmpty)
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
    }

    // MARK: - Actions
    private func addAttachment() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.message = "Select files to attach (max 40MB total)"

        if panel.runModal() == .OK {
            for url in panel.urls {
                do {
                    let attachment = try EmailAttachment.fromURL(url)
                    viewModel.addAttachment(attachment)
                } catch {
                    viewModel.alertTitle = "Attachment Error"
                    viewModel.alertMessage = "Could not attach \(url.lastPathComponent): \(error.localizedDescription)"
                    viewModel.showAlert = true
                }
            }
        }
    }

    private func loadHTMLFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [UTType.html]
        panel.message = "Select an HTML file for email body"

        if panel.runModal() == .OK, let url = panel.url {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                viewModel.htmlContent = content
            } catch {
                viewModel.alertTitle = "Load Error"
                viewModel.alertMessage = "Could not load \(url.lastPathComponent): \(error.localizedDescription)"
                viewModel.showAlert = true
            }
        }
    }
}

#Preview {
    EmailComposerView()
        .modelContainer(for: [SenderAccount.self, SentEmail.self, StoredAttachment.self], inMemory: true)
}
