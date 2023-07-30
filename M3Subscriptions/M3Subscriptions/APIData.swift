//
//  APIData.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import CommonCrypto
import Foundation

struct APIData {
    enum Response: Equatable {
        case active
        case deactivated
        case loginFailed
        case multipleSubscriptions
        case noSubscriptionFound
        case noDeviceFound
        case tooManyDevices
        case expired
        case invalidLicence
        case success
        case loggedIn
        case loggedOut
        case other(String)

        static func response(from string: String) -> Response {
            if (string == "active") {
                return .active
            }
            if (string == "deactivated") {
                return .deactivated
            }
            if (string == "login_failed") {
                return .loginFailed
            }
            if (string == "multiple_subscriptions") {
                return .multipleSubscriptions
            }
            if (string == "no_subscription_found") {
                return .noSubscriptionFound
            }
            if (string == "no_device_found") {
                return .noDeviceFound
            }
            if (string == "too_many_devices") {
                return .tooManyDevices
            }
            if (string == "subscription_expired") {
                return .expired
            }
            if (string == "invalid_licence") {
                return .invalidLicence
            }
            if (string == "success") {
                return .success
            }
            if (string == "logged_in") {
                return .loggedIn
            }
            if (string == "logged_out") {
                return .loggedOut
            }
            return .other(string)
        }
    }

    var payload: [String: Any]
    var signature: String
    var response: Response

    init?(json: [String: Any]) {
        guard let payload = json["payload"] as? [String: Any],
            let response = payload["response"] as? String,
            let signature = json["signature"] as? String
        else {
                return nil
        }

        guard APIData.verify(payload: payload, signature: signature) == signature else {
            return nil
        }

        self.payload = payload
        self.signature = signature
        self.response = Response.response(from: response)
    }

    static func verify(payload: [String: Any], signature: String) -> String? {
        guard let payloadData = try? JSONSerialization.data(withJSONObject: payload, options: .sortedKeys) else {
            return nil
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        payloadData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(payloadData.count), &hash)
        }

        let hashedPayload = Data(hash)


        let publicKey = self.publicKey()
        guard let data = Data(base64Encoded: publicKey as String, options: .ignoreUnknownCharacters) else {
            return nil
        }

        let options: [String: Any] = [kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                      kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                      kSecAttrKeySizeInBits as String: 2048]
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, options as CFDictionary, &error) else {
            return nil
        }

        guard SecKeyIsAlgorithmSupported(key, .verify, .rsaSignatureDigestPKCS1v15SHA256) else {
            return nil
        }

        guard let signatureData = Data(base64Encoded: signature) else {
            return nil
        }

        guard SecKeyVerifySignature(key,
                                    .rsaSignatureDigestPKCS1v15SHA256,
                                    hashedPayload as CFData,
                                    signatureData as CFData,
                                    &error)
        else {
                                        return nil
        }
        return signature
    }

    func write(to fileURL: URL) throws {
        let json: [String: Any] = ["payload": self.payload, "signature": self.signature]
        let data = try JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
        try data.write(to: fileURL)
    }

    static func publicKey() -> String {
        #if TEST
        if let key = TEST_OVERRIDES.publicKey {
            return key
        }
        #endif

        #if DEBUG
        return APIDebugManager.shared.activeConfig.publicKey
        #else
        return Config.production.publicKey
        #endif
    }
}
