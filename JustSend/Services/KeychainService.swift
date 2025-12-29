//
//  KeychainService.swift
//  JustSend
//
//  Created by Prajeet Shrestha on 28/12/2025.
//

import Foundation
import Security

final class KeychainService {
    static let shared = KeychainService()

    private let serviceName = "com.justSend.apiKeys"

    private init() {}

    // MARK: - Save API Key

    @discardableResult
    func saveAPIKey(_ apiKey: String, for accountId: String) -> Bool {
        guard let data = apiKey.data(using: .utf8) else { return false }

        // Delete existing key first
        deleteAPIKey(for: accountId)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountId,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve API Key

    func retrieveAPIKey(for accountId: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountId,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let apiKey = String(data: data, encoding: .utf8) else {
            return nil
        }

        return apiKey
    }

    // MARK: - Delete API Key

    @discardableResult
    func deleteAPIKey(for accountId: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountId
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Update API Key

    @discardableResult
    func updateAPIKey(_ apiKey: String, for accountId: String) -> Bool {
        guard let data = apiKey.data(using: .utf8) else { return false }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountId
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecItemNotFound {
            return saveAPIKey(apiKey, for: accountId)
        }

        return status == errSecSuccess
    }

    // MARK: - Check if API Key Exists

    func hasAPIKey(for accountId: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: accountId,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
