//
//  EmailComposerViewModel.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import SwiftData
import Observation
import AppKit

@Observable
final class EmailComposerViewModel {
    // Form fields
    var toEmail = ""
    var fromEmail = ""
    var subject = ""
    var ccEmail = ""
    var bccEmail = ""
    var replyToEmail = ""
    var htmlContent = ""
    var attachments: [EmailAttachment] = []

    // State
    var isSending = false
    var showAlert = false
    var alertTitle = ""
    var alertMessage = ""
    var showCcBcc = false

    // Selected account
    var selectedAccount: SenderAccount?

    private var modelContext: ModelContext?
    private var resendService: ResendService?

    init() {}

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    func setSelectedAccount(_ account: SenderAccount?) {
        // Remove old signature if present
        if let oldAccount = selectedAccount, let oldSignature = oldAccount.signature, !oldSignature.isEmpty {
            let signatureHTML = "<br><br>--<br>\(oldSignature.replacingOccurrences(of: "\n", with: "<br>"))"
            if htmlContent.hasSuffix(signatureHTML) {
                htmlContent = String(htmlContent.dropLast(signatureHTML.count))
            }
        }

        self.selectedAccount = account
        if let account = account {
            fromEmail = account.emailAddress
            if let apiKey = account.apiKey {
                resendService = ResendService(apiKey: apiKey)
            }
            
            // Append new signature
            if let signature = account.signature, !signature.isEmpty {
                let signatureHTML = "<br><br>--<br>\(signature.replacingOccurrences(of: "\n", with: "<br>"))"
                htmlContent += signatureHTML
            }
        }
    }

    // MARK: - Validation

    var isValidEmail: Bool {
        !toEmail.isEmpty &&
        !fromEmail.isEmpty &&
        !subject.isEmpty &&
        !htmlContent.isEmpty &&
        isValidEmailFormat(toEmail) &&
        isValidEmailFormat(fromEmail)
    }

    func isValidEmailFormat(_ email: String) -> Bool {
        let emailRegex = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }

    func parseEmails(_ text: String) -> [String]? {
        let emails = text.split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        return emails.isEmpty ? nil : emails
    }

    // MARK: - Plain Text Extraction

    func extractPlainText(from html: String) -> String {
        guard let data = html.data(using: .utf8) else { return "" }
        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]
        if let attributed = try? NSAttributedString(data: data, options: options, documentAttributes: nil) {
            return attributed.string
        }
        return html.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
    }

    // MARK: - Send Email

    func sendEmail() async {
        guard let resendService else {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = "No sender account selected. Please select an account first."
                showAlert = true
            }
            return
        }

        await MainActor.run {
            isSending = true
        }

        let plainText = extractPlainText(from: htmlContent)

        do {
            let response = try await resendService.sendEmail(
                from: fromEmail,
                to: [toEmail],
                subject: subject,
                htmlContent: htmlContent,
                textContent: plainText,
                ccc: parseEmails(ccEmail),
                bcc: parseEmails(bccEmail),
                replyTo: parseEmails(replyToEmail),
                attachments: attachments.isEmpty ? nil : attachments
            )

            // Save to database
            await saveToDatabase(resendId: response.id)

            await MainActor.run {
                alertTitle = "Success"
                alertMessage = "Your email has been sent successfully!"
                
                // Track email sent event
                AnalyticsService.shared.trackEmailSent(
                    hasAttachments: !attachments.isEmpty,
                    recipientCount: 1 + (parseEmails(ccEmail)?.count ?? 0) + (parseEmails(bccEmail)?.count ?? 0)
                )
                
                showAlert = true
                clearForm()
            }
        } catch {
            await MainActor.run {
                alertTitle = "Error"
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }

        await MainActor.run {
            isSending = false
        }
    }

    // MARK: - Save to Database

    @MainActor
    private func saveToDatabase(resendId: String) async {
        guard let modelContext else { return }

        let emailId = UUID()

        // Save attachments to disk and create StoredAttachment records
        var storedAttachments: [StoredAttachment] = []

        for attachment in attachments {
            do {
                // Decode base64 content
                guard let data = Data(base64Encoded: attachment.content) else { continue }

                let localPath = try AttachmentStorageService.shared.saveAttachment(
                    data: data,
                    filename: attachment.filename,
                    emailId: emailId
                )

                let storedAttachment = StoredAttachment(
                    filename: attachment.filename,
                    contentType: attachment.contentType,
                    fileSize: data.count,
                    localPath: localPath
                )

                storedAttachments.append(storedAttachment)
            } catch {
                print("Failed to save attachment: \(error)")
            }
        }

        let sentEmail = SentEmail(
            id: emailId,
            from: fromEmail,
            to: [toEmail],
            cc: parseEmails(ccEmail),
            bcc: parseEmails(bccEmail),
            subject: subject,
            htmlContent: htmlContent,
            textContent: extractPlainText(from: htmlContent),
            resendId: resendId,
            attachments: storedAttachments,
            senderAccount: selectedAccount
        )

        modelContext.insert(sentEmail)

        do {
            try modelContext.save()
        } catch {
            print("Failed to save sent email: \(error)")
        }
    }

    // MARK: - Form Actions

    func clearForm() {
        toEmail = ""
        subject = ""
        ccEmail = ""
        bccEmail = ""
        replyToEmail = ""
        htmlContent = ""
        attachments = []
    }

    func addAttachment(_ attachment: EmailAttachment) {
        attachments.append(attachment)
    }

    func removeAttachment(at index: Int) {
        guard index < attachments.count else { return }
        attachments.remove(at: index)
    }
}
