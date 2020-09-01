//
//  M3SubscriptionsStageTests.swift
//  M3SubscriptionsStageTests
//
//  Created by Martin Pilkington on 14/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

struct TestData {
    struct Emails {
        static let empty = "empty@mcubedsw.com"
        static let basic = "basic@mcubedsw.com"
        static let basicExpired = "basic_expired@mcubedsw.com"
        static let multipleApps = "multiple_apps@mcubedsw.com"
        static let multipleSubscriptions = "multiple_subs@mcubedsw.com"
        static let multipleSubscriptionsExpired = "multiple_subs_expired@mcubedsw.com"
        static let tooManyDevices = "too_many_devices@mcubedsw.com"
    }

    static let password = "1234567890"

    struct BundleIDs {
        static let appA = "com.mcubedsw.appa"
        static let appB = "com.mcubedsw.appb"
    }

    struct SubscriptionName {
        static let appAAnnual = "App A (Annual)"
        static let appAMonthly = "App A (Monthly)"
        static let appBAnnual = "App B (Annual)"
    }

    struct DeviceIDs {
        static let basic = "9A020C50-2910-4034-A981-BD40FFB76C4A"
        static let basicExpired = "DA088B59-A5E9-4DD3-82A7-8CB9B22A09AE"
        static let tooManyDevices1 = "544D97C8-E456-489C-B8C1-5E7FD9E24E87"
        static let tooManyDevices2 = "16F260F8-A1AD-48DD-A38C-82E1F753B852"
    }

    struct DeviceNames {
        static let basic = "My iMac"
        static let basicExpired = "Mac Mini"
        static let tooManyDevices1 = "MacBook Pro"
        static let tooManyDevices2 = "Mac Pro"
    }

    struct Tokens {
        static let basic = "E62EFBD0-62E8-4C1F-B2E1-25F712621960"
        static let basicExpired = "41D79059-F66D-40EB-A8C0-65159CE9329E"
        static let tooManyDevices1 = "9216F578-7311-4949-932C-5333886FB03E"
        static let tooManyDevices2 = "A426953A-C611-403D-9E59-0B70E16CE2F2"
    }
}


class M3SubscriptionsStageTests: XCTestCase {
    var prepareURL:URL!
    var licenceURL: URL!
    var controller: SubscriptionController!

    override func setUpWithError() throws {
        try super.setUpWithError()

        let serverURL = "https://integration-test-mcubedsw-com:8890"
        self.prepareURL = URL(string: "\(serverURL)/test/prepare")!
        TEST_OVERRIDES.baseURL = URL(string: "\(serverURL)/api")!
        TEST_OVERRIDES.apiVersion = "v1"

        let licenceDirectory = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("com.mcubedsw.subscriptions")
        if !FileManager.default.fileExists(atPath: licenceDirectory.path) {
            try FileManager.default.createDirectory(at: licenceDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        self.licenceURL = licenceDirectory.appendingPathComponent("stage-licence.txt")
        self.controller = SubscriptionController(licenceURL: self.licenceURL)

        self.prepare()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()

        if FileManager.default.fileExists(atPath: self.licenceURL.path) {
            try FileManager.default.removeItem(at: self.licenceURL)
        }
    }

    private func prepare() {
        self.performAndWaitFor("Call to prepare") { (expectation) in
            let dataTask = URLSession.shared.dataTask(with: self.prepareURL) { (_, response, error) in
                XCTAssertNil(error)
                XCTAssertEqual((response as? HTTPURLResponse)?.statusCode, 200)
                expectation.fulfill()
            }
            dataTask.resume()
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


    //MARK: - Activate
    func test_activate_loginFailed() throws {
        var actualError: NSError?
        self.performAndWaitFor("Wait for error", timeout: 2) { (expectation) in
            self.controller.activate(withEmail: "pilky@mcubedsw.com", password: "password1!") { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.loginFailed.rawValue)
    }

    func test_activate_emptyAccount() throws {
        var actualError: NSError?
        self.performAndWaitFor("Wait for error", timeout: 2) { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.empty, password: TestData.password) { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_activate_accountHasSubscriptionsButNotForApp() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        var actualError: NSError?
        self.performAndWaitFor("Wait for error", timeout: 2) { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.basic, password: TestData.password) { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_activate_accountHasSubscriptionForAppButItsExpired() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.basicExpired, password: TestData.password) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertFalse(response.isActive)
        XCTAssertFalse(response.deviceIsActivated)
        XCTAssertNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertLessThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasActiveSubscriptionForApp() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.basic, password: TestData.password) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasTwoSubscriptionsButForDifferentApps() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.multipleApps, password: TestData.password) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appAAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasTwoSubscriptionsForTheSameAppButOneHasExpired() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptionsExpired, password: TestData.password) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appAAnnual)
        XCTAssertEqual(subscription.renewalStatus, .failed)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasTwoActiveSubscriptionsForTheSameApp() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        var actualError: NSError?
        self.performAndWaitFor("Wait for subscription plans") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptions, password: TestData.password){ result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.multipleSubscriptionsFound.rawValue)

        let plans = try XCTUnwrap(error.userInfo[SubscriptionErrorFactory.InfoKeys.subscriptionPlans] as? [Subscription])
        XCTAssertEqual(plans.count, 2)
        XCTAssertTrue(plans.contains(where: { $0.name == TestData.SubscriptionName.appAAnnual && $0.renewalStatus == .failed}))
        XCTAssertTrue(plans.contains(where: { $0.name == TestData.SubscriptionName.appAMonthly && $0.renewalStatus == .renew}))
    }

    func test_activate_accountHasTwoActiveSubscriptionsForTheSameAppAndSubscriptionIDProvided() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        var actualError: NSError?
        self.performAndWaitFor("Wait for subscription plans") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptions, password: TestData.password) { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let plans = try XCTUnwrap(actualError?.userInfo[SubscriptionErrorFactory.InfoKeys.subscriptionPlans] as? [Subscription])
        let subscriptionPlan = try XCTUnwrap(plans.first(where: { $0.name == TestData.SubscriptionName.appAMonthly }))

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptions, password: TestData.password, subscription: subscriptionPlan) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appAMonthly)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasSubscriptionButIsMaxedOutOnDeviceType() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        var actualError: NSError?
        self.performAndWaitFor("Wait for devices") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password) { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.tooManyDevices.rawValue)

        let devices = try XCTUnwrap(error.userInfo[SubscriptionErrorFactory.InfoKeys.devices] as? [SubscriptionDevice])
        XCTAssertEqual(devices.count, 2)
        XCTAssertTrue(devices.contains(where: { $0.name == TestData.DeviceNames.tooManyDevices1}))
        XCTAssertTrue(devices.contains(where: { $0.name == TestData.DeviceNames.tooManyDevices2}))
    }

    func test_activate_accountHasSubscriptionButIsMaxedOutOnDeviceTypeAndDeactivatingDeviceTokenProvided() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        var actualError: NSError?
        self.performAndWaitFor("Wait for devices") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password) { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let devices = try XCTUnwrap(actualError?.userInfo[SubscriptionErrorFactory.InfoKeys.devices] as? [SubscriptionDevice])
        let device = try XCTUnwrap(devices.first(where: { $0.name == TestData.DeviceNames.tooManyDevices2 }))

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activate") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password, deactivatingDevice: device) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasSubscriptionMaxedOutOnOtherDeviceTypeButNotThisDeviceType() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB
        TEST_OVERRIDES.deviceType = .ipad

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activate") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasSubscriptionMaxedOutOnThisDeviceTypeButDeviceIDMatchesExistingActivation() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.tooManyDevices2

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activate") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password) { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }


    //MARK: - Check
    func test_check_noMatchingTokenInAccount() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token": "foobarbaz",
            "subscription": ["name": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"]
        ]
        let storedSignature = "MQVWTcssklEphlG2Pizak+0B4ehbDqqWo0qm4c47x7mQP6Sp5hVfazEfI2PWE4C0RBieR5Vk2gTR5yjAtj1zz+ytGCKIMSsC/M+By6fViilgJpFC4xaiAJsrtSAV+mKxx0wI0NOJxvvOz5NVxuZqF9kut0wwr1N9rRKP7eu3vOpp5OU6JlBIhTAteRYzVV9/R/aZ8G6qxkaPk5clRGSMQTa/L+brkYzHTt7Lk5W2+amR69H/Yo9ibrUmwHTbFauGcftBqkP38J6kLCuk2Pnu6Q/n/cFcN/IZx+Y75dTQjaWBUjY33xoEi3MKSs6RlJsvUM+3FzP/BMCtPtK2sNGUUQ=="
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        var actualError: NSError?
        self.performAndWaitFor("Wait for error", timeout: 2) { (expectation) in
            self.controller.checkSubscription() { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_check_accountHasMatchingTokenButDeviceIDsDontMatch() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.tooManyDevices2
        let storedPayload: [String: Any] = [
            "response": "active",
            "token": TestData.Tokens.basic,
            "subscription": ["name": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"]
        ]
        let storedSignature = "EKX2xO5nbmSWIsuSH3PfXSyd/Z5OV4OBhfUuh15R2PniIZAsoiAqdE4uLcbEyI6FO1D9Lgf5/AAHMAunXoVZ/BMWi78DCYJbmxXG+eD35E3TigtBAc2hRKV8zewRWM42GqR5IDN79eSveAtvDLr70t5VaH8Lf7om7Irk1j1JCgBEyTvTS2Urql0e7Djdeu6ppTqw91rVBCz+GE6BJ6oAJCPVNjABUDdADr8d2xULbyQMiOFYK9yksabf+rPLDLNXx1rEHXCQudCy7jxJ152caYdC0y+RZ5FlQxuJ7Z53omIPYwuLSqwuWi0KfY6oQDzjZ2/CscVVGeBXPxmcoKG/cQ=="
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        var actualError: NSError?
        self.performAndWaitFor("Wait for error", timeout: 2) { (expectation) in
            self.controller.checkSubscription(){ result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_check_accountHasActivationButSubscriptionExpired() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.basicExpired

        let storedPayload: [String: Any] = [
            "response": "active",
            "token": TestData.Tokens.basicExpired,
            "subscription": ["name": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"]
        ]
        let storedSignature = "qHHftTX9NpI4urBXueVDHClZ0cyT8a8xPJFgV0x3QYZXAghbm8+Kh8mt6J3kHesJhpgSpK5oguNgiCsw2wtPGXg8zPCmu7z+BdlXKd+2e0ZNeQ6FSHjmzINkiHBH7I/FO6WFUGaWAvWxpJfQlwOS+0XlcHqVCVUfvZxyIUqR8+zjS/FIyid68y5U/LgRoPJi1vHUjER2pmSeNzt2dn6SeUbQaFO/bEks5+QfmUWg+Mg7OaM598nDYWvCzK+f9SM6q1vGQjXwv1Gxe53ytPhe7GK/vX+qBrGEQeXVNC6Cfu4+JpkJNe48Awgfbb9YaJB7NGPC1SnIO90VJoZ4KC0j0g=="
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation", timeout: 2) { (expectation) in
            self.controller.checkSubscription() { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertFalse(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertTrue(subscription.hasExpired)
        XCTAssertLessThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasActivationForActiveSubscription() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.basic
        let storedPayload: [String: Any] = [
            "response": "active",
            "token": TestData.Tokens.basic,
            "subscription": ["name": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"]
        ]

        let storedSignature = "EKX2xO5nbmSWIsuSH3PfXSyd/Z5OV4OBhfUuh15R2PniIZAsoiAqdE4uLcbEyI6FO1D9Lgf5/AAHMAunXoVZ/BMWi78DCYJbmxXG+eD35E3TigtBAc2hRKV8zewRWM42GqR5IDN79eSveAtvDLr70t5VaH8Lf7om7Irk1j1JCgBEyTvTS2Urql0e7Djdeu6ppTqw91rVBCz+GE6BJ6oAJCPVNjABUDdADr8d2xULbyQMiOFYK9yksabf+rPLDLNXx1rEHXCQudCy7jxJ152caYdC0y+RZ5FlQxuJ7Z53omIPYwuLSqwuWi0KfY6oQDzjZ2/CscVVGeBXPxmcoKG/cQ=="
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.checkSubscription() { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let response = try XCTUnwrap(actualActivationResponse)
        XCTAssertTrue(response.isActive)
        XCTAssertTrue(response.deviceIsActivated)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertEqual(subscription.renewalStatus, .renew)
        XCTAssertFalse(subscription.hasExpired)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }


    //MARK: - Deactivate
    func test_deactivate_noMatchingTokenInAccount() throws {
        let storedPayload: [String: Any] = [
            "response": "active",
            "token": "foobarbaz",
            "subscription": ["name": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"]
        ]
        let storedSignature = "MQVWTcssklEphlG2Pizak+0B4ehbDqqWo0qm4c47x7mQP6Sp5hVfazEfI2PWE4C0RBieR5Vk2gTR5yjAtj1zz+ytGCKIMSsC/M+By6fViilgJpFC4xaiAJsrtSAV+mKxx0wI0NOJxvvOz5NVxuZqF9kut0wwr1N9rRKP7eu3vOpp5OU6JlBIhTAteRYzVV9/R/aZ8G6qxkaPk5clRGSMQTa/L+brkYzHTt7Lk5W2+amR69H/Yo9ibrUmwHTbFauGcftBqkP38J6kLCuk2Pnu6Q/n/cFcN/IZx+Y75dTQjaWBUjY33xoEi3MKSs6RlJsvUM+3FzP/BMCtPtK2sNGUUQ=="
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        var actualError: NSError?
        self.performAndWaitFor("Wait for error", timeout: 2) { (expectation) in
            self.controller.deactivate() { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_deactivate_accountHasMatchingTokenButDeviceIDsDontMatch() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.tooManyDevices2
        let storedPayload: [String: Any] = [
            "response": "active",
            "token": TestData.Tokens.basic,
            "subscription": ["name": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"]
        ]
        let storedSignature = "EKX2xO5nbmSWIsuSH3PfXSyd/Z5OV4OBhfUuh15R2PniIZAsoiAqdE4uLcbEyI6FO1D9Lgf5/AAHMAunXoVZ/BMWi78DCYJbmxXG+eD35E3TigtBAc2hRKV8zewRWM42GqR5IDN79eSveAtvDLr70t5VaH8Lf7om7Irk1j1JCgBEyTvTS2Urql0e7Djdeu6ppTqw91rVBCz+GE6BJ6oAJCPVNjABUDdADr8d2xULbyQMiOFYK9yksabf+rPLDLNXx1rEHXCQudCy7jxJ152caYdC0y+RZ5FlQxuJ7Z53omIPYwuLSqwuWi0KfY6oQDzjZ2/CscVVGeBXPxmcoKG/cQ=="
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])
        var actualError: NSError?
        self.performAndWaitFor("Wait for error", timeout: 2) { (expectation) in
            self.controller.deactivate() { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_deactivate_successfullyDeactives() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.basic
        let storedPayload: [String: Any] = [
            "response": "active",
            "token": TestData.Tokens.basic,
            "subscription": ["name": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z", "renewalStatus": "renew"]
        ]

        let storedSignature = "EKX2xO5nbmSWIsuSH3PfXSyd/Z5OV4OBhfUuh15R2PniIZAsoiAqdE4uLcbEyI6FO1D9Lgf5/AAHMAunXoVZ/BMWi78DCYJbmxXG+eD35E3TigtBAc2hRKV8zewRWM42GqR5IDN79eSveAtvDLr70t5VaH8Lf7om7Irk1j1JCgBEyTvTS2Urql0e7Djdeu6ppTqw91rVBCz+GE6BJ6oAJCPVNjABUDdADr8d2xULbyQMiOFYK9yksabf+rPLDLNXx1rEHXCQudCy7jxJ152caYdC0y+RZ5FlQxuJ7Z53omIPYwuLSqwuWi0KfY6oQDzjZ2/CscVVGeBXPxmcoKG/cQ=="
        try self.writeLicence(["payload": storedPayload, "signature": storedSignature])

        var actualActivationResponse: ActivationResponse?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.deactivate() { result in
                if case .success(let response) = result {
                    actualActivationResponse = response
                }
                expectation.fulfill()
            }
        }

        let activationResponse = try XCTUnwrap(actualActivationResponse)
        XCTAssertFalse(activationResponse.isActive)
        XCTAssertFalse(activationResponse.deviceIsActivated)
    }
}
