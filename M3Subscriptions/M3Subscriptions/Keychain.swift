//
//  Keychain.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 28/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

class Keychain {
    static let `default` = Keychain()

    private let server = "mcubedsw.com"

    func addToken(_ token: String) throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: self.server,
            kSecValueData as String: token
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw Error.unhandledError(status: status)
        }
    }

    func removeToken() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: self.server
        ]

        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Error.unhandledError(status: status)
        }
    }

    func fetchToken() throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassInternetPassword,
            kSecAttrServer as String: self.server,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true,
            kSecReturnData as String: true
        ]

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status != errSecItemNotFound else {
            throw Error.noPassword
        }
        guard status == errSecSuccess else {
            throw Error.unhandledError(status: status)
        }

        guard
            let existingItem = item as? [String: Any],
            let tokenData = existingItem[kSecValueData as String] as? Data,
            let token = String(data: tokenData, encoding: .utf8)
        else {
            throw Error.unexpectedPasswordData
        }

        return token
    }

}

extension Keychain {
    enum Error: Swift.Error {
        case noPassword
        case unexpectedPasswordData
        case unhandledError(status: OSStatus)
    }
}
