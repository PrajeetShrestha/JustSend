//
//  ResendService.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import Combine

/// Service for sending emails via Resend API
class ResendService: ObservableObject {
    private let baseURL = "https://api.resend.com"
    private var apiKey: String
    private let session: URLSession

    @Published var isSending = false
    @Published var lastError: String?
    @Published var lastSuccess: Bool = false

    init(apiKey: String, session: URLSession = .shared) {
        self.apiKey = apiKey
        self.session = session
    }

    /// Send an email using Resend API
    /// - Parameters:
    ///   - from: Sender email address (must be verified domain in Resend)
    ///   - to: Recipient email addresses (max 50)
    ///   - subject: Email subject
    ///   - htmlContent: HTML content of the email
    ///   - textContent: Plain text fallback (optional)
    ///   - cc: Carbon copy recipients (optional)
    ///   - bcc: Blind carbon copy recipients (optional)
    ///   - replyTo: Reply-to email addresses (optional)
    ///   - attachments: File attachments (optional)
    /// - Returns: Result with SendEmailResponse or Error
    func sendEmail(
        from: String,
        to: [String],
        subject: String,
        htmlContent: String,
        textContent: String? = nil,
        ccc: [String]? = nil,
        bcc: [String]? = nil,
        replyTo: [String]? = nil,
        attachments: [EmailAttachment]? = nil
    ) async throws -> SendEmailResponse {
        guard !apiKey.isEmpty else {
            throw ResendError.missingAPIKey
        }

        let url = URL(string: "\(baseURL)/emails")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var body: [String: Any] = [
            "from": from,
            "to": to,
            "subject": subject,
            "html": htmlContent
        ]

        if let text = textContent, !text.isEmpty {
            body["text"] = text
        }

        if let cc = ccc, !cc.isEmpty {
            body["cc"] = cc
        }

        if let bcc = bcc, !bcc.isEmpty {
            body["bcc"] = bcc
        }

        if let replyTo = replyTo, !replyTo.isEmpty {
            body["reply_to"] = replyTo
        }

        if let attachments = attachments, !attachments.isEmpty {
            body["attachments"] = attachments.map { attachment in
                var dict: [String: Any] = [
                    "filename": attachment.filename,
                    "content": attachment.content
                ]
                if let contentType = attachment.contentType {
                    dict["content_type"] = contentType
                }
                return dict
            }
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw ResendError.invalidResponse
        }

        if httpResponse.statusCode == 200 || httpResponse.statusCode == 201 {
            let decoder = JSONDecoder()
            return try decoder.decode(SendEmailResponse.self, from: data)
        } else {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(ResendErrorResponse.self, from: data) {
                throw ResendError.apiError(
                    statusCode: httpResponse.statusCode,
                    message: errorResponse.message
                )
            }
            throw ResendError.httpError(statusCode: httpResponse.statusCode)
        }
    }

    /// Send email with completion handler (for use with @MainActor)
    @MainActor
    func sendEmailAsync(
        from: String,
        to: [String],
        subject: String,
        htmlContent: String,
        textContent: String? = nil,
        ccc: [String]? = nil,
        bcc: [String]? = nil,
        replyTo: [String]? = nil,
        attachments: [EmailAttachment]? = nil
    ) async {
        isSending = true
        lastError = nil
        lastSuccess = false

        do {
            let response = try await sendEmail(
                from: from,
                to: to,
                subject: subject,
                htmlContent: htmlContent,
                textContent: textContent,
                ccc: ccc,
                bcc: bcc,
                replyTo: replyTo,
                attachments: attachments
            )
            print("Email sent successfully! ID: \(response.id)")
            lastSuccess = true
        } catch {
            lastError = error.localizedDescription
            print("Failed to send email: \(error)")
        }

        isSending = false
    }
}

// MARK: - Attachment Model
struct EmailAttachment {
    /// The name of the attached file
    let filename: String
    /// Base64-encoded content of the file
    let content: String
    /// MIME type (e.g., "application/pdf", "image/png")
    let contentType: String?

    init(filename: String, content: String, contentType: String? = nil) {
        self.filename = filename
        self.content = content
        self.contentType = contentType
    }

    /// Create attachment from file URL
    static func fromURL(_ url: URL) throws -> EmailAttachment {
        let data = try Data(contentsOf: url)
        let base64Content = data.base64EncodedString()
        let filename = url.lastPathComponent

        // Determine content type from file extension
        let contentType = mimeType(for: url.pathExtension)

        return EmailAttachment(
            filename: filename,
            content: base64Content,
            contentType: contentType
        )
    }

    /// MIME type mapping for common file extensions
    private static let mimeTypes: [String: String] = [
        "pdf": "application/pdf",
        "png": "image/png",
        "jpg": "image/jpeg",
        "jpeg": "image/jpeg",
        "gif": "image/gif",
        "txt": "text/plain",
        "html": "text/html",
        "htm": "text/html",
        "css": "text/css",
        "js": "application/javascript",
        "json": "application/json",
        "xml": "application/xml",
        "zip": "application/zip",
        "csv": "text/csv",
        "mp3": "audio/mpeg",
        "mp4": "video/mp4"
    ]

    /// Get MIME type for file extension
    private static func mimeType(for ext: String) -> String {
        mimeTypes[ext.lowercased()] ?? "application/octet-stream"
    }
}

// MARK: - Response Models
struct SendEmailResponse: Codable {
    let id: String
}

struct ResendErrorResponse: Codable {
    let statusCode: Int?
    let message: String
    let name: String?
}

// MARK: - Errors
enum ResendError: LocalizedError {
    case missingAPIKey
    case invalidResponse
    case httpError(statusCode: Int)
    case apiError(statusCode: Int, message: String)
    case attachmentError(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "API key is missing. Please configure your Resend API key."
        case .invalidResponse:
            return "Received an invalid response from the server."
        case .httpError(let statusCode):
            return "HTTP error with status code: \(statusCode)"
        case .apiError(_, let message):
            return message
        case .attachmentError(let message):
            return "Attachment error: \(message)"
        }
    }
}

// MARK: - Configuration (Deprecated - Use SenderAccount with Keychain instead)
// API keys are now stored securely in Keychain via SenderAccount model
