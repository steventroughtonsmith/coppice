//
//  APIDataTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class APIDataTests: XCTestCase {

    func test_init_returnsNilIfJSONContainsNoPayloadKey() throws {
        let json = [
            "signature": ""
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONPayloadIsNotDictionary() throws {
        let json: [String: Any] = [
            "payload": [1, 2, 3],
            "signature": ""
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONContainsNoSignatureKey() throws {
        let json: [String: Any] = [
            "payload": ["foo": "bar"]
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONSignatureIsNotString() throws {
        let json: [String: Any] = [
            "payload": ["foo": "bar"],
            "signature": 42
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONPayloadIsNotValidJSON() throws {
        let json: [String: Any] = [
            "payload": ["foo": NSObject()],
            "signature": 42
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfSignatureIsNotBase64EncodedString() throws {
        let json: [String: Any] = [
            "payload": ["foo": "bar", "baz": 42, "test": ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2]],
            "signature": "•"
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfSignatureIsInvalidForPayload() throws {
        let payload: [String: Any] = ["foo": "bar", "baz": 42, "test": ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2]]
        let json: [String: Any] = [
            "payload": payload,
            "signature": "ePeowEl5P6DtRgEdyeTuvKUPjfZunI2cjZ1cTIAqTOCJ7B6KWU3Pek9cTHe2UTjAZUbw6N5p4arFDXVnBkIi5MUvXG3tcCWxE0Kvd1NnirPTFwQNMsDrhlWNi+7eAjNHvMNXQB1Aqgq5BkqaJvXcyOpALrkgXby2OsC8381063ZJrVvmtjIv9Lls/d91fv6dtV3kCsVTVl+LwPWhNX2R/0gstiyVt4aFizIj9Gd6iN0KrWbd47T8y4wYtfls6+YdmhndwqQ61ZLgMFiaH/GixfdJEFMsN3IsmsNGousGK+Zll5S7VfJe0uYepb2P36XcgyAjiUgbTo8p9w5hHX0wSQ=="
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsInitialisedDataWithPayloadAndSignatureIfSignatureIsValid() throws {
        let payload: [String: Any] = ["foo": "bar", "baz": 42, "test": ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2]]
        let signature = "IGRpP5E0JA1d2ty3rd8YFyPoaxrbK39IvwNo+s4UgkE1Us1wAFe4wejg8QedcN9PclzwstozvJb0B0ouCqRgmz8FSV8/xFcHVIaLzyrvjqwYy5quTQPmN2Za82sgl/XNyvTcjMBcKPXn7hSp4E5X/ce71HSUBWH7yuhSdsOXBLrhuvB0jcfQkKQnAXT/RMrInjdVc0bSEEFIt2ZQaWseciBTwD8WJsaPEGLaXqftIAPMrbYcBAGj+ImA0/exts0mRjGoOEP92EobnBPLsKlBrOo0zEzoySokFwGj1xYDktfB/OWJmznNU/s0Hu2bdjNzdX7U/JYWlley9XktEj1eoQ=="
        let json: [String: Any] = [
            "payload": payload,
            "signature": signature
        ]
        let data = try XCTUnwrap(APIData(json: json))
        XCTAssertEqual(data.payload["foo"] as? String, "bar")
        XCTAssertEqual(data.payload["baz"] as? Int, 42)
        XCTAssertEqual(data.payload["test"] as? [String: Int], ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2])
    }

}
