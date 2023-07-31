//
//  FakeKeychain.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 30/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation
@testable import M3Subscriptions

class FakeKeychain: Keychain {
    var token: String?

    func addToken(_ token: String) throws {
        self.token = token
    }

    func removeToken() throws {
        self.token = nil
    }

    func fetchToken() throws -> String {
        guard let token = self.token else {
            throw KeychainError.noPassword
        }
        return token
    }
}
