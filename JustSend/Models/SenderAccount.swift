//
//  SenderAccount.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import SwiftData

@Model
final class SenderAccount {
    var id: UUID
    var websiteName: String
    var emailAddress: String
    var signature: String?
    var createdAt: Date
    var isDefault: Bool

    @Relationship(deleteRule: .nullify, inverse: \SentEmail.senderAccount)
    var sentEmails: [SentEmail]?

    init(
        id: UUID = UUID(),
        websiteName: String,
        emailAddress: String,
        signature: String? = nil,
        createdAt: Date = Date(),
        isDefault: Bool = false
    ) {
        self.id = id
        self.websiteName = websiteName
        self.emailAddress = emailAddress
        self.signature = signature
        self.createdAt = createdAt
        self.isDefault = isDefault
    }

    // MARK: - Keychain API Key Management

    var apiKey: String? {
        get {
            KeychainService.shared.retrieveAPIKey(for: id.uuidString)
        }
        set {
            if let newValue = newValue {
                KeychainService.shared.saveAPIKey(newValue, for: id.uuidString)
            } else {
                KeychainService.shared.deleteAPIKey(for: id.uuidString)
            }
        }
    }

    func deleteAPIKey() {
        KeychainService.shared.deleteAPIKey(for: id.uuidString)
    }
}
