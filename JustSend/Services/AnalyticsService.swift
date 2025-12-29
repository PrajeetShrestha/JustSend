//
//  AnalyticsService.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import FirebaseAnalytics

final class AnalyticsService {
    static let shared = AnalyticsService()

    private init() {}

    /// Logs a generic event to Firebase Analytics
    /// - Parameters:
    ///   - name: The name of the event
    ///   - parameters: Optional parameters for the event
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        Analytics.logEvent(name, parameters: parameters)
    }

    // MARK: - Specific Events

    /// Tracks when an email is successfully sent
    /// - Parameters:
    ///   - hasAttachments: Whether the email had attachments
    ///   - recipientCount: Total number of recipients (To + CC + BCC)
    func trackEmailSent(hasAttachments: Bool, recipientCount: Int) {
        logEvent("email_sent", parameters: [
            "has_attachments": hasAttachments,
            "recipient_count": recipientCount
        ])
    }

    /// Tracks when a new sender account is added
    /// - Parameter websiteDomain: The domain/website name associated with the account
    func trackAccountAdded(websiteDomain: String) {
        logEvent("account_added", parameters: [
            "website_domain": websiteDomain
        ])
    }
}
