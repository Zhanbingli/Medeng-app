//
//  SecureStorage.swift
//  Medeng
//
//  Secure storage for sensitive data using Keychain
//

import Foundation
import Security

/// Secure storage service using iOS Keychain
/// Stores sensitive data like API keys securely
class SecureStorage {

    enum KeychainError: Error, LocalizedError {
        case unableToSave
        case unableToLoad
        case unableToDelete
        case itemNotFound

        var errorDescription: String? {
            switch self {
            case .unableToSave:
                return "Unable to save data to Keychain"
            case .unableToLoad:
                return "Unable to load data from Keychain"
            case .unableToDelete:
                return "Unable to delete data from Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            }
        }
    }

    /// Save a string value securely in Keychain
    /// - Parameters:
    ///   - key: The key to identify the value
    ///   - value: The string value to save
    /// - Throws: KeychainError if save fails
    func save(key: String, value: String) throws {
        guard let data = value.data(using: .utf8) else {
            throw KeychainError.unableToSave
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        // Delete existing item if present
        SecItemDelete(query as CFDictionary)

        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw KeychainError.unableToSave
        }
    }

    /// Load a string value from Keychain
    /// - Parameter key: The key to identify the value
    /// - Returns: The stored string value, or nil if not found
    /// - Throws: KeychainError if load fails
    func load(key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status != errSecItemNotFound else {
            return nil // Item doesn't exist yet, not an error
        }

        guard status == errSecSuccess else {
            throw KeychainError.unableToLoad
        }

        guard let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unableToLoad
        }

        return string
    }

    /// Delete a value from Keychain
    /// - Parameter key: The key to identify the value
    /// - Throws: KeychainError if delete fails
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]

        let status = SecItemDelete(query as CFDictionary)

        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unableToDelete
        }
    }

    /// Check if a key exists in Keychain
    /// - Parameter key: The key to check
    /// - Returns: True if the key exists, false otherwise
    func exists(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: false
        ]

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }
}
