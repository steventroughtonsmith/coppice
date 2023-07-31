//
//  LicenceTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 30/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

typealias Licence = API.V2.Licence

final class LicenceTests: APITestCase {
    //init(url:) – Files
    func test_init_succeedsIfPassedFileURLToValidLicence() throws {
        let licencePayload: [String: Any] = [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ]

        let data = try JSONSerialization.data(withJSONObject: [
            "payload": licencePayload,
            "signature": try Self.signature(forPayload: licencePayload),
        ])

        let licenceURL = try self.temporaryTestDirectory().appendingPathComponent("test.coppicelicence")
        try data.write(to: licenceURL)


        let licence = try Licence(url: licenceURL)

        XCTAssertEqual(licence.licenceID, "1234567890")
        XCTAssertEqual(licence.subscription.id, "abcdefghijklm")
        XCTAssertEqual(licence.subscription.name, "Annual Subscription")
        XCTAssertEqual(licence.subscription.expirationTimestamp, 876_543_210)
        XCTAssertEqual(licence.subscriber, "Pilky")
    }

    //init(url:) – URLs
    func test_init_throwsInvalidLicenceIfURLHostIsNotActivate() throws {
        self.runFailingLicenceURLTest(url: URL(string: "coppice://page")!)
    }

    func test_init_throwsInvalidLicenceIfURLQueryDoesntContainLicenceItem() throws {
        self.runFailingLicenceURLTest(url: URL(string: "coppice://activate?foo=bar")!)
    }

    func test_init_succeedsIfPassedLicenceURL() throws {
        let licencePayload: [String: Any] = [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ]

        let data = try JSONSerialization.data(withJSONObject: [
            "payload": licencePayload,
            "signature": try Self.signature(forPayload: licencePayload),
        ])

        let licenceString = data.base64EncodedString()

        let licence = try Licence(url: URL(string: "coppice://activate?licence=\(licenceString)")!)
        XCTAssertEqual(licence.licenceID, "1234567890")
        XCTAssertEqual(licence.subscription.id, "abcdefghijklm")
        XCTAssertEqual(licence.subscription.name, "Annual Subscription")
        XCTAssertEqual(licence.subscription.expirationTimestamp, 876_543_210)
        XCTAssertEqual(licence.subscriber, "Pilky")
    }

    //init(url:)
    func test_init_throwsInvalidLicenceIfInvalidURLPassedIn() throws {
        self.runFailingLicenceURLTest(url: URL(string: "https://mcubedsw.com")!)
    }

    func test_init_throwsInvalidLicenceIfPayloadMissing() throws {
        let licencePayload: [String: Any] = [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ]

        let data = try JSONSerialization.data(withJSONObject: [
            "signature": try Self.signature(forPayload: licencePayload),
        ])

        let licenceString = data.base64EncodedString()

        self.runFailingLicenceURLTest(url: URL(string: "coppice://activate?licence=\(licenceString)")!)
    }

    func test_init_throwsInvalidLicenceIfSignatureMissing() throws {
        let licencePayload: [String: Any] = [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ]

        let data = try JSONSerialization.data(withJSONObject: [
            "payload": licencePayload,
        ])

        let licenceString = data.base64EncodedString()

        self.runFailingLicenceURLTest(url: URL(string: "coppice://activate?licence=\(licenceString)")!)
    }

    func test_init_throwsInvalidLicenceIfLicenceIDMissing() throws {
        try self.runMissingPayloadLicenceURLTest(payload: [
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ])
    }

    func test_init_throwsInvalidLicenceIfSubscriberMissing() throws {
        try self.runMissingPayloadLicenceURLTest(payload: [
            "licenceID": "1234567890",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ])
    }

    func test_init_throwsInvalidLicenceIfSubscriptionIDMissing() throws {
        try self.runMissingPayloadLicenceURLTest(payload: [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ])
    }

    func test_init_throwsInvalidLicenceIfSubscriptionNameMissing() throws {
        try self.runMissingPayloadLicenceURLTest(payload: [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "expirationTimestamp": 876_543_210,
        ])
    }

    func test_init_throwsInvalidLicenceIfExpirationTimestampMissing() throws {
        try self.runMissingPayloadLicenceURLTest(payload: [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
        ])
    }

    //MARK: - write(to:)
    func test_writeToFile_writesDataToFile() throws {
        let licencePayload: [String: Any] = [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ]

        let data = try JSONSerialization.data(withJSONObject: [
            "payload": licencePayload,
            "signature": try Self.signature(forPayload: licencePayload),
        ])

        let licenceString = data.base64EncodedString()
        let licence = try Licence(url: URL(string: "coppice://activate?licence=\(licenceString)")!)

        let licenceURL = try self.temporaryTestDirectory().appendingPathComponent("test.coppicelicence")
        try licence.write(to: licenceURL)

        XCTAssertTrue(FileManager.default.fileExists(atPath: licenceURL.path))
    }

    func test_writeToFile_writtenFileLoadsBackIntoLicence() throws {
        let licencePayload: [String: Any] = [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ]

        let data = try JSONSerialization.data(withJSONObject: [
            "payload": licencePayload,
            "signature": try Self.signature(forPayload: licencePayload),
        ])

        let licenceString = data.base64EncodedString()
        let licence = try Licence(url: URL(string: "coppice://activate?licence=\(licenceString)")!)

        let licenceURL = try self.temporaryTestDirectory().appendingPathComponent("test.coppicelicence")
        try licence.write(to: licenceURL)

        let reloadedLicence = try Licence(url: licenceURL)

        XCTAssertEqual(reloadedLicence.licenceID, "1234567890")
        XCTAssertEqual(reloadedLicence.subscription.id, "abcdefghijklm")
        XCTAssertEqual(reloadedLicence.subscription.name, "Annual Subscription")
        XCTAssertEqual(reloadedLicence.subscription.expirationTimestamp, 876_543_210)
        XCTAssertEqual(reloadedLicence.subscriber, "Pilky")
    }

    //MARK: - Helper
    private func runMissingPayloadLicenceURLTest(payload: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "payload": payload,
            "signature": try Self.signature(forPayload: payload),
        ])

        let licenceString = data.base64EncodedString()
        let url = URL(string: "coppice://activate?licence=\(licenceString)")!

        self.runFailingLicenceURLTest(url: url)
    }

    private func runFailingLicenceURLTest(url: URL) {
        XCTAssertThrowsError(try Licence(url: url)) { error in
            guard
                let apiError = error as? API.V2.Error,
                case .invalidLicence = apiError
            else {
                XCTFail("\(error) is not .invalidLicence")
                return
            }
        }
    }
}
