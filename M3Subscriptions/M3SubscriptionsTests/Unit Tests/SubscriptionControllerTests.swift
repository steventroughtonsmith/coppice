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

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.licenceURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.mcubed.subscriptions").appendingPathComponent("licence.txt")
        try FileManager.default.createDirectory(at: self.licenceURL.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)
        self.mockAPI = MockSubscriptionAPI()
        self.controller = SubscriptionController(licenceURL: self.licenceURL, subscriptionAPI: self.mockAPI)

        self.mockDelegate = MockSubscriptionDelegate()
        self.controller.delegate = self.mockDelegate
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



    //MARK: - activate(withEmail:password:subscription:deactivatingDevice:)
    func test_activate_tellsSubscriptionAPIToActivateWithRequestAndDevice() throws {
        XCTFail()
    }

    func test_activate_tellsSubscriptionAPIToActivateWithSubscriptionPlanIfSupplied() throws {
        XCTFail()
    }

    func test_activate_tellsSubscriptionAPIToActivateWhileDeactivatingDeviceIfSupplied() throws {
        XCTFail()
    }

    func test_activate_tellsDelegateOfServerConnectionErrorIfConnectionFailed() throws {
        XCTFail()
    }

    func test_activate_tellsDelegateOfLoginFailedError() throws {
        XCTFail()
    }

    func test_activate_tellsDelegateOfSubscriptionExpirationError() throws {
        XCTFail()
    }

    func test_activate_tellsDelegateOfNoSubscriptionFoundError() throws {
        XCTFail()
    }

    func test_activate_tellsUIDelegateToShowSubscriptionPlansForMultipleSubscriptionsError() throws {
        XCTFail()
    }

    func test_activate_tellsUIDelegateToShowDevicesToDeactivateForTooManyDevicesError() throws {
        XCTFail()
    }

    func test_activate_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivated() throws {
        XCTFail()
    }

    func test_activate_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivatedWithBillingFailure() throws {
        XCTFail()
    }

    func test_activate_storesSuccessfulActivationToDiskIfActive() throws {
        XCTFail()
    }

    func test_activate_storesSuccessfulActivationToDiskIfBillingFailed() throws {
        XCTFail()
    }

    func test_activate_callsCheckSubscriptionAfterTimerFires() throws {
        XCTFail()
    }


    //MARK: - checkSubscription(updatingDeviceName:)
    func test_checkSubscription_tellsSubscriptionAPIToCheckWithTokenAndDevice() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsSubscriptionAPIToCheckWithDeviceNameIfSupplied() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfNotActivatedErrorIfAPICallFailedAndNoLocalLicence() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfServerConnectionErrorIfAPICallFailedAndLocalLicenceIsInvalid() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfExpirationErrorIfAPICallFailedAndLocalLicenceIsValidButBeyondExpirationDate() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionChangeIfAPICallFailedAndLocalLicenceIsValid() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfNoDeviceFoundError() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfNoSubscriptionFoundError() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionExpiredError() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivated() throws {
        XCTFail()
    }

    func test_checkSubscription_tellsDelegateOfSubscriptionChangeIfSuccessfullyActivatedWithBillingFailure() throws {
        XCTFail()
    }

    func test_checkSubscription_storesSuccessfulActivationToDiskIfActive() throws {
        XCTFail()
    }

    func test_checkSubscription_storesSuccessfulActivationToDiskIfBillingFailed() throws {
        XCTFail()
    }

    func test_checkSubscription_callsCheckSubscriptionAgainAfterTimerFires() throws {
        XCTFail()
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
