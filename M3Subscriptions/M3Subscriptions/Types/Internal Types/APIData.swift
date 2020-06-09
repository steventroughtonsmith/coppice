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
    var payload: [String: Any]
    var signature: String

    init?(json: [String: Any]) {
        guard let payload = json["payload"] as? [String: Any],
            let signature = json["signature"] as? String else {
                return nil
        }

        guard APIData.verify(payload: payload, signature: signature) == signature else {
            return nil
        }

        self.payload = payload
        self.signature = signature
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

        let publicKey = """
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA3Ya6Fwp1ZawfJEs+iPL5
UUthay1URdcIEw0Kah0sO7lIYFKqcE5/XbWfoIWqEQanWzBpQhhv84nguWLv8DMs
2Rv+6OqH4qXElSxmGvZQFIT15sjifdI2dGblm6GADVJXh0AMcpWeB01FGtNKbaRV
EgtQpS5ukDyFBJ+OBA/39fXRzb2pH0JD3dIveNwyXyjc1jVvAJGku+lVKpIS1GeP
79ULXqfOfFPcmRzforPi2NUTzAwIR+BFLEcXNuF5N5MqQ6Fkv8Uct7jFSyYZvNn3
ngBORNS9QFDuvvBfxv1KOPly7FjcM7lR+trpiNfq2Gok3kIcXMHs+loVLaabEEtU
owIDAQAB
"""
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
}
