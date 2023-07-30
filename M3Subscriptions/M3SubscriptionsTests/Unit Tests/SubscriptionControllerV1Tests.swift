//
//  SubscriptionControllerV1Tests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 11/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

extension API.V1 {
    class SubscriptionControllerV1Tests: APITestCase {
        var licenceURL: URL!
        var mockAPI: MockSubscriptionAPIV1!
        var controller: SubscriptionController!

        override func setUpWithError() throws {
            try super.setUpWithError()
            self.licenceURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.mcubedsw.subscriptions").appendingPathComponent("licence.txt")
            try FileManager.default.createDirectory(at: self.licenceURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
            self.mockAPI = MockSubscriptionAPIV1()
            self.controller = SubscriptionController(activationDetailsURL: self.licenceURL, subscriptionAPI: self.mockAPI)
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
        func test_activate_tellsSubscriptionAPIToActivateWithRequestAndDevice() async throws {
            _ = try? await self.controller.activate(withEmail: "foo@bar.com", password: "123456")

            XCTAssertEqual(self.mockAPI.calledMethod, "activate")
            let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)
            let actualDevice = try XCTUnwrap(self.mockAPI.deviceArgument)

            XCTAssertEqual(actualRequest.email, "foo@bar.com")
            XCTAssertEqual(actualRequest.password, "123456")

            let device = Device()
            XCTAssertEqual(actualDevice.id, device.id)
            XCTAssertEqual(actualDevice.name, Host.current().localizedName)
        }

        func test_activate_tellsSubscriptionAPIToActivateWithSubscriptionPlanIfSupplied() async throws {
            let plan = try XCTUnwrap(Subscription(payload: ["id": "foobar", "name": "Plan 3", "maxDeviceCount": 3, "currentDeviceCount": 2, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: false))
            _ = try? await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef", subscription: plan)

            XCTAssertEqual(self.mockAPI.calledMethod, "activate")
            let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)

            XCTAssertEqual(actualRequest.email, "baz@possum.com")
            XCTAssertEqual(actualRequest.password, "abcdef")
            XCTAssertEqual(actualRequest.subscriptionID, "foobar")
        }

        func test_activate_tellsSubscriptionAPIToActivateWhileDeactivatingDeviceIfSupplied() async throws {
            let device = try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "deleteimac", "name": "My iMac", "activationDate": "2035-01-01T00:00:00Z"]))
            _ = try? await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef", deactivatingDevice: device)

            XCTAssertEqual(self.mockAPI.calledMethod, "activate")
            let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)

            XCTAssertEqual(actualRequest.email, "baz@possum.com")
            XCTAssertEqual(actualRequest.password, "abcdef")
            XCTAssertEqual(actualRequest.deviceDeactivationToken, "deleteimac")
        }

        func test_activate_returnsServerConnectionErrorIfConnectionFailed() async throws {
            let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
            self.mockAPI.activateError = .generic(expectedError)

            await XCTAssertThrowsErrorAsync(try await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.couldNotConnectToServer.rawValue)
                XCTAssertEqual(actualError.userInfo[NSUnderlyingErrorKey] as? NSError, expectedError)
            }
        }

        func test_activate_returnsLoginFailedError() async throws {
            self.mockAPI.activateError = .loginFailed

            await XCTAssertThrowsErrorAsync(try await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.loginFailed.rawValue)
            }
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

        func test_activate_returnsNoSubscriptionFoundError() async throws {
            self.mockAPI.activateError = .noSubscriptionFound

            await XCTAssertThrowsErrorAsync(try await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
            }
        }

        func test_activate_returnsMultipleSubscriptionsErrorWithSubscriptionPlans() async throws {
            let plans = [
                try XCTUnwrap(Subscription(payload: ["id": "plan1", "name": "Plan A", "expirationDate": "2034-02-05T00:00:00Z", "maxDeviceCount": 5, "currentDeviceCount": 3, "renewalStatus": "renew"], hasExpired: false)),
                try XCTUnwrap(Subscription(payload: ["id": "foobar", "name": "Plan 3", "maxDeviceCount": 3, "currentDeviceCount": 2, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: false)),
            ]

            self.mockAPI.activateError = .multipleSubscriptions(plans)

            await XCTAssertThrowsErrorAsync(try await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.multipleSubscriptionsFound.rawValue)
                XCTAssertEqual(actualError.userInfo[SubscriptionErrorFactory.InfoKeys.subscriptionPlans] as? [Subscription], plans)
            }
        }

        func test_activate_returnsTooManyDevicesErrorWithDevices() async throws {
            let devices = [
                try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "deleteimac", "name": "My iMac", "activationDate": "2035-01-01T00:00:00Z"])),
                try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "macpro", "name": "A Mac Pro", "activationDate": "2031-09-21T00:16:00Z"])),
            ]

            self.mockAPI.activateError = .tooManyDevices(devices)

            await XCTAssertThrowsErrorAsync(try await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.tooManyDevices.rawValue)
                XCTAssertEqual(actualError.userInfo[SubscriptionErrorFactory.InfoKeys.devices] as? [SubscriptionDevice], devices)
            }
        }

        private func run_activate_successfullyActivatedTest(with renewalStatus: Subscription.RenewalStatus) async throws {
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
            self.mockAPI.activateReturnValue = expectedResponse

            let expectedSubscription = try XCTUnwrap(Subscription(payload: ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": renewalStatus.rawValue], hasExpired: false))
            let response = try await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

            XCTAssertTrue(response.isActive)
            XCTAssertTrue(response.deviceIsActivated)
            XCTAssertEqual(response.token, "updated-token")
            XCTAssertEqual(response.subscription, expectedSubscription)
        }

        func test_activate_returnsActiveResponseIfSuccessfullyActivated() async throws {
            try await self.run_activate_successfullyActivatedTest(with: .renew)
        }

        func test_activate_returnsActiveResponseIfSuccessfullyActivatedWithFailedRenewStatus() async throws {
            try await self.run_activate_successfullyActivatedTest(with: .failed)
        }

        func test_activate_returnsActiveResponseIfSuccessfullyActivatedWithCancelledRenewStatus() async throws {
            try await self.run_activate_successfullyActivatedTest(with: .cancelled)
        }

        func test_activate_storesSuccessfulActivationToDiskIfActive() async throws {
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
            self.mockAPI.activateReturnValue = expectedResponse

            _ = try await self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

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
        func test_checkSubscription_tellsSubscriptionAPIToCheckWithTokenAndDevice() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            _ = try? await self.controller.checkSubscription()

            XCTAssertEqual(self.mockAPI.calledMethod, "check")

            let device = Device()
            let actualDevice = try XCTUnwrap(self.mockAPI.deviceArgument)
            let actualToken = try XCTUnwrap(self.mockAPI.tokenArgument)
            XCTAssertEqual(actualDevice.id, device.id)
            XCTAssertEqual(actualDevice.appVersion, device.appVersion)
            XCTAssertEqual(actualToken, "abctoken123")
            XCTAssertNil(actualDevice.name)
        }

        func test_checkSubscription_tellsSubscriptionAPIToCheckWithDeviceNameIfSupplied() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            _ = try? await self.controller.checkSubscription(updatingDeviceName: "Foo Bar Baz")

            let actualDevice = try XCTUnwrap(self.mockAPI.deviceArgument)
            XCTAssertEqual(actualDevice.name, "Foo Bar Baz")
        }

        func test_checkSubscription_returnsNotActivatedErrorIfAPICallFailedAndNoLocalLicence() async throws {
            let expectedError = NSError(domain: "test domain", code: 31, userInfo: nil)
            self.mockAPI.checkError = .generic(expectedError)

            await XCTAssertThrowsErrorAsync(try await self.controller.checkSubscription()) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.notActivated.rawValue)
            }
        }

        func test_checkSubscription_returnsServerConnectionErrorIfAPICallFailedAndLocalLicenceIsInvalid() async throws {
            var storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            storedPayload["token"] = "invalid-token"
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
            let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
            self.mockAPI.checkError = .generic(expectedError)

            await XCTAssertThrowsErrorAsync(try await self.controller.checkSubscription()) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.notActivated.rawValue)
            }
        }

        func test_checkSubscription_returnsActivationResponseWithExpiredSubscriptionIfAPICallFailedAndLocalLicenceIsValidButBeyondExpirationDate() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2015-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate": "2015-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: true)

            let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
            self.mockAPI.checkError = .generic(expectedError)

            let response = try await self.controller.checkSubscription()

            XCTAssertFalse(response.isActive)
            XCTAssertTrue(response.deviceIsActivated)
            XCTAssertEqual(response.token, "abctoken123")
            XCTAssertEqual(response.deviceName, "My iMac")
            XCTAssertEqual(response.subscription, expectedSubscription)
        }

        func test_checkSubscription_returnsActivationResponseIfAPICallFailedAndLocalLicenceIsValid() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
            let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: false)
            let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
            self.mockAPI.checkError = .generic(expectedError)

            let response = try await self.controller.checkSubscription()

            XCTAssertTrue(response.isActive)
            XCTAssertTrue(response.deviceIsActivated)
            XCTAssertEqual(response.token, "abctoken123")
            XCTAssertEqual(response.deviceName, "My iMac")
            XCTAssertEqual(response.subscription, expectedSubscription)
        }

        func test_checkSubscription_returnsNoDeviceFoundError() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
            self.mockAPI.checkError = .noDeviceFound

            await XCTAssertThrowsErrorAsync(try await self.controller.checkSubscription()) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
            }
        }

        func test_checkSubscription_returnsNoSubscriptionFoundError() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
            self.mockAPI.checkError = .noSubscriptionFound

            await XCTAssertThrowsErrorAsync(try await self.controller.checkSubscription()) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
            }
        }

        func test_checkSubscription_returnsActivationResponseWithExpiredSubscription() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            let payload: [String: Any] = [
                "response": "subscription_expired",
                "token": "updated-token",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let signature = try self.signature(forPayload: payload)
            let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
            let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"], hasExpired: true)

            let apiData = try XCTUnwrap(APIData(json: expectedJSON))
            let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
            self.mockAPI.checkReturnValue = expectedResponse

            let response = try await self.controller.checkSubscription()

            XCTAssertFalse(response.isActive)
            XCTAssertTrue(response.deviceIsActivated)
            XCTAssertEqual(response.token, "updated-token")
            XCTAssertEqual(response.subscription, expectedSubscription)
        }

        private func run_checkSubscription_returnsActiveResponseIfStillActivated(with renewalStatus: Subscription.RenewalStatus) async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": renewalStatus.rawValue],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            let payload: [String: Any] = [
                "response": "active",
                "token": "updated-token",
                "subscription": ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": renewalStatus.rawValue],
                "device": ["name": "My iMac"],
            ]
            let signature = try self.signature(forPayload: payload)
            let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]
            let expectedSubscription = Subscription(payload: ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": renewalStatus.rawValue], hasExpired: false)

            let apiData = try XCTUnwrap(APIData(json: expectedJSON))
            let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
            self.mockAPI.checkReturnValue = expectedResponse

            let response = try await self.controller.checkSubscription()
            XCTAssertTrue(response.isActive)
            XCTAssertTrue(response.deviceIsActivated)
            XCTAssertEqual(response.token, "updated-token")
            XCTAssertEqual(response.subscription, expectedSubscription)
        }

        func test_checkSubscription_returnsActivationResponseIfStillActivated() async throws {
            try await self.run_checkSubscription_returnsActiveResponseIfStillActivated(with: .renew)
        }

        func test_checkSubscription_returnsActivationResponseIfSuccessfullyActivatedWithFailedRenewalStatus() async throws {
            try await self.run_checkSubscription_returnsActiveResponseIfStillActivated(with: .failed)
        }

        func test_checkSubscription_returnsActivationResponseIfSuccessfullyActivatedWithCancelledRenewalStatus() async throws {
            try await self.run_checkSubscription_returnsActiveResponseIfStillActivated(with: .cancelled)
        }

        func test_checkSubscription_storesSuccessfulActivationToDiskIfActive() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

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
            self.mockAPI.checkReturnValue = expectedResponse

            _ = try await self.controller.checkSubscription()

            let actualJSON = try XCTUnwrap(try self.readLicence())

            let actualPayload = try XCTUnwrap(actualJSON["payload"] as? [String: Any])
            XCTAssertEqual(actualPayload["response"] as? String, "active")
            XCTAssertEqual(actualPayload["token"] as? String, "updated-token")
            XCTAssertEqual(actualPayload["subscription"] as? [String: String], ["name": "Plan B", "expirationDate": "2036-01-01T01:01:01Z", "renewalStatus": "renew"])
            XCTAssertEqual(actualPayload["device"] as? [String: String], ["name": "My iMac"])

            XCTAssertEqual(actualJSON["signature"] as? String, signature)
        }

        func test_checkSubscription_storesActivationToDiskIfExpired() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            let payload: [String: Any] = [
                "response": "subscription_expired",
                "token": "updated-token",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "cancelled"],
                "device": ["name": "My iMac"],
            ]
            let signature = try self.signature(forPayload: payload)
            let expectedJSON: [String: Any] = ["payload": payload, "signature": signature]

            let apiData = try XCTUnwrap(APIData(json: expectedJSON))
            let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
            self.mockAPI.checkReturnValue = expectedResponse

            _ = try await self.controller.checkSubscription()

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
        func test_deactivate_immediatelyReturnsDeactivatedIfLicenceDoesntExist() async throws {
            let response = try await self.controller.deactivate()
            XCTAssertFalse(response.isActive)

            XCTAssertNil(self.mockAPI.calledMethod)
        }

        func test_deactivate_immediatelyReturnsDeactivatedIfLicenceIsAlreadyDeactivated() async throws {
            let payload: [String: Any] = ["response": "deactivated"]
            let signature = try self.signature(forPayload: payload)
            try self.writeLicence(["payload": payload, "signature": signature])

            let response = try await self.controller.deactivate()
            XCTAssertFalse(response.isActive)

            XCTAssertNil(self.mockAPI.calledMethod)
        }

        func test_deactivate_tellsSubscriptionAPIToDeactivateWithDeviceAndSavedToken() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            _ = try? await self.controller.deactivate()

            XCTAssertEqual(self.mockAPI.calledMethod, "deactivate")

            let device = Device()
            XCTAssertEqual(self.mockAPI.deviceArgument?.id, device.id)
            XCTAssertEqual(self.mockAPI.tokenArgument, "abctoken123")
        }

        func test_deactivate_returnsNoDeviceFoundError() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            self.mockAPI.deactivateError = .noDeviceFound

            await XCTAssertThrowsErrorAsync(try await self.controller.deactivate()) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
            }
        }

        func test_deactivate_returnsGenericError() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            let expectedError = NSError(domain: "test domain", code: 42, userInfo: nil)
            self.mockAPI.deactivateError = .generic(expectedError)

            await XCTAssertThrowsErrorAsync(try await self.controller.deactivate()) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.other.rawValue)
                XCTAssertEqual(actualError.userInfo[NSUnderlyingErrorKey] as? NSError, expectedError)
            }
        }

        func test_deactivate_returnsGenericNilError() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            self.mockAPI.deactivateError = .generic(nil)
            await XCTAssertThrowsErrorAsync(try await self.controller.deactivate()) { error in
                let actualError = error as NSError
                XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
                XCTAssertEqual(actualError.code, SubscriptionErrorCodes.other.rawValue)
            }
        }

        func test_deactivate_removesLicenceOnDiskIfSuccessfullyDeactivated() async throws {
            let storedPayload: [String: Any] = [
                "response": "active",
                "token": "abctoken123",
                "subscription": ["name": "Plan B", "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"],
                "device": ["name": "My iMac"],
            ]
            let storedSignature = try self.signature(forPayload: storedPayload)
            try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

            self.mockAPI.deactivateReturnValue = ActivationResponse.deactivated()

            _ = try await self.controller.deactivate()

            XCTAssertFalse(FileManager.default.fileExists(atPath: self.licenceURL.path))
        }

        func test_deactivate_returnsDeactivated() async throws {
            let payload: [String: Any] = ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"]
            let signature = try self.signature(forPayload: payload)
            try self.writeLicence(["payload": payload, "signature": signature])

            self.mockAPI.deactivateReturnValue = ActivationResponse.deactivated()

            let response = try await self.controller.deactivate()
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
}
