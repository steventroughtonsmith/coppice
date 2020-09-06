//
//  APIData.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
import CommonCrypto

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
            return .other(string)
        }
    }

    //TODO: Need to expose reponse at the top level and return nil if no response found in payload
    var payload: [String: Any]
    var signature: String
    var response: Response

    init?(json: [String: Any]) {
        guard let payload = json["payload"] as? [String: Any],
            let response = payload["response"] as? String,
            let signature = json["signature"] as? String else {
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
                                      kSecAttrKeySizeInBits as String : 2048]
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
                                    &error) else {
                                        return nil
        }
        return signature
    }

    static func publicKey() -> String {
        #if TEST
        if let key = TEST_OVERRIDES.publicKey {
            return key
        }
        #endif
        return """
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAqZdbp6XV0sxInPFl7K5O
9aGRQkjdmspuV7bbDplLzznueAHJP25zbsiGKKKsTypKa5Zf5vJtMGNhe6D/kKiO
JkkCiTJJ8KgzP1DaJeXMCCrXmG+iivIPgXv6XJuO55+iVVI9RCOp247Z0oXjOBl6
m/PU7irVPng9wCWDELsgI8nKUZM/+RKc1PJ3bb3MW2GbDMxAWPnGRvvjx/Y9M+hW
VaYLykTPu5f6islSJKllN7XVfBgWMxt8+RNnYoVcoRGbtlRvZ0LOyjMHzwoU6NDM
0QnIJeuNvirS1wlIrdfhNLkfa6nIWsePa4aaXBPRuMx1To/gi57TTMMIqGPSsp5y
BQIDAQAB
"""
    }
}
