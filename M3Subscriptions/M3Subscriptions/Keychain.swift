//
//  Keychain.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 28/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

protocol Keychain {
    func addToken(_ token: String) throws
    func removeToken() throws
    func fetchToken() throws -> String
}

class DefaultKeychain: Keychain {
    private let server = "mcubedsw.com"

    func addToken(_ token: String) throws {
        do {
            //Check if token exists
            let existingToken = try self.fetchToken()
            guard token != existingToken else {
                return
            }
            try self.updateToken(token)
        } catch KeychainError.noPassword {
            try self.insertToken(token)
        } catch {
            throw error
        }
    }

    private func insertToken(_ token: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "M Cubed Account Login",
            kSecValueData as String: token,
            kSecAttrAccount as String: "M Cubed Account",
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    private func updateToken(_ token: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "M Cubed Account Login",
            kSecAttrAccount as String: "M Cubed Account",
        ]

        let attributes: [String: Any] = [
            kSecValueData as String: token,
        ]

        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    func removeToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "M Cubed Account Login",
            kSecAttrAccount as String: "M Cubed Account",
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }

    func fetchToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrLabel as String: "M Cubed Account Login",
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true,
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw KeychainError.noPassword
        }
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }

        guard
            let existingItem = item as? [String: Any],
            let tokenData = existingItem[kSecValueData as String] as? Data,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            throw KeychainError.unexpectedPasswordData
        }

        return token
    }
}

enum KeychainError: Swift.Error {
    case noPassword
    case unexpectedPasswordData
    case unhandledError(status: OSStatus)
}

