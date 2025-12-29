//
//  StoredAttachment.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import SwiftData

@Model
final class StoredAttachment {
    var id: UUID
    var filename: String
    var contentType: String?
    var fileSize: Int
    var localPath: String
    var createdAt: Date

    @Relationship
    var sentEmail: SentEmail?

    init(
        id: UUID = UUID(),
        filename: String,
        contentType: String? = nil,
        fileSize: Int,
        localPath: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.contentType = contentType
        self.fileSize = fileSize
        self.localPath = localPath
        self.createdAt = createdAt
    }

    // MARK: - File Operations

    var fullPath: URL? {
        AttachmentStorageService.shared.getFullPath(for: localPath)
    }

    var fileExists: Bool {
        guard let path = fullPath else { return false }
        return FileManager.default.fileExists(atPath: path.path)
    }

    func loadData() throws -> Data? {
        guard let path = fullPath else { return nil }
        return try Data(contentsOf: path)
    }
}
