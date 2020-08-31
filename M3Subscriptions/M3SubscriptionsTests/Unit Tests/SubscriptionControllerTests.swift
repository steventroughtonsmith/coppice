//
//  SubscriptionController.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 11/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class SubscriptionControllerTests: APITestCase {
    var licenceURL: URL!
    var mockAPI: MockSubscriptionAPI!
    var controller: SubscriptionController!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.licenceURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.mcubedsw.subscriptions").appendingPathComponent("licence.txt")
        try FileManager.default.createDirectory(at: self.licenceURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        self.mockAPI = MockSubscriptionAPI()
        self.controller = SubscriptionController(licenceURL: self.licenceURL, subscriptionAPI: self.mockAPI)
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        if FileManager.default.fileExists(atPath: self.licenceURL.path) {
            try FileManager.default.removeItem(at: self.licenceURL)
        }
    }

    //MARK: - Helpers
    func writeLicence(_ json: [String: Any]) throws {
        let data = try JSONSerialization.data(withJSONObject: json, options: [])
        try data.write(to: self.licenceURL)
    }

    func readLicence() throws -> [String: Any]? {
        let data = try Data(contentsOf: self.licenceURL)
        return (try JSONSerialization.jsonObject(with: data, options: [])) as? [String: Any]
    }



    //MARK: - activate(withEmail:password:subscription:deactivatingDevice:)
    func test_activate_tellsSubscriptionAPIToActivateWithRequestAndDevice() throws {
        self.controller.activate(withEmail: "foo@bar.com", password: "123456") {_ in }

        XCTAssertEqual(self.mockAPI.calledMethod, "activate")
        let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)
        let actualDevice = try XCTUnwrap(self.mockAPI.deviceArgument)

        XCTAssertEqual(actualRequest.email, "foo@bar.com")
        XCTAssertEqual(actualRequest.password, "123456")

		let device = Device()
        XCTAssertEqual(actualDevice.id, device.id)
        XCTAssertEqual(actualDevice.name, Host.current().localizedName)
    }

    func test_activate_tellsSubscriptionAPIToActivateWithSubscriptionPlanIfSupplied() throws {
        let plan = try XCTUnwrap(Subscription(payload: ["id": "foobar", "name": "Plan 3", "maxDeviceCount": 3, "currentDeviceCount": 2, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: false))
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef", subscription: plan)  {_ in }

        XCTAssertEqual(self.mockAPI.calledMethod, "activate")
        let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)

        XCTAssertEqual(actualRequest.email, "baz@possum.com")
        XCTAssertEqual(actualRequest.password, "abcdef")
        XCTAssertEqual(actualRequest.subscriptionID, "foobar")
    }

    func test_activate_tellsSubscriptionAPIToActivateWhileDeactivatingDeviceIfSupplied() throws {
        let device = try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "deleteimac", "name": "My iMac", "activationDate": "2035-01-01T00:00:00Z"]))
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef", deactivatingDevice: device)  {_ in }

        XCTAssertEqual(self.mockAPI.calledMethod, "activate")
        let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)

        XCTAssertEqual(actualRequest.email, "baz@possum.com")
        XCTAssertEqual(actualRequest.password, "abcdef")
        XCTAssertEqual(actualRequest.deviceDeactivationToken, "deleteimac")
    }

    func test_activate_returnsServerConnectionErrorIfConnectionFailed() throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.activateResponse = .failure(.generic(expectedError))

        let expectation = self.expectation(description: "Activate Completed")
        var actualError: NSError? = nil
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.couldNotConnectToServer.rawValue)
        XCTAssertEqual(actualError?.userInfo[NSUnderlyingErrorKey] as? NSError, expectedError)
    }

    func test_activate_returnsLoginFailedError() throws {
        self.mockAPI.activateResponse = .failure(.loginFailed)

        let expectation = self.expectation(description: "Activate Completed")
        var actualError: NSError? = nil
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.loginFailed.rawValue)
    }

//    func test_activate_returnsSubscriptionExpirationError() throws {
//        let expectedSubscription = try XCTUnwrap(Subscription(payload: ["subscriptionName": "Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "cancelled"], hasExpired: true))
//        self.mockAPI.activateResponse = .failure(.subscriptionExpired(expectedSubscription))
//
//        let expectation = self.expectation(description: "Activate Completed")
//        var actualError: NSError? = nil
//        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
//            if case .failure(let error) = result {
//                actualError = error
//            }
//            expectation.fulfill()
//        }
//        self.waitForExpectations(timeout: 1)
//
//        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
//        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.subscriptionExpired.rawValue)
//        XCTAssertEqual(actualError?.userInfo[SubscriptionErrorFactory.InfoKeys.subscription] as? Subscription, expectedSubscription)
//        XCTFail()
//    }

    func test_activate_returnsNoSubscriptionFoundError() throws {
        self.mockAPI.activateResponse = .failure(.noSubscriptionFound)

        let expectation = self.expectation(description: "Activate Completed")
        var actualError: NSError? = nil
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_activate_returnsMultipleSubscriptionsErrorWithSubscriptionPlans() throws {
        let plans = [
            try XCTUnwrap(Subscription(payload: ["id": "plan1", "name": "Plan A", "expirationDate":"2034-02-05T00:00:00Z", "maxDeviceCount": 5, "currentDeviceCount": 3, "renewalStatus": "renew"], hasExpired: false)),
            try XCTUnwrap(Subscription(payload: ["id": "foobar", "name": "Plan 3", "maxDeviceCount": 3, "currentDeviceCount": 2, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: false))
        ]

        self.mockAPI.activateResponse = .failure(.multipleSubscriptions(plans))

        let expectation = self.expectation(description: "Activate Completed")
        var actualError: NSError? = nil
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.multipleSubscriptionsFound.rawValue)
        XCTAssertEqual(actualError?.userInfo[SubscriptionErrorFactory.InfoKeys.subscriptionPlans] as? [Subscription], plans)
    }

    func test_activate_returnsTooManyDevicesErrorWithDevices() throws {
        let devices = [
            try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "deleteimac", "name": "My iMac", "activationDate": "2035-01-01T00:00:00Z"])),
            try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "macpro", "name": "A Mac Pro", "activationDate": "2031-09-21T00:16:00Z"]))
        ]

        self.mockAPI.activateResponse = .failure(.tooManyDevices(devices))

        let expectation = self.expectation(description: "Activate Completed")
        var actualError: NSError? = nil
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.tooManyDevices.rawValue)
        XCTAssertEqual(actualError?.userInfo[SubscriptionErrorFactory.InfoKeys.devices] as? [SubscriptionDevice], devices)
    }

    private func run_activate_successfullyActivatedTest(with renewalStatus: Subscription.RenewalStatus) throws {
        let payload: [String: Any] = [
            "response": "active",
            "token": "updated-token",
            "subscription": ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": renewalStatus.rawValue],
            "device": ["name": "My iMac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        let expectedSubscription = try XCTUnwrap(Subscription(payload: ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": renewalStatus.rawValue], hasExpired: false))

        let expectation = self.expectation(description: "Activate Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertEqual(response.token, "updated-token")
        XCTAssertEqual(response.subscription, expectedSubscription)
    }

    func test_activate_returnsActiveResponseIfSuccessfullyActivated() throws {
        try self.run_activate_successfullyActivatedTest(with: .renew)
    }

    func test_activate_returnsActiveResponseIfSuccessfullyActivatedWithFailedRenewStatus() throws {
        try self.run_activate_successfullyActivatedTest(with: .failed)
    }

    func test_activate_returnsActiveResponseIfSuccessfullyActivatedWithCancelledRenewStatus() throws {
        try self.run_activate_successfullyActivatedTest(with: .cancelled)
    }

    func test_activate_storesSuccessfulActivationToDiskIfActive() throws {
        let payload: [String: Any] = [
            "response": "active",
            "token": "updated-token",
            "subscription": ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        let expectation = self.expectation(description: "Activate Completed")
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let json = try XCTUnwrap(try self.readLicence())
        let actualPayload = try XCTUnwrap(json["payload"] as? [String: Any])
        XCTAssertEqual(actualPayload["response"] as? String, "active")
        XCTAssertEqual(actualPayload["token"] as? String, "updated-token")
        XCTAssertEqual(actualPayload["subscription"] as? [String: String], ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": "renew"])
        XCTAssertEqual(actualPayload["device"] as? [String: String], ["name": "My iMac"])

        XCTAssertEqual(json["signature"] as? String, signature)
    }

//    func test_activate_setsTimerToFireInAnHour() throws {
//        let payload: [String: Any] = ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]
//        let signature = try self.signature(forPayload: payload)
//        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
//        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
//        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
//        self.mockAPI.activateResponse = .success(expectedResponse)
//
//        let expectation = self.expectation(description: "Activate Completed")
//        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")  { result in
//            expectation.fulfill()
//        }
//        self.waitForExpectations(timeout: 1)
//
//        let timer = try XCTUnwrap(self.controller.recheckTimer)
//        let difference = timer.fireDate.timeIntervalSince(Date())
//        XCTAssertGreaterThan(difference, 3600 - 1)
//        XCTAssertLessThan(difference, 3600 + 1)
//    }
//
//    func test_activate_setsLastCheckDate() throws {
//        let payload: [String: Any] = ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]
//        let signature = try self.signature(forPayload: payload)
//        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
//        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
//        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
//        self.mockAPI.activateResponse = .success(expectedResponse)
//
//        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")
//
//        let lastCheck = try XCTUnwrap(self.controller.lastCheck)
//        let difference = lastCheck.timeIntervalSince(Date())
//        XCTAssertGreaterThan(difference, -1)
//        XCTAssertLessThan(difference, 1)
//    }
//
//    func test_activate_callsCheckSubscriptionAgainIfTimerFiresAfterLastCheckDatePlus24Hours() throws {
//        let payload: [String: Any] = ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]
//        let signature = try self.signature(forPayload: payload)
//        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
//        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
//        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
//        self.mockAPI.activateResponse = .success(expectedResponse)
//
//        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")
//
//        self.mockAPI.reset()
//        let timer = try XCTUnwrap(self.controller.recheckTimer)
//
//        XCTAssertNil(self.mockAPI.calledMethod)
//        self.controller.setLastCheck(Date(timeIntervalSinceNow: -86401))
//        timer.fire()
//
//        XCTAssertEqual(self.mockAPI.calledMethod, "check")
//    }


    //MARK: - checkSubscription(updatingDeviceName:)
    func test_checkSubscription_tellsSubscriptionAPIToCheckWithTokenAndDevice() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let expectation = self.expectation(description: "Check Completed")
        self.controller.checkSubscription()  { result in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(self.mockAPI.calledMethod, "check")

        let device = Device()
        let actualDevice = try XCTUnwrap(self.mockAPI.deviceArgument)
        let actualToken = try XCTUnwrap(self.mockAPI.tokenArgument)
        XCTAssertEqual(actualDevice.id, device.id)
        XCTAssertEqual(actualDevice.appVersion, device.appVersion)
        XCTAssertEqual(actualToken, "abctoken123")
        XCTAssertNil(actualDevice.name)
    }

    func test_checkSubscription_tellsSubscriptionAPIToCheckWithDeviceNameIfSupplied() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let expectation = self.expectation(description: "Check Completed")
        self.controller.checkSubscription(updatingDeviceName: "Foo Bar Baz")  { result in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let actualDevice = try XCTUnwrap(self.mockAPI.deviceArgument)
        XCTAssertEqual(actualDevice.name, "Foo Bar Baz")
    }

    func test_checkSubscription_returnsNotActivatedErrorIfAPICallFailedAndNoLocalLicence() throws {
        let expectedError = NSError(domain: "test domain", code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))

        let expectation = self.expectation(description: "Check Completed")
        var actualError: NSError? = nil
        self.controller.checkSubscription()  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.notActivated.rawValue)
    }

    func test_checkSubscription_returnsServerConnectionErrorIfAPICallFailedAndLocalLicenceIsInvalid() throws {
        var storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        storedPayload["token"] = "invalid-token"
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))

        let expectation = self.expectation(description: "Check Completed")
        var actualError: NSError? = nil
        self.controller.checkSubscription()  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.notActivated.rawValue)
    }

    func test_checkSubscription_returnsActivationResponseWithExpiredSubscriptionIfAPICallFailedAndLocalLicenceIsValidButBeyondExpirationDate() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2015-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate": "2015-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: true)

        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))

        let expectation = self.expectation(description: "Check Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.checkSubscription()  { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertFalse(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertEqual(response.token, "abctoken123")
        XCTAssertEqual(response.deviceName, "My iMac")
        XCTAssertEqual(response.subscription, expectedSubscription)
    }

    func test_checkSubscription_returnsActivationResponseIfAPICallFailedAndLocalLicenceIsValid() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
        let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: false)
        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))

        let expectation = self.expectation(description: "Check Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.checkSubscription()  { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertEqual(response.token, "abctoken123")
        XCTAssertEqual(response.deviceName, "My iMac")
        XCTAssertEqual(response.subscription, expectedSubscription)
    }

    func test_checkSubscription_returnsNoDeviceFoundError() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
        self.mockAPI.checkResponse = .failure(.noDeviceFound)

        let expectation = self.expectation(description: "Check Completed")
        var actualError: NSError? = nil
        self.controller.checkSubscription()  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_checkSubscription_returnsNoSubscriptionFoundError() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
        self.mockAPI.checkResponse = .failure(.noSubscriptionFound)

        let expectation = self.expectation(description: "Check Completed")
        var actualError: NSError? = nil
        self.controller.checkSubscription()  { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_checkSubscription_returnsActivationResponseWithExpiredSubscription() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let payload: [String: Any] = [
            "response": "subscription_expired",
            "token": "updated-token",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
        let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: true)

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)

        let expectation = self.expectation(description: "Check Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.checkSubscription()  { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertFalse(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertEqual(response.token, "updated-token")
        XCTAssertEqual(response.subscription, expectedSubscription)
    }

    private func run_checkSubscription_returnsActiveResponseIfStillActivated(with renewalStatus: Subscription.RenewalStatus) throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": renewalStatus.rawValue],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let payload: [String: Any] = [
            "response": "active",
            "token": "updated-token",
            "subscription": ["name":"Plan B", "expirationDate":"2036-01-01T01:01:01Z", "renewalStatus": renewalStatus.rawValue],
            "device": ["name": "My iMac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
        let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": renewalStatus.rawValue], hasExpired: false)

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)

        let expectation = self.expectation(description: "Check Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.checkSubscription()  { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertEqual(response.token, "updated-token")
        XCTAssertEqual(response.subscription, expectedSubscription)
    }

    func test_checkSubscription_returnsActivationResponseIfStillActivated() throws {
        try self.run_checkSubscription_returnsActiveResponseIfStillActivated(with: .renew)
    }

    func test_checkSubscription_returnsActivationResponseIfSuccessfullyActivatedWithFailedRenewalStatus() throws {
        try self.run_checkSubscription_returnsActiveResponseIfStillActivated(with: .failed)
    }

    func test_checkSubscription_returnsActivationResponseIfSuccessfullyActivatedWithCancelledRenewalStatus() throws {
        try self.run_checkSubscription_returnsActiveResponseIfStillActivated(with: .cancelled)
    }

    func test_checkSubscription_storesSuccessfulActivationToDiskIfActive() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let payload: [String: Any] = [
            "response": "active",
            "token": "updated-token",
            "subscription": ["name":"Plan B", "expirationDate":"2036-01-01T01:01:01Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)

        let expectation = self.expectation(description: "Check Completed")
        self.controller.checkSubscription()  { result in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let actualJSON = try XCTUnwrap(try self.readLicence())

        let actualPayload = try XCTUnwrap(actualJSON["payload"] as? [String: Any])
        XCTAssertEqual(actualPayload["response"] as? String, "active")
        XCTAssertEqual(actualPayload["token"] as? String, "updated-token")
        XCTAssertEqual(actualPayload["subscription"] as? [String: String], ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": "renew"])
        XCTAssertEqual(actualPayload["device"] as? [String: String], ["name": "My iMac"])

        XCTAssertEqual(actualJSON["signature"] as? String, signature)
    }

    func test_checkSubscription_storesActivationToDiskIfExpired() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let payload: [String: Any] = [
            "response": "subscription_expired",
            "token": "updated-token",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "cancelled"],
            "device": ["name": "My iMac"],
        ]
        let signature = try self.signature(forPayload: payload)
        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)

        let expectation = self.expectation(description: "Check Completed")
        self.controller.checkSubscription()  { result in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let actualJSON = try XCTUnwrap(try self.readLicence())

        let actualPayload = try XCTUnwrap(actualJSON["payload"] as? [String: Any])
        XCTAssertEqual(actualPayload["response"] as? String, "subscription_expired")
        XCTAssertEqual(actualPayload["token"] as? String, "updated-token")
        XCTAssertEqual(actualPayload["subscription"] as? [String: String], ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "cancelled"])
        XCTAssertEqual(actualPayload["device"] as? [String: String], ["name": "My iMac"])

        XCTAssertEqual(actualJSON["signature"] as? String, signature)
    }

//    func test_checkSubscription_setsTimerToFireInAnHour() throws {
//        let payload: [String: Any] = ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"]
//        let signature = try self.signature(forPayload: payload)
//        try self.writeLicence(["payload": payload, "signature": signature])
//
//        let payload: [String: Any] = ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]
//        let signature = try self.signature(forPayload: payload)
//        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
//
//        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
//        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
//        self.mockAPI.checkResponse = .success(expectedResponse)
//        self.controller.checkSubscription()
//
//        let timer = try XCTUnwrap(self.controller.recheckTimer)
//        let difference = timer.fireDate.timeIntervalSince(Date())
//        XCTAssertGreaterThan(difference, 3600 - 1)
//        XCTAssertLessThan(difference, 3600 + 1)
//    }
//
//    func test_checkSubscription_setsLastCheckDate() throws {
//        let payload: [String: Any] = ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"]
//        let signature = try self.signature(forPayload: payload)
//        try self.writeLicence(["payload": payload, "signature": signature])
//
//        let payload: [String: Any] = ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]
//        let signature = try self.signature(forPayload: payload)
//        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
//
//        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
//        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
//        self.mockAPI.checkResponse = .success(expectedResponse)
//        self.controller.checkSubscription()
//
//        let lastCheck = try XCTUnwrap(self.controller.lastCheck)
//        let difference = lastCheck.timeIntervalSince(Date())
//        XCTAssertGreaterThan(difference, -1)
//        XCTAssertLessThan(difference, 1)
//    }
//
//    func test_checkSubscription_callsCheckSubscriptionAgainIfTimerFiresAfterLastCheckDatePlus24Hours() throws {
//        let payload: [String: Any] = ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"]
//        let signature = try self.signature(forPayload: payload)
//        try self.writeLicence(["payload": payload, "signature": signature])
//
//        let payload: [String: Any] = ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]
//        let signature = try self.signature(forPayload: payload)
//        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
//
//        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
//        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
//        self.mockAPI.checkResponse = .success(expectedResponse)
//        self.controller.checkSubscription()
//
//        self.mockAPI.reset()
//        let timer = try XCTUnwrap(self.controller.recheckTimer)
//
//        XCTAssertNil(self.mockAPI.calledMethod)
//        self.controller.setLastCheck(Date(timeIntervalSinceNow: -86401))
//        timer.fire()
//
//        XCTAssertEqual(self.mockAPI.calledMethod, "check")
//    }


    //MARK: - deactivate()
    func test_deactivate_immediatelyReturnsDeactivatedIfLicenceDoesntExist() throws {
        let expectation = self.expectation(description: "Deactivate Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.deactivate() { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertFalse(response.isActive)

        XCTAssertNil(self.mockAPI.calledMethod)
    }

    func test_deactivate_immediatelyReturnsDeactivatedIfLicenceIsAlreadyDeactivated() throws {
        let payload: [String: Any] = ["response": "deactivated"]
        let signature = try self.signature(forPayload: payload)
        try self.writeLicence(["payload": payload, "signature": signature])

        let expectation = self.expectation(description: "Deactivate Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.deactivate() { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertFalse(response.isActive)

        XCTAssertNil(self.mockAPI.calledMethod)
    }

    func test_deactivate_tellsSubscriptionAPIToDeactivateWithDeviceAndSavedToken() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let expectation = self.expectation(description: "Deactivate Completed")
        self.controller.deactivate() { result in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(self.mockAPI.calledMethod, "deactivate")

        let device = Device()
        XCTAssertEqual(self.mockAPI.deviceArgument?.id, device.id)
        XCTAssertEqual(self.mockAPI.tokenArgument, "abctoken123")
    }

    func test_deactivate_returnsNoDeviceFoundError() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        self.mockAPI.deactivateResponse = .failure(.noDeviceFound)

        let expectation = self.expectation(description: "Deactivate Completed")
        var actualError: NSError? = nil
        self.controller.deactivate() { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_deactivate_returnsGenericError() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        let expectedError = NSError(domain: "test domain", code: 42, userInfo: nil)
        self.mockAPI.deactivateResponse = .failure(.generic(expectedError))

        let expectation = self.expectation(description: "Deactivate Completed")
        var actualError: NSError? = nil
        self.controller.deactivate() { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.other.rawValue)
        XCTAssertEqual(actualError?.userInfo[NSUnderlyingErrorKey] as? NSError, expectedError)
    }

    func test_deactivate_returnsGenericNilError() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        self.mockAPI.deactivateResponse = .failure(.generic(nil))

        let expectation = self.expectation(description: "Deactivate Completed")
        var actualError: NSError? = nil
        self.controller.deactivate() { result in
            if case .failure(let error) = result {
                actualError = error
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertEqual(actualError?.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError?.code, SubscriptionErrorCodes.other.rawValue)
    }

    func test_deactivate_removesLicenceOnDiskIfSuccessfullyDeactivated() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token":"abctoken123",
            "subscription": ["name":"Plan B", "expirationDate":"2035-01-01T00:00:00Z", "renewalStatus": "renew"],
            "device": ["name": "My iMac"]
        ]
        let storedSignature = try self.signature(forPayload: storedPayload)
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        self.mockAPI.deactivateResponse = .success(ActivationResponse.deactivated())

        let expectation = self.expectation(description: "Deactivate Completed")
        self.controller.deactivate() { result in
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        XCTAssertFalse(FileManager.default.fileExists(atPath: self.licenceURL.path))

    }

    func test_deactivate_returnsDeactivated() throws {
        let payload: [String: Any] = ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"]
        let signature = try self.signature(forPayload: payload)
        try self.writeLicence(["payload": payload, "signature": signature])

        self.mockAPI.deactivateResponse = .success(ActivationResponse.deactivated())

        let expectation = self.expectation(description: "Deactivate Completed")
        var actualResponse: ActivationResponse? = nil
        self.controller.deactivate() { result in
            if case .success(let response) = result {
                actualResponse = response
            }
            expectation.fulfill()
        }
        self.waitForExpectations(timeout: 1)

        let response = try XCTUnwrap(actualResponse)
        XCTAssertFalse(response.isActive)
    }

//    func test_deactivate_clearsTimer() throws {
//        let payload: [String: Any] = ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"]
//        let signature = try self.signature(forPayload: payload)
//        try self.writeLicence(["payload": payload, "signature": signature])
//
//        let payload: [String: Any] = ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]
//        let signature = try self.signature(forPayload: payload)
//        let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
//
//        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
//        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
//        self.mockAPI.checkResponse = .success(expectedResponse)
//        self.controller.checkSubscription()
//
//        XCTAssertNotNil(self.controller.recheckTimer)
//
//        self.mockAPI.deactivateResponse = .success(ActivationResponse.deactivated()!)
//
//        self.controller.deactivate()
//
//        XCTAssertNil(self.controller.recheckTimer)
//    }

}
