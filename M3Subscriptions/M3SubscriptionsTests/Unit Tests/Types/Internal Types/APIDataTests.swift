//
//  APIDataTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

class APIDataTests: APITestCase {
    func test_init_returnsNilIfJSONContainsNoPayloadKey() throws {
        let json = [
            "signature": "",
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONPayloadIsNotDictionary() throws {
        let json: [String: Any] = [
            "payload": [1, 2, 3],
            "signature": "",
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfPayloadDoesntContainResponse() throws {
        let json: [String: Any] = [
            "payload": ["foo": "bar"],
            "signature": "",
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfPayloadResponseIsNotString() throws {
        let json: [String: Any] = [
            "payload": ["response": 42],
            "signature": "",
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONContainsNoSignatureKey() throws {
        let json: [String: Any] = [
            "payload": ["response": "foo"],
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONSignatureIsNotString() throws {
        let json: [String: Any] = [
            "payload": ["response": "bar"],
            "signature": 42,
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfJSONPayloadIsNotValidJSON() throws {
        let json: [String: Any] = [
            "payload": ["response": "bar", "foo": NSObject()],
            "signature": 42,
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfSignatureIsNotBase64EncodedString() throws {
        let json: [String: Any] = [
            "payload": ["response": "baz", "foo": "bar", "baz": 42, "test": ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2]],
            "signature": "•",
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsNilIfSignatureIsInvalidForPayload() throws {
        let payload: [String: Any] = ["response": "possum", "foo": "bar", "baz": 42, "test": ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2]]
        let json: [String: Any] = [
            "payload": payload,
            "signature": "ePeowEl5P6DtRgEdyeTuvKUPjfZunI2cjZ1cTIAqTOCJ7B6KWU3Pek9cTHe2UTjAZUbw6N5p4arFDXVnBkIi5MUvXG3tcCWxE0Kvd1NnirPTFwQNMsDrhlWNi+7eAjNHvMNXQB1Aqgq5BkqaJvXcyOpALrkgXby2OsC8381063ZJrVvmtjIv9Lls/d91fv6dtV3kCsVTVl+LwPWhNX2R/0gstiyVt4aFizIj9Gd6iN0KrWbd47T8y4wYtfls6+YdmhndwqQ61ZLgMFiaH/GixfdJEFMsN3IsmsNGousGK+Zll5S7VfJe0uYepb2P36XcgyAjiUgbTo8p9w5hHX0wSQ==",
        ]
        XCTAssertNil(APIData(json: json))
    }

    func test_init_returnsInitialisedDataWithPayloadResponseAndSignatureIfSignatureIsValid() throws {
        let payload: [String: Any] = ["response": "possum", "foo": "bar", "baz": 42, "test": ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2]]
        let signature = try self.signature(forPayload: payload)
        let json: [String: Any] = [
            "payload": payload,
            "signature": signature,
        ]
        let data = try XCTUnwrap(APIData(json: json))
        XCTAssertEqual(data.payload["foo"] as? String, "bar")
        XCTAssertEqual(data.payload["baz"] as? Int, 42)
        XCTAssertEqual(data.payload["test"] as? [String: Int], ["c": 3, "p": 0, "bb": 8, "r": 2, "d": 2])
        XCTAssertEqual(data.signature, signature)
        XCTAssertEqual(data.response, .other("possum"))
    }


    //MARK: - response(from:)
    func test_responseFromString_parsesActive() throws {
        XCTAssertEqual(APIData.Response.response(from: "active"), .active)
    }

    func test_responseFromString_parsesDeactivated() throws {
        XCTAssertEqual(APIData.Response.response(from: "deactivated"), .deactivated)
    }

    func test_responseFromString_parsesLoginFailed() throws {
        XCTAssertEqual(APIData.Response.response(from: "login_failed"), .loginFailed)
    }

    func test_responseFromString_parsesMultipleSubscriptions() throws {
        XCTAssertEqual(APIData.Response.response(from: "multiple_subscriptions"), .multipleSubscriptions)
    }

    func test_responseFromString_parsesNoSubscriptionFound() throws {
        XCTAssertEqual(APIData.Response.response(from: "no_subscription_found"), .noSubscriptionFound)
    }

    func test_responseFromString_parsesNoDeviceFound() throws {
        XCTAssertEqual(APIData.Response.response(from: "no_device_found"), .noDeviceFound)
    }

    func test_responseFromString_parsesTooManyDevices() throws {
        XCTAssertEqual(APIData.Response.response(from: "too_many_devices"), .tooManyDevices)
    }

    func test_responseFromString_parsesSubscriptionExpired() throws {
        XCTAssertEqual(APIData.Response.response(from: "subscription_expired"), .expired)
    }

    func test_responseFromString_parsesAnotherStringAsOther() throws {
        XCTAssertEqual(APIData.Response.response(from: "foobarbaz"), .other("foobarbaz"))
    }
}
