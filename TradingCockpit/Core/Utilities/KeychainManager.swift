//
//  KeychainManager.swift
//  Financial Trading Cockpit
//
//  Created on 2025-11-24
//

import Foundation
import Security

/// Manages secure storage of sensitive data in the Keychain
class KeychainManager {
    // MARK: - Singleton

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Constants

    private let service = "com.tradingcockpit.app"

    // MARK: - Error Types

    enum KeychainError: Error, LocalizedError {
        case storeFailed(OSStatus)
        case retrieveFailed(OSStatus)
        case deleteFailed(OSStatus)
        case dataConversionFailed
        case itemNotFound

        var errorDescription: String? {
            switch self {
            case .storeFailed(let status):
                return "Failed to store item in Keychain (status: \(status))"
            case .retrieveFailed(let status):
                return "Failed to retrieve item from Keychain (status: \(status))"
            case .deleteFailed(let status):
                return "Failed to delete item from Keychain (status: \(status))"
            case .dataConversionFailed:
                return "Failed to convert data"
            case .itemNotFound:
                return "Item not found in Keychain"
            }
        }
    }

    // MARK: - Public Methods

    /// Store auth token for a broker
    func storeAuthToken(_ token: AuthToken, for broker: Broker) throws {
        let account = "auth_token_\(broker.rawValue)"
        let data = try JSONEncoder().encode(token)
        try store(data, account: account)
        Logger.info("✅ Stored auth token for \(broker.rawValue)")
    }

    /// Retrieve auth token for a broker
    func retrieveAuthToken(for broker: Broker) throws -> AuthToken {
        let account = "auth_token_\(broker.rawValue)"
        let data = try retrieve(account: account)
        let token = try JSONDecoder().decode(AuthToken.self, from: data)
        Logger.debug("✅ Retrieved auth token for \(broker.rawValue)")
        return token
    }

    /// Delete auth token for a broker
    func deleteAuthToken(for broker: Broker) throws {
        let account = "auth_token_\(broker.rawValue)"
        try delete(account: account)
        Logger.info("🗑️ Deleted auth token for \(broker.rawValue)")
    }

    // MARK: - Generic Storage Methods

    /// Store arbitrary data in Keychain
    func store(_ data: Data, account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]

        // Delete existing item if any
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }

    /// Retrieve data from Keychain
    func retrieve(account: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.retrieveFailed(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.dataConversionFailed
        }

        return data
    }

    /// Delete item from Keychain
    func delete(account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }

    /// Clear all app data from Keychain
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }

        Logger.info("🗑️ Cleared all Keychain data")
    }
}

// MARK: - AuthToken Model

struct AuthToken: Codable {
    let accessToken: String
    let refreshToken: String?
    let expiresIn: Int
    let tokenType: String
    let scope: String?
    let issuedAt: Date

    var isExpired: Bool {
        let expirationDate = issuedAt.addingTimeInterval(TimeInterval(expiresIn))
        return Date() > expirationDate
    }

    var needsRefresh: Bool {
        // Refresh if token expires in less than 5 minutes
        let expirationDate = issuedAt.addingTimeInterval(TimeInterval(expiresIn))
        let refreshThreshold = expirationDate.addingTimeInterval(-300) // 5 minutes before
        return Date() > refreshThreshold
    }

    init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresIn: Int,
        tokenType: String = "Bearer",
        scope: String? = nil,
        issuedAt: Date = Date()
    ) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.tokenType = tokenType
        self.scope = scope
        self.issuedAt = issuedAt
    }
}
