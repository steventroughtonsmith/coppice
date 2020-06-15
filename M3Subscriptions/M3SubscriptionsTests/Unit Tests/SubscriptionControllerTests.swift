//
//  SubscriptionController.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 11/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class SubscriptionControllerTests: XCTestCase {
    var licenceURL: URL!
    var mockAPI: MockSubscriptionAPI!
    var controller: SubscriptionController!
    var mockDelegate: MockSubscriptionDelegate!
    var mockUIDelegate: MockSubscriptionUIDelegate!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.licenceURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.mcubedsw.subscriptions").appendingPathComponent("licence.txt")
        try FileManager.default.createDirectory(at: self.licenceURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        self.mockAPI = MockSubscriptionAPI()
        self.controller = SubscriptionController(licenceURL: self.licenceURL, subscriptionAPI: self.mockAPI)

        self.mockDelegate = MockSubscriptionDelegate()
        self.controller.delegate = self.mockDelegate

        self.mockUIDelegate = MockSubscriptionUIDelegate()
        self.controller.uiDelegate = self.mockUIDelegate
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
        self.controller.activate(withEmail: "foo@bar.com", password: "123456")

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
        let plan = try XCTUnwrap(SubscriptionPlan(payload: ["id": "foobar", "name": "Plan 3", "maxDeviceCount": 3, "currentDeviceCount": 2, "expirationDate": "2035-01-01T00:00:00Z"]))
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef", subscription: plan)

        XCTAssertEqual(self.mockAPI.calledMethod, "activate")
        let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)

        XCTAssertEqual(actualRequest.email, "baz@possum.com")
        XCTAssertEqual(actualRequest.password, "abcdef")
        XCTAssertEqual(actualRequest.subscriptionID, "foobar")
    }

    func test_activate_tellsSubscriptionAPIToActivateWhileDeactivatingDeviceIfSupplied() throws {
        let device = try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "deleteimac", "name": "My iMac", "activationDate": "2035-01-01T00:00:00Z"]))
        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef", deactivatingDevice: device)

        XCTAssertEqual(self.mockAPI.calledMethod, "activate")
        let actualRequest = try XCTUnwrap(self.mockAPI.requestArgument)

        XCTAssertEqual(actualRequest.email, "baz@possum.com")
        XCTAssertEqual(actualRequest.password, "abcdef")
        XCTAssertEqual(actualRequest.deviceDeactivationToken, "deleteimac")
    }

    func test_activate_tellsDelegateOfServerConnectionErrorIfConnectionFailed() throws {
        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.activateResponse = .failure(.generic(expectedError))

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.couldNotConnectToServer.rawValue)
        XCTAssertEqual(actualError.userInfo[NSUnderlyingErrorKey] as? NSError, expectedError)
    }

    func test_activate_tellsDelegateOfLoginFailedError() throws {
        self.mockAPI.activateResponse = .failure(.loginFailed)

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.loginFailed.rawValue)
    }

    func test_activate_tellsDelegateOfSubscriptionExpirationError() throws {
        let expectedSubscription = try XCTUnwrap(Subscription(payload: ["subscriptionName": "Plan B", "expirationDate":"2035-01-01T00:00:00Z"]))
        self.mockAPI.activateResponse = .failure(.subscriptionExpired(expectedSubscription))

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.subscriptionExpired.rawValue)
        XCTAssertEqual(actualError.userInfo[SubscriptionErrorFactory.InfoKeys.subscription] as? Subscription, expectedSubscription)
    }

    func test_activate_tellsDelegateOfNoSubscriptionFoundError() throws {
        self.mockAPI.activateResponse = .failure(.noSubscriptionFound)

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_activate_tellsUIDelegateToShowSubscriptionPlansForMultipleSubscriptionsError() throws {
        let plans = [
            try XCTUnwrap(SubscriptionPlan(payload: ["id": "plan1", "name": "Plan A", "expirationDate":"2034-02-05T00:00:00Z", "maxDeviceCount": 5, "currentDeviceCount": 3])),
            try XCTUnwrap(SubscriptionPlan(payload: ["id": "foobar", "name": "Plan 3", "maxDeviceCount": 3, "currentDeviceCount": 2, "expirationDate": "2035-01-01T00:00:00Z"]))
        ]

        self.mockAPI.activateResponse = .failure(.multipleSubscriptions(plans))

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        XCTAssertEqual(self.mockUIDelegate.plansArgument, plans)
    }

    func test_activate_tellsUIDelegateToShowDevicesToDeactivateForTooManyDevicesError() throws {
        let devices = [
            try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "deleteimac", "name": "My iMac", "activationDate": "2035-01-01T00:00:00Z"])),
            try XCTUnwrap(SubscriptionDevice(payload: ["deactivationToken": "macpro", "name": "A Mac Pro", "activationDate": "2031-09-21T00:16:00Z"]))
        ]

        self.mockAPI.activateResponse = .failure(.tooManyDevices(devices))

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        XCTAssertEqual(self.mockUIDelegate.devicesArgument, devices)
    }

    func test_activate_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivated() throws {
        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        let expectedSubscription = try XCTUnwrap(Subscription(payload: ["subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]))

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let actualResponse = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(actualResponse.state, .active)
        XCTAssertEqual(actualResponse.token, "updated-token")
        XCTAssertEqual(actualResponse.subscription, expectedSubscription)
    }

    func test_activate_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivatedWithBillingFailure() throws {
        let expectedJSON: [String: Any] = ["payload": ["response": "billing_failed", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "dUZqFj+bII2zPftVNZjp3reO53+Uc0+Z5hDYcvLkg/lbVssoHLpJYCWeWV/r48zC4tbV2Yb1xMlTBFmN8PImwD7Noh+C/jamCbgl21HCZoTZ7CQe/ndIGaVul9fgIaCDH36Prfu2sVIHyv8he3sZWUMuBOU383zTCcG/TU9XxvLBnL1OjQ5fVSx7G83KoSo50PxTPfYsesVq2R4Y6/t6qLVQA3itqFxyJpgvdwFTGWYvVvyDNCDZIJ5HcMCweVmMgU+L/e7CBAKysHdvtXCfxLqlIxxJEs2Z8/tv2Wz0KOqpmzDGJLtZe/XyEcFmFhDzgGGuehtV0A71SXwuw3dWNw=="]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        let expectedSubscription = try XCTUnwrap(Subscription(payload: ["subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"]))

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let actualResponse = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(actualResponse.state, .billingFailed)
        XCTAssertEqual(actualResponse.token, "updated-token")
        XCTAssertEqual(actualResponse.subscription, expectedSubscription)
    }

    func test_activate_storesSuccessfulActivationToDiskIfActive() throws {
        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let json = try XCTUnwrap(try self.readLicence())
        let payload = try XCTUnwrap(json["payload"] as? [String: String])
        XCTAssertEqual(payload["response"], "active")
        XCTAssertEqual(payload["token"], "updated-token")
        XCTAssertEqual(payload["subscriptionName"], "Plan B")
        XCTAssertEqual(payload["expirationDate"], "2036-01-01T01:01:01Z")

        XCTAssertEqual(json["signature"] as? String, "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA==")
    }

    func test_activate_storesSuccessfulActivationToDiskIfBillingFailed() throws {
        let expectedJSON: [String: Any] = ["payload": ["response": "billing_failed", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature":"dUZqFj+bII2zPftVNZjp3reO53+Uc0+Z5hDYcvLkg/lbVssoHLpJYCWeWV/r48zC4tbV2Yb1xMlTBFmN8PImwD7Noh+C/jamCbgl21HCZoTZ7CQe/ndIGaVul9fgIaCDH36Prfu2sVIHyv8he3sZWUMuBOU383zTCcG/TU9XxvLBnL1OjQ5fVSx7G83KoSo50PxTPfYsesVq2R4Y6/t6qLVQA3itqFxyJpgvdwFTGWYvVvyDNCDZIJ5HcMCweVmMgU+L/e7CBAKysHdvtXCfxLqlIxxJEs2Z8/tv2Wz0KOqpmzDGJLtZe/XyEcFmFhDzgGGuehtV0A71SXwuw3dWNw=="]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)


        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let json = try XCTUnwrap(try self.readLicence())
        let payload = try XCTUnwrap(json["payload"] as? [String: String])
        XCTAssertEqual(payload["response"], "billing_failed")
        XCTAssertEqual(payload["token"], "updated-token")
        XCTAssertEqual(payload["subscriptionName"], "Plan B")
        XCTAssertEqual(payload["expirationDate"], "2036-01-01T01:01:01Z")

        XCTAssertEqual(json["signature"] as? String, "dUZqFj+bII2zPftVNZjp3reO53+Uc0+Z5hDYcvLkg/lbVssoHLpJYCWeWV/r48zC4tbV2Yb1xMlTBFmN8PImwD7Noh+C/jamCbgl21HCZoTZ7CQe/ndIGaVul9fgIaCDH36Prfu2sVIHyv8he3sZWUMuBOU383zTCcG/TU9XxvLBnL1OjQ5fVSx7G83KoSo50PxTPfYsesVq2R4Y6/t6qLVQA3itqFxyJpgvdwFTGWYvVvyDNCDZIJ5HcMCweVmMgU+L/e7CBAKysHdvtXCfxLqlIxxJEs2Z8/tv2Wz0KOqpmzDGJLtZe/XyEcFmFhDzgGGuehtV0A71SXwuw3dWNw==")
    }

    func test_activate_setsTimerToFireInAnHour() throws {
        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let timer = try XCTUnwrap(self.controller.recheckTimer)
        let difference = timer.fireDate.timeIntervalSince(Date())
        XCTAssertGreaterThan(difference, 3600 - 1)
        XCTAssertLessThan(difference, 3600 + 1)
    }

    func test_activate_setsLastCheckDate() throws {
        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        let lastCheck = try XCTUnwrap(self.controller.lastCheck)
        let difference = lastCheck.timeIntervalSince(Date())
        XCTAssertGreaterThan(difference, -1)
        XCTAssertLessThan(difference, 1)
    }

    func test_activate_callsCheckSubscriptionAgainIfTimerFiresAfterLastCheckDatePlus24Hours() throws {
        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]
        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.activateResponse = .success(expectedResponse)

        self.controller.activate(withEmail: "baz@possum.com", password: "abcdef")

        self.mockAPI.reset()
        let timer = try XCTUnwrap(self.controller.recheckTimer)

        XCTAssertNil(self.mockAPI.calledMethod)
        self.controller.setLastCheck(Date(timeIntervalSinceNow: -86401))
        timer.fire()

        XCTAssertEqual(self.mockAPI.calledMethod, "check")
    }


    //MARK: - checkSubscription(updatingDeviceName:)
    func test_checkSubscription_tellsSubscriptionAPIToCheckWithTokenAndDevice() throws {
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        self.controller.checkSubscription()

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
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        self.controller.checkSubscription(updatingDeviceName: "Foo Bar Baz")

        let actualDevice = try XCTUnwrap(self.mockAPI.deviceArgument)
        XCTAssertEqual(actualDevice.name, "Foo Bar Baz")
    }

    func test_checkSubscription_tellsDelegateOfNotActivatedErrorIfAPICallFailedAndNoLocalLicence() throws {
        let expectedError = NSError(domain: "test domain", code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))
        self.controller.checkSubscription()

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.notActivated.rawValue)
    }

    func test_checkSubscription_tellsDelegateOfServerConnectionErrorIfAPICallFailedAndLocalLicenceIsInvalid() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "invalid-token", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature":  "qjJKZXhTvFIsaINfhzHPFfC7DgQV+5/uMlwXvmX9eYFAIN1RIuJ0+l7EJreHsoiZja3PplnyoCqK1O9O0ZiM+XPTEKlEHMcP1KDKhtp5LhGxybzX55VozgNcZgqDf4cRO3WTY/P4J6jdTlyyXMIv/DITPcyQdf1oUdRm0t2rJT1pK58Jh2sLzFn7nus9c+XoVxCCR9JQZSPmZLoyPM83qLNiIgXH70N8aZ6qJOIC9eGNytJ3yBs56XFhcwXmEZnZ3XbTJWqlxkx8ybqtF90mmZeARBUwxfCuX26Xo9OcAfx76t9FPXGiPi7kvFjPg6WzCS5M97WZ6ff/0+MtdP7ojw=="])
        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))
        self.controller.checkSubscription()

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.notActivated.rawValue)
    }

    func test_checkSubscription_tellsDelegateOfExpirationErrorIfAPICallFailedAndLocalLicenceIsValidButBeyondExpirationDate() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2015-01-01T00:00:00Z"], "signature": "qjJKZXhTvFIsaINfhzHPFfC7DgQV+5/uMlwXvmX9eYFAIN1RIuJ0+l7EJreHsoiZja3PplnyoCqK1O9O0ZiM+XPTEKlEHMcP1KDKhtp5LhGxybzX55VozgNcZgqDf4cRO3WTY/P4J6jdTlyyXMIv/DITPcyQdf1oUdRm0t2rJT1pK58Jh2sLzFn7nus9c+XoVxCCR9JQZSPmZLoyPM83qLNiIgXH70N8aZ6qJOIC9eGNytJ3yBs56XFhcwXmEZnZ3XbTJWqlxkx8ybqtF90mmZeARBUwxfCuX26Xo9OcAfx76t9FPXGiPi7kvFjPg6WzCS5M97WZ6ff/0+MtdP7ojw=="])

        let expectedSubscription = Subscription(payload: ["subscriptionName": "Plan B", "expirationDate": "2015-01-01T00:00:00Z"])

        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))
        self.controller.checkSubscription()


        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.subscriptionExpired.rawValue)
        XCTAssertEqual(actualError.userInfo[SubscriptionErrorFactory.InfoKeys.subscription] as? Subscription, expectedSubscription)
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionChangeIfAPICallFailedAndLocalLicenceIsValid() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])
        let expectedSubscription = Subscription(payload: ["subscriptionName": "Plan B", "expirationDate":"2035-01-01T00:00:00Z"])
        let expectedError = NSError(domain: NSURLErrorDomain, code: 31, userInfo: nil)
        self.mockAPI.checkResponse = .failure(.generic(expectedError))
        self.controller.checkSubscription()

        let actualResponse = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(actualResponse.state, .active)
        XCTAssertEqual(actualResponse.token, "abctoken123")
        XCTAssertEqual(actualResponse.subscription, expectedSubscription)
    }

    func test_checkSubscription_tellsDelegateOfNoDeviceFoundError() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])
        self.mockAPI.checkResponse = .failure(.noDeviceFound)
        self.controller.checkSubscription()

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_checkSubscription_tellsDelegateOfNoSubscriptionFoundError() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])
        self.mockAPI.checkResponse = .failure(.noSubscriptionFound)
        self.controller.checkSubscription()

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionExpiredError() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])
        let expectedSubscription = Subscription(payload: ["name": "Old Sub", "expirationDate": "2011-11-11T11:11:11Z"])
        self.mockAPI.checkResponse = .failure(.subscriptionExpired(expectedSubscription))
        self.controller.checkSubscription()

        let actualError = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(actualError.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(actualError.code, SubscriptionErrorCodes.subscriptionExpired.rawValue)
        XCTAssertEqual(actualError.userInfo[SubscriptionErrorFactory.InfoKeys.subscription] as? Subscription, expectedSubscription)
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivated() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]
        let expectedSubscription = Subscription(payload: ["subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"])

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        let actualResponse = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(actualResponse.state, .active)
        XCTAssertEqual(actualResponse.token, "updated-token")
        XCTAssertEqual(actualResponse.subscription, expectedSubscription)
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivatedWithBillingFailure() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "billing_failed", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "dUZqFj+bII2zPftVNZjp3reO53+Uc0+Z5hDYcvLkg/lbVssoHLpJYCWeWV/r48zC4tbV2Yb1xMlTBFmN8PImwD7Noh+C/jamCbgl21HCZoTZ7CQe/ndIGaVul9fgIaCDH36Prfu2sVIHyv8he3sZWUMuBOU383zTCcG/TU9XxvLBnL1OjQ5fVSx7G83KoSo50PxTPfYsesVq2R4Y6/t6qLVQA3itqFxyJpgvdwFTGWYvVvyDNCDZIJ5HcMCweVmMgU+L/e7CBAKysHdvtXCfxLqlIxxJEs2Z8/tv2Wz0KOqpmzDGJLtZe/XyEcFmFhDzgGGuehtV0A71SXwuw3dWNw=="]
        let expectedSubscription = Subscription(payload: ["subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"])

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        let actualResponse = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(actualResponse.state, .billingFailed)
        XCTAssertEqual(actualResponse.token, "updated-token")
        XCTAssertEqual(actualResponse.subscription, expectedSubscription)
    }

    func test_checkSubscription_storesSuccessfulActivationToDiskIfActive() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        let actualJSON = try XCTUnwrap(try self.readLicence())

        let payload = try XCTUnwrap(actualJSON["payload"] as? [String: String])
        XCTAssertEqual(payload["response"], "active")
        XCTAssertEqual(payload["token"], "updated-token")
        XCTAssertEqual(payload["subscriptionName"], "Plan B")
        XCTAssertEqual(payload["expirationDate"], "2036-01-01T01:01:01Z")

        XCTAssertEqual(actualJSON["signature"] as? String, "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA==")
    }

    func test_checkSubscription_storesSuccessfulActivationToDiskIfBillingFailed() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "billing_failed", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "dUZqFj+bII2zPftVNZjp3reO53+Uc0+Z5hDYcvLkg/lbVssoHLpJYCWeWV/r48zC4tbV2Yb1xMlTBFmN8PImwD7Noh+C/jamCbgl21HCZoTZ7CQe/ndIGaVul9fgIaCDH36Prfu2sVIHyv8he3sZWUMuBOU383zTCcG/TU9XxvLBnL1OjQ5fVSx7G83KoSo50PxTPfYsesVq2R4Y6/t6qLVQA3itqFxyJpgvdwFTGWYvVvyDNCDZIJ5HcMCweVmMgU+L/e7CBAKysHdvtXCfxLqlIxxJEs2Z8/tv2Wz0KOqpmzDGJLtZe/XyEcFmFhDzgGGuehtV0A71SXwuw3dWNw=="]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        let actualJSON = try XCTUnwrap(try self.readLicence())

        let payload = try XCTUnwrap(actualJSON["payload"] as? [String: String])
        XCTAssertEqual(payload["response"], "billing_failed")
        XCTAssertEqual(payload["token"], "updated-token")
        XCTAssertEqual(payload["subscriptionName"], "Plan B")
        XCTAssertEqual(payload["expirationDate"], "2036-01-01T01:01:01Z")

        XCTAssertEqual(actualJSON["signature"] as? String, "dUZqFj+bII2zPftVNZjp3reO53+Uc0+Z5hDYcvLkg/lbVssoHLpJYCWeWV/r48zC4tbV2Yb1xMlTBFmN8PImwD7Noh+C/jamCbgl21HCZoTZ7CQe/ndIGaVul9fgIaCDH36Prfu2sVIHyv8he3sZWUMuBOU383zTCcG/TU9XxvLBnL1OjQ5fVSx7G83KoSo50PxTPfYsesVq2R4Y6/t6qLVQA3itqFxyJpgvdwFTGWYvVvyDNCDZIJ5HcMCweVmMgU+L/e7CBAKysHdvtXCfxLqlIxxJEs2Z8/tv2Wz0KOqpmzDGJLtZe/XyEcFmFhDzgGGuehtV0A71SXwuw3dWNw==")
    }

    func test_checkSubscription_setsTimerToFireInAnHour() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        let timer = try XCTUnwrap(self.controller.recheckTimer)
        let difference = timer.fireDate.timeIntervalSince(Date())
        XCTAssertGreaterThan(difference, 3600 - 1)
        XCTAssertLessThan(difference, 3600 + 1)
    }

    func test_checkSubscription_setsLastCheckDate() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        let lastCheck = try XCTUnwrap(self.controller.lastCheck)
        let difference = lastCheck.timeIntervalSince(Date())
        XCTAssertGreaterThan(difference, -1)
        XCTAssertLessThan(difference, 1)
    }

    func test_checkSubscription_callsCheckSubscriptionAgainIfTimerFiresAfterLastCheckDatePlus24Hours() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        self.mockAPI.reset()
        let timer = try XCTUnwrap(self.controller.recheckTimer)

        XCTAssertNil(self.mockAPI.calledMethod)
        self.controller.setLastCheck(Date(timeIntervalSinceNow: -86401))
        timer.fire()

        XCTAssertEqual(self.mockAPI.calledMethod, "check")
    }


    //MARK: - deactivate()
    func test_deactivate_immediatelyTellsDelegateToChangeSubscriptionToDeactivatedIfLicenceDoesntExist() throws {
        self.controller.deactivate()

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .deactivated)

        XCTAssertNil(self.mockAPI.calledMethod)
    }

    func test_deactivate_immediatelyTellsDelegateToChangeSubscriptionToDeactivatedIfLicenceIsAlreadyDeactivated() throws {
        try self.writeLicence(["payload": ["response": "deactivated"], "signature": "2FK5GJmiT6C4aLZTWq8R0d+sEXWLORh0iQnHKritAfySu+W/wvhlblSXy2hUqKiRjHuOWIcz+f4wjMBTuoki7SAV78LElaPxor2hIEB8eqtaX3P+foAY0s/XpnlXWXg7YrUD53YsCRaZR47rLfLBsS9iCcKPRIWz8xXgyev4sbwt2Td3EvFukIasGRsTMe9Jvt0Qi1euyN8yKB7kYPqH43Oaua0rdxUN8BjoiTmUHwq7Z3gBn2+3K7DzhfRoYY7AAqZDO9FwDrcrwI5b5M5eXG9ZLSCdYJadeW6VfFLc/6Mtnt59EHzazbmzkfUwYw0y0+Cbvj8eb/+eiN8a/ALgBg=="])

        self.controller.deactivate()

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .deactivated)

        XCTAssertNil(self.mockAPI.calledMethod)
    }

    func test_deactivate_tellsSubscriptionAPIToDeactivateWithDeviceAndSavedToken() throws {
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        self.controller.deactivate()

        XCTAssertEqual(self.mockAPI.calledMethod, "deactivate")

        let device = Device()
        XCTAssertEqual(self.mockAPI.deviceArgument?.id, device.id)
        XCTAssertEqual(self.mockAPI.tokenArgument, "abctoken123")
    }

    func test_deactivate_tellsDelegateOfNoDeviceFoundError() throws {
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        self.mockAPI.deactivateResponse = .failure(.noDeviceFound)

        self.controller.deactivate()

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_deactivate_tellsDelegateOfGenericError() throws {
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedError = NSError(domain: "test domain", code: 42, userInfo: nil)
        self.mockAPI.deactivateResponse = .failure(.generic(expectedError))

        self.controller.deactivate()

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.other.rawValue)
        XCTAssertEqual(error.userInfo[NSUnderlyingErrorKey] as? NSError, expectedError)
    }

    func test_deactivate_tellsDelegateOfGenericNilError() throws {
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        self.mockAPI.deactivateResponse = .failure(.generic(nil))

        self.controller.deactivate()

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.domain, SubscriptionErrorFactory.domain)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.other.rawValue)
    }

    func test_deactivate_removesLicenceOnDiskIfSuccessfullyDeactivated() throws {
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        self.mockAPI.deactivateResponse = .success(ActivationResponse.deactivated()!)

        self.controller.deactivate()

        XCTAssertFalse(FileManager.default.fileExists(atPath: self.licenceURL.path))

    }

    func test_deactivate_tellsDelegateOfSubscriptionChangeIfSuccessfullyDeactivated() throws {
        try self.writeLicence(["payload": ["response": "active", "token":"abctoken123", "subscriptionName":"Plan B", "expirationDate":"2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        self.mockAPI.deactivateResponse = .success(ActivationResponse.deactivated()!)

        self.controller.deactivate()

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .deactivated)
    }

    func test_deactivate_clearsTimer() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "abctoken123", "subscriptionName": "Plan B", "expirationDate": "2035-01-01T00:00:00Z"], "signature": "p95hpnUCr/DdzKmCbNHPdb+oZoNnRVdC05aj9uxlpMhBSStSnpYn0GqRv3zGYKoCEmLrTNtCV87kT4tmHsknfOgrDE7/6+BQwYwP2+iLU9fbbQhmMuTBYTChw205VjwHu1wQKGy8QYC96sZ7TjlkQ/73kLfeTUKH8TGmvv3XEm10PY6NryuAbfnzd2zpKoL/bUMOcSCdZJb7NJ1FHLf/DmZVvlCYBfKahyE9+2xiQYbhqAfuDzAs+1PWvCkDdOSM8CFy0UlScdLLhvj6/JSr6DUWt4Ivgr6ATRiKOQIaeo8BwH1dtMgwXgw50V3fSl70b2j7DGx5sXBf5WUBIxMwdw=="])

        let expectedJSON: [String: Any] = ["payload": ["response": "active", "token": "updated-token", "subscriptionName": "Plan B", "expirationDate": "2036-01-01T01:01:01Z"], "signature": "sLD+XmujPGuq7LrEA1r7vTlwdRIhIUUIbozw10KWo1OAobiuiAJSei2Fuuk/jxMvaI9aAh4565s6L05kLyfBCiyC043ohdVDsqip4OlORqKBC+V0bF0p7PR7QLlVH7gkWJzzte7S3XgFRLGEsmzNeqv2waZaRfDWAXXowaSxTGYe8YQxXuNWfTUI1IUz3xVrjvu7SS8sXN8kcgmjCCAIwG3IqS0kdyWnqlcFUqr6pFsFbQFTQvASpa4GRz+DZc2QbZQHdCxUHA4oSf49BQb2s81b7BEOZagODtkaEmku6i9w09PqGKyw6+Fh5UukQJmKVO26rJKFScRORalJsY91MA=="]

        let apiData = try XCTUnwrap(APIData(json: expectedJSON))
        let expectedResponse = try XCTUnwrap(ActivationResponse(data: apiData))
        self.mockAPI.checkResponse = .success(expectedResponse)
        self.controller.checkSubscription()

        XCTAssertNotNil(self.controller.recheckTimer)

        self.mockAPI.deactivateResponse = .success(ActivationResponse.deactivated()!)

        self.controller.deactivate()

        XCTAssertNil(self.controller.recheckTimer)
    }

}


class MockSubscriptionDelegate: SubscriptionControllerDelegate {
    var activationResponse: ActivationResponse?
    func didChangeSubscription(_ info: ActivationResponse, in controller: SubscriptionController) {
        self.activationResponse = info
    }

    var error: NSError?
    func didEncounterError(_ error: NSError, in controller: SubscriptionController) {
        self.error = error
    }
}


class MockSubscriptionUIDelegate: SubscriptionControllerUIDelegate {
    var plansArgument: [SubscriptionPlan]?
    func showSubscriptionPlans(_ plans: [SubscriptionPlan], for controller: SubscriptionController) {
        self.plansArgument = plans
    }

    var devicesArgument: [SubscriptionDevice]?
    func showDevicesToDeactivate(_ devices: [SubscriptionDevice], for controller: SubscriptionController) {
        self.devicesArgument = devices
    }
}
