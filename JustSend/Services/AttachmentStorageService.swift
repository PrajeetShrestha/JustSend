//
//  AttachmentStorageService.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation

final class AttachmentStorageService {
    static let shared = AttachmentStorageService()

    private let fileManager = FileManager.default
    private let attachmentsFolderName = "Attachments"

    private init() {
        createBaseDirectoryIfNeeded()
    }

    // MARK: - Base Directory

    var baseDirectory: URL? {
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        return appSupport.appendingPathComponent("JustSend").appendingPathComponent(attachmentsFolderName)
    }

    private func createBaseDirectoryIfNeeded() {
        guard let baseDir = baseDirectory else { return }
        if !fileManager.fileExists(atPath: baseDir.path) {
            try? fileManager.createDirectory(at: baseDir, withIntermediateDirectories: true)
        }
    }

    // MARK: - Email Folder Management

    func emailFolder(for emailId: UUID) -> URL? {
        baseDirectory?.appendingPathComponent(emailId.uuidString)
    }

    func createEmailFolder(emailId: UUID) throws -> URL {
        guard let folder = emailFolder(for: emailId) else {
            throw StorageError.invalidPath
        }

        if !fileManager.fileExists(atPath: folder.path) {
            try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
        }

        return folder
    }

    func deleteEmailFolder(emailId: UUID) {
        guard let folder = emailFolder(for: emailId) else { return }
        try? fileManager.removeItem(at: folder)
    }

    // MARK: - File Operations

    func saveAttachment(data: Data, filename: String, emailId: UUID) throws -> String {
        let folder = try createEmailFolder(emailId: emailId)
        let fileURL = folder.appendingPathComponent(filename)

        // Handle duplicate filenames
        var finalURL = fileURL
        var counter = 1
        while fileManager.fileExists(atPath: finalURL.path) {
            let name = (filename as NSString).deletingPathExtension
            let ext = (filename as NSString).pathExtension
            let newName = ext.isEmpty ? "\(name)_\(counter)" : "\(name)_\(counter).\(ext)"
            finalURL = folder.appendingPathComponent(newName)
            counter += 1
        }

        try data.write(to: finalURL)

        // Return relative path from base directory
        return "\(emailId.uuidString)/\(finalURL.lastPathComponent)"
    }

    func saveAttachment(from sourceURL: URL, emailId: UUID) throws -> (localPath: String, fileSize: Int) {
        let data = try Data(contentsOf: sourceURL)
        let filename = sourceURL.lastPathComponent
        let localPath = try saveAttachment(data: data, filename: filename, emailId: emailId)
        return (localPath, data.count)
    }

    func getFullPath(for relativePath: String) -> URL? {
        baseDirectory?.appendingPathComponent(relativePath)
    }

    func deleteAttachment(relativePath: String) {
        guard let fullPath = getFullPath(for: relativePath) else { return }
        try? fileManager.removeItem(at: fullPath)
    }

    func loadAttachment(relativePath: String) throws -> Data {
        guard let fullPath = getFullPath(for: relativePath) else {
            throw StorageError.invalidPath
        }
        return try Data(contentsOf: fullPath)
    }

    // MARK: - Utilities

    func totalStorageUsed() -> Int64 {
        guard let baseDir = baseDirectory else { return 0 }
        return folderSize(at: baseDir)
    }

    private func folderSize(at url: URL) -> Int64 {
        var size: Int64 = 0
        let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: [.fileSizeKey])

        while let fileURL = enumerator?.nextObject() as? URL {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                size += Int64(fileSize)
            }
        }

        return size
    }

    func formattedStorageUsed() -> String {
        let bytes = totalStorageUsed()
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }

    // MARK: - Errors

    enum StorageError: LocalizedError {
        case invalidPath
        case fileNotFound
        case saveFailed

        var errorDescription: String? {
            switch self {
            case .invalidPath:
                return "Invalid storage path"
            case .fileNotFound:
                return "File not found"
            case .saveFailed:
                return "Failed to save file"
            }
        }
    }
}
