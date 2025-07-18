//
//  APITestCase.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 31/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CommonCrypto
@testable import M3Subscriptions
import XCTest

class APITestCase: XCTestCase {
    enum SigningError: Error {
        case signingError
    }

    func temporaryTestDirectory(createIfNeeded: Bool = true) throws -> URL {
        let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("M3Subscription-Tests")
        if createIfNeeded, FileManager.default.fileExists(atPath: url.path) == false {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        //set public key
        guard let publicKeyURL = self.testBundle.url(forResource: "test_public_key", withExtension: "pem") else {
            XCTFail("Could not find public key in bundle")
            return
        }
        let key = try String(contentsOf: publicKeyURL)
        #if TEST
        TEST_OVERRIDES.publicKey = key
        #endif
    }

    override func tearDownWithError() throws {
        #if TEST
        TEST_OVERRIDES.publicKey = nil
        #endif
        let testDirectoryPath = try self.temporaryTestDirectory(createIfNeeded: false)
        if FileManager.default.fileExists(atPath: testDirectoryPath.path) {
            try FileManager.default.removeItem(at: testDirectoryPath)
        }
        try super.tearDownWithError()
    }

    static func signature(forPayload payload: [String: Any]) throws -> String {
        let privateKeyURL = try XCTUnwrap(Self.testBundle.url(forResource: "test_private_key", withExtension: "p12"))
        let p12Data = try Data(contentsOf: privateKeyURL)


        let payloadData = try JSONSerialization.data(withJSONObject: payload, options: .sortedKeys)
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        payloadData.withUnsafeBytes {
            _ = CC_SHA256($0.baseAddress, CC_LONG(payloadData.count), &hash)
        }

        let hashedPayload = Data(hash)

        //See https://stackoverflow.com/questions/10579985/how-can-i-get-seckeyref-from-der-pem-file
        let options: [String: Any] = [kSecImportExportPassphrase as String: "password"]
        var error: Unmanaged<CFError>?
        var itemsArray: CFArray? = [Any]() as CFArray
        var privateKey: SecKey?
        let importResult = SecPKCS12Import(p12Data as CFData, options as CFDictionary, &itemsArray)
        guard
            importResult == noErr,
            let items = itemsArray,
            (items as NSArray).count > 0,
            let identityDict = (items as NSArray).firstObject as? NSDictionary,
            let identity = identityDict.object(forKey: kSecImportItemIdentity),
            SecIdentityCopyPrivateKey(identity as! SecIdentity, &privateKey) == noErr,
            let key = privateKey
        else {
            if let error = error {
                print("error: \(error)")
            }
            throw SigningError.signingError
        }

        guard SecKeyIsAlgorithmSupported(key, .sign, .rsaSignatureDigestPKCS1v15SHA256) else {
            throw SigningError.signingError
        }

        guard let signature = SecKeyCreateSignature(key, .rsaSignatureDigestPKCS1v15SHA256, hashedPayload as CFData, &error) else {
            if let error = error {
                print("error: \(error)")
            }
            throw SigningError.signingError
        }
        return (signature as Data).base64EncodedString()
    }
}
