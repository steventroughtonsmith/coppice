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

        var actualError: NSError?
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.controller.activate(withEmail: TestData.Emails.basicExpired, password: TestData.password) { result in
                if case .failure(let error) = result {
                    actualError = error
                }
                expectation.fulfill()
            }
        }

        let error = try XCTUnwrap(actualError)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.subscriptionExpired.rawValue)

        let subscription = try XCTUnwrap(error.userInfo[SubscriptionErrorFactory.InfoKeys.subscription] as? Subscription)
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
        let storedSignature = "Xt5EWbwKITWOegS+Sfqsv1EdgZ//9fkL1+8WXaEWbWjL6LzrpOShF0CBxVr/A0FLNqFXacnHmwFKANR6XiPV8q/t8ZnRvWoEaP4nGmheKFfw+uY6myQUZY4wYg7R2Yc7Zr7q+ushJ8WRhL0pNnie8tq9UXTJp+EwTjRDLU+BsJvI5ccvGp34MJ10BVDKo+/cjRche8gdhBM/jIppaCBT5fOZMyFl20K9bzSQFIpYROsK0SUIacvq3SZB3RHOFyuYoqIzl7C35pb14XpS4L0w+236HAr0DPuH0fca9+wp4cmUj0FdZ+vOnVt3CIW6z3qviI6OGtWrUUJVgeKKNKzfeQ=="
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
        let storedSignature = "jmYgnt5w2lDqcWbQsgTtXmE6BXNcfQV+lTBrtvYRVpPanOlZ3/yse6WToa4lx/xO0/f0kpx8rsXcm7ir9RAgY4sZbh8kAhhEsj+JLZ5dB2lx2TvfuMXO0bcbuIIBpSEDVQwD4o8pMCtlCJ2EKGDxZktTEnsCS6uVQxH7Hq2geaSmkdlyz4XYC/s2zY+OFl/tvdOLYazy057PCZ8odL6c4dIUcao1QejbvXEOfILrVGQMrhtm4lSRaY0LWAyMIbpaJlS3MYzmFoV3BViBb8yX1tUsokcDZDfqTCWxsFwxxwm6V18waLrZM2yep3lK+l2bfNyVPxgnPQosvgbAWR6t6g=="
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
        let storedSignature = "e8gCPoA00KISi07ByKTa8sze80oZJzEP4RmfF8gMi2OsLon/4dus44dOIaFz6NwCyvvd/JG+aZnrA7pYJmpTIYzKwudcb6Ha3qbe0rFwch64ndcUqR3HleRRdmgF459OHgaeXwvCeOxVX+OcQzpai3z3YI1lrtSIPntakIXan/q+TNDTBeS9sF+zUq1qsZCn77AJJ2qK4g+HX2niH97FlMk8eLfcjuve6RMLlK0fFQf8W5J9a4GlVnsNm+jzmeNEVMr4yXb8cTP/Y974tjFyYqx/NoYQcNSwDh1YkndWSWtNZSXsjhJp9cVZr+UCIDjJrkNQW6TdC2rHUbZX2j3zHQ=="
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
        let storedSignature = "jmYgnt5w2lDqcWbQsgTtXmE6BXNcfQV+lTBrtvYRVpPanOlZ3/yse6WToa4lx/xO0/f0kpx8rsXcm7ir9RAgY4sZbh8kAhhEsj+JLZ5dB2lx2TvfuMXO0bcbuIIBpSEDVQwD4o8pMCtlCJ2EKGDxZktTEnsCS6uVQxH7Hq2geaSmkdlyz4XYC/s2zY+OFl/tvdOLYazy057PCZ8odL6c4dIUcao1QejbvXEOfILrVGQMrhtm4lSRaY0LWAyMIbpaJlS3MYzmFoV3BViBb8yX1tUsokcDZDfqTCWxsFwxxwm6V18waLrZM2yep3lK+l2bfNyVPxgnPQosvgbAWR6t6g=="
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
        let storedSignature = "Xt5EWbwKITWOegS+Sfqsv1EdgZ//9fkL1+8WXaEWbWjL6LzrpOShF0CBxVr/A0FLNqFXacnHmwFKANR6XiPV8q/t8ZnRvWoEaP4nGmheKFfw+uY6myQUZY4wYg7R2Yc7Zr7q+ushJ8WRhL0pNnie8tq9UXTJp+EwTjRDLU+BsJvI5ccvGp34MJ10BVDKo+/cjRche8gdhBM/jIppaCBT5fOZMyFl20K9bzSQFIpYROsK0SUIacvq3SZB3RHOFyuYoqIzl7C35pb14XpS4L0w+236HAr0DPuH0fca9+wp4cmUj0FdZ+vOnVt3CIW6z3qviI6OGtWrUUJVgeKKNKzfeQ=="
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
        let storedSignature = "jmYgnt5w2lDqcWbQsgTtXmE6BXNcfQV+lTBrtvYRVpPanOlZ3/yse6WToa4lx/xO0/f0kpx8rsXcm7ir9RAgY4sZbh8kAhhEsj+JLZ5dB2lx2TvfuMXO0bcbuIIBpSEDVQwD4o8pMCtlCJ2EKGDxZktTEnsCS6uVQxH7Hq2geaSmkdlyz4XYC/s2zY+OFl/tvdOLYazy057PCZ8odL6c4dIUcao1QejbvXEOfILrVGQMrhtm4lSRaY0LWAyMIbpaJlS3MYzmFoV3BViBb8yX1tUsokcDZDfqTCWxsFwxxwm6V18waLrZM2yep3lK+l2bfNyVPxgnPQosvgbAWR6t6g=="
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

        let storedSignature = "jmYgnt5w2lDqcWbQsgTtXmE6BXNcfQV+lTBrtvYRVpPanOlZ3/yse6WToa4lx/xO0/f0kpx8rsXcm7ir9RAgY4sZbh8kAhhEsj+JLZ5dB2lx2TvfuMXO0bcbuIIBpSEDVQwD4o8pMCtlCJ2EKGDxZktTEnsCS6uVQxH7Hq2geaSmkdlyz4XYC/s2zY+OFl/tvdOLYazy057PCZ8odL6c4dIUcao1QejbvXEOfILrVGQMrhtm4lSRaY0LWAyMIbpaJlS3MYzmFoV3BViBb8yX1tUsokcDZDfqTCWxsFwxxwm6V18waLrZM2yep3lK+l2bfNyVPxgnPQosvgbAWR6t6g=="
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
