//
//  SentEmail.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import SwiftData

@Model
final class SentEmail {
    var id: UUID
    var from: String
    var to: [String]
    var cc: [String]?
    var bcc: [String]?
    var subject: String
    var htmlContent: String
    var textContent: String?
    var sentAt: Date
    var resendId: String?

    @Relationship(deleteRule: .cascade)
    var attachments: [StoredAttachment]?

    var senderAccount: SenderAccount?

    init(
        id: UUID = UUID(),
        from: String,
        to: [String],
        cc: [String]? = nil,
        bcc: [String]? = nil,
        subject: String,
        htmlContent: String,
        textContent: String? = nil,
        sentAt: Date = Date(),
        resendId: String? = nil,
        attachments: [StoredAttachment]? = nil,
        senderAccount: SenderAccount? = nil
    ) {
        self.id = id
        self.from = from
        self.to = to
        self.cc = cc
        self.bcc = bcc
        self.subject = subject
        self.htmlContent = htmlContent
        self.textContent = textContent
        self.sentAt = sentAt
        self.resendId = resendId
        self.attachments = attachments
        self.senderAccount = senderAccount
    }

    // MARK: - Computed Properties

    var recipientsSummary: String {
        to.joined(separator: ", ")
    }

    var hasAttachments: Bool {
        !(attachments?.isEmpty ?? true)
    }

    var attachmentCount: Int {
        attachments?.count ?? 0
    }

    // MARK: - File Cleanup

    func deleteAttachmentFiles() {
        AttachmentStorageService.shared.deleteEmailFolder(emailId: id)
    }
}
