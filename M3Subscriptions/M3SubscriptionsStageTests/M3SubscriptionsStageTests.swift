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
    var mockDelegate: MockSubscriptionDelegate!
    var mockUIDelegate: MockSubscriptionUIDelegate!

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
        print("licenceURL: \(self.licenceURL)")
        self.controller = SubscriptionController(licenceURL: self.licenceURL)

        self.mockDelegate = MockSubscriptionDelegate()
        self.controller.delegate = self.mockDelegate

        self.mockUIDelegate = MockSubscriptionUIDelegate()
        self.controller.uiDelegate = self.mockUIDelegate

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
        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.activate(withEmail: "pilky@mcubedsw.com", password: "password1!")
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.loginFailed.rawValue)
    }

    func test_activate_emptyAccount() throws {
        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.empty, password: TestData.password)
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_activate_accountHasSubscriptionsButNotForApp() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.basic, password: TestData.password)
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noSubscriptionFound.rawValue)
    }

    func test_activate_accountHasSubscriptionForAppButItsExpired() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.basicExpired, password: TestData.password)
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.subscriptionExpired.rawValue)

        let subscription = try XCTUnwrap(error.userInfo[SubscriptionErrorFactory.InfoKeys.subscription] as? Subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertLessThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasActiveSubscriptionForApp() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.basic, password: TestData.password)
        }

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .active)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasTwoSubscriptionsButForDifferentApps() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.multipleApps, password: TestData.password)
        }

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .active)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appAAnnual)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasTwoSubscriptionsForTheSameAppButOneHasExpired() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptionsExpired, password: TestData.password)
        }

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .active)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appAAnnual)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasTwoActiveSubscriptionsForTheSameApp() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        self.performAndWaitFor("Wait for subscription plans") { (expectation) in
            self.mockUIDelegate.showSubscriptionPlansExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptions, password: TestData.password)
        }

        let plans = try XCTUnwrap(self.mockUIDelegate.plansArgument)
        XCTAssertEqual(plans.count, 2)
        XCTAssertTrue(plans.contains(where: { $0.name == TestData.SubscriptionName.appAAnnual}))
        XCTAssertTrue(plans.contains(where: { $0.name == TestData.SubscriptionName.appAMonthly}))
    }

    func test_activate_accountHasTwoActiveSubscriptionsForTheSameAppAndSubscriptionIDProvided() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appA

        self.performAndWaitFor("Wait for subscription plans") { (expectation) in
            self.mockUIDelegate.showSubscriptionPlansExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptions, password: TestData.password)
        }

        let plans = try XCTUnwrap(self.mockUIDelegate.plansArgument)
        let subscriptionPlan = try XCTUnwrap(plans.first(where: { $0.name == TestData.SubscriptionName.appAMonthly }))

        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.multipleSubscriptions, password: TestData.password, subscription: subscriptionPlan)
        }

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .active)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appAMonthly)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasSubscriptionButIsMaxedOutOnDeviceType() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        self.performAndWaitFor("Wait for devices") { (expectation) in
            self.mockUIDelegate.showDevicesExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password)
        }

        let devices = try XCTUnwrap(self.mockUIDelegate.devicesArgument)
        XCTAssertEqual(devices.count, 2)
        XCTAssertTrue(devices.contains(where: { $0.name == TestData.DeviceNames.tooManyDevices1}))
        XCTAssertTrue(devices.contains(where: { $0.name == TestData.DeviceNames.tooManyDevices2}))
    }

    func test_activate_accountHasSubscriptionButIsMaxedOutOnDeviceTypeAndDeactivatingDeviceTokenProvided() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB

        self.performAndWaitFor("Wait for devices") { (expectation) in
            self.mockUIDelegate.showDevicesExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password)
        }

        let devices = try XCTUnwrap(self.mockUIDelegate.devicesArgument)
        let device = try XCTUnwrap(devices.first(where: { $0.name == TestData.DeviceNames.tooManyDevices2 }))

        self.performAndWaitFor("Wait for activate") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password, deactivatingDevice: device)
        }

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .active)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasSubscriptionMaxedOutOnOtherDeviceTypeButNotThisDeviceType() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB
        TEST_OVERRIDES.deviceType = .ipad

        self.performAndWaitFor("Wait for activate") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password)
        }

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .active)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasSubscriptionMaxedOutOnThisDeviceTypeButDeviceIDMatchesExistingActivation() throws {
        TEST_OVERRIDES.bundleID = TestData.BundleIDs.appB
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.tooManyDevices2

        self.performAndWaitFor("Wait for activate") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.activate(withEmail: TestData.Emails.tooManyDevices, password: TestData.password)
        }

        let response = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(response.state, .active)
        XCTAssertNotNil(response.token)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }


    //MARK: - Check
    func test_check_noMatchingTokenInAccount() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "foobarbaz", "subscriptionName": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z"], "signature": "JXTHYF1DoiTDlFFCWEGJe6dXJX5pcTtUdPK4ziq+o22dibxbunYDYkYUMFrEMte8Jr/dqs9eVKIhMKqx65iEth0Y1f61y4V+dukLr1K9cEGciITwsbqKWAPk861FeShpWwdxAYqCuYQ0UeMCPbo3SrW2mQ5Nn3nzH0dmqFhrMAJONS9IiMbqgPkvwMDy/Gn38GafiWZmMUW+0P1ndgSFvLTJMnWsXEe+hLpJA9dKwWBgeXQ8VF4mN7dZwTLkWYSVOJkb4s3WndRrACi7tTgVcSWDhan/lVTM3JovHSKfCx8jzZlG1CZnpmes6GizpGW8TRff+evfZaGulNzhQiuykQ=="])
        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.checkSubscription()
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_check_accountHasMatchingTokenButDeviceIDsDontMatch() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.tooManyDevices2
        try self.writeLicence(["payload": ["response": "active", "token": TestData.Tokens.basic, "subscriptionName": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z"], "signature": "WasVsa3NufBMRwOoEJLYFozKPkDAlhAnnIsNpR3vkRiUcKzHkxAMhdzOwKl2yrrLp0alfaojtXUkDs1Z5xsUCaEyQ5dy+PbGGXe30ZBy9VCC7AuPNntku+40ng3VJU1TpwaIOdKUzaWx6i4G6Y5JFOTqC1FyY4AbMKH7Pemg11VZMWdt+602cTNmJfzbkSPbLxcfLFYUojdoUG9K6b8k11KXGk0ph/oRD0dGz7syUSIXGeHGIQQPKkefR/PCBGz5Q4n2cTb8seOhmf7x4jAdnToFk3l2iwYkdfKwK6QFFyL+mZeD5sCjiuF79ll3x1P1w2vrRg/Yj4KIhoCLo5eWdA=="])
        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.checkSubscription()
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_check_accountHasActivationButSubscriptionExpired() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.basicExpired
        try self.writeLicence(["payload": ["response": "active", "token": TestData.Tokens.basicExpired, "subscriptionName": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z"], "signature":"hdp0NG0XxEv0iJI09HnJiEoPzSPrvguLNs3/xhW/bYS1iaOuqEvOBj6EfKW3QVqnuOugoojT6SdGAz+d0NZ6hrLq5VqoVHCQg+pDjueHEASSJUnnBWma3emCFpNUB7bHb9gV5rmxjEaomx4a0I2oXKC/jtcLcXgguoDa6AqTogW1fdvr1dd/j+yHopMkQNXohVHOWJI9f1OlCxEKd86T5xgk9C2szCmpHSOwnGek6zcQfcSySQ+ouUBXvIjkdOdOT6L0mgMYkAi1+VN1IUpWNxOFaTjSWGopXI8YTtigI/pV6ATUgW9LSaMijr8g06+CQ3n40Ona4/zMLSYbkXkSkw=="])
        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.checkSubscription()
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.subscriptionExpired.rawValue)

        let subscription = try XCTUnwrap(error.userInfo[SubscriptionErrorFactory.InfoKeys.subscription] as? Subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertLessThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }

    func test_activate_accountHasActivationForActiveSubscription() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.basic
        try self.writeLicence(["payload": ["response": "active", "token": TestData.Tokens.basic, "subscriptionName": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z"], "signature": "WasVsa3NufBMRwOoEJLYFozKPkDAlhAnnIsNpR3vkRiUcKzHkxAMhdzOwKl2yrrLp0alfaojtXUkDs1Z5xsUCaEyQ5dy+PbGGXe30ZBy9VCC7AuPNntku+40ng3VJU1TpwaIOdKUzaWx6i4G6Y5JFOTqC1FyY4AbMKH7Pemg11VZMWdt+602cTNmJfzbkSPbLxcfLFYUojdoUG9K6b8k11KXGk0ph/oRD0dGz7syUSIXGeHGIQQPKkefR/PCBGz5Q4n2cTb8seOhmf7x4jAdnToFk3l2iwYkdfKwK6QFFyL+mZeD5sCjiuF79ll3x1P1w2vrRg/Yj4KIhoCLo5eWdA=="])
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.checkSubscription()
        }

        let activationResponse = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(activationResponse.state, .active)
        XCTAssertNotNil(activationResponse.token)

        let subscription = try XCTUnwrap(activationResponse.subscription)
        XCTAssertEqual(subscription.name, TestData.SubscriptionName.appBAnnual)
        XCTAssertGreaterThan(subscription.expirationDate.timeIntervalSinceReferenceDate, Date().timeIntervalSinceReferenceDate)
    }


    //MARK: - Deactivate
    func test_deactivate_noMatchingTokenInAccount() throws {
        try self.writeLicence(["payload": ["response": "active", "token": "foobarbaz", "subscriptionName": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z"], "signature": "JXTHYF1DoiTDlFFCWEGJe6dXJX5pcTtUdPK4ziq+o22dibxbunYDYkYUMFrEMte8Jr/dqs9eVKIhMKqx65iEth0Y1f61y4V+dukLr1K9cEGciITwsbqKWAPk861FeShpWwdxAYqCuYQ0UeMCPbo3SrW2mQ5Nn3nzH0dmqFhrMAJONS9IiMbqgPkvwMDy/Gn38GafiWZmMUW+0P1ndgSFvLTJMnWsXEe+hLpJA9dKwWBgeXQ8VF4mN7dZwTLkWYSVOJkb4s3WndRrACi7tTgVcSWDhan/lVTM3JovHSKfCx8jzZlG1CZnpmes6GizpGW8TRff+evfZaGulNzhQiuykQ=="])
        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.deactivate()
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_deactivate_accountHasMatchingTokenButDeviceIDsDontMatch() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.tooManyDevices2
        try self.writeLicence(["payload": ["response": "active", "token": TestData.Tokens.basic, "subscriptionName": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z"], "signature": "WasVsa3NufBMRwOoEJLYFozKPkDAlhAnnIsNpR3vkRiUcKzHkxAMhdzOwKl2yrrLp0alfaojtXUkDs1Z5xsUCaEyQ5dy+PbGGXe30ZBy9VCC7AuPNntku+40ng3VJU1TpwaIOdKUzaWx6i4G6Y5JFOTqC1FyY4AbMKH7Pemg11VZMWdt+602cTNmJfzbkSPbLxcfLFYUojdoUG9K6b8k11KXGk0ph/oRD0dGz7syUSIXGeHGIQQPKkefR/PCBGz5Q4n2cTb8seOhmf7x4jAdnToFk3l2iwYkdfKwK6QFFyL+mZeD5sCjiuF79ll3x1P1w2vrRg/Yj4KIhoCLo5eWdA=="])
        self.performAndWaitFor("Wait for error") { (expectation) in
            self.mockDelegate.errorExpectation = expectation
            self.controller.deactivate()
        }

        let error = try XCTUnwrap(self.mockDelegate.error)
        XCTAssertEqual(error.code, SubscriptionErrorCodes.noDeviceFound.rawValue)
    }

    func test_deactivate_successfullyDeactives() throws {
        TEST_OVERRIDES.deviceID = TestData.DeviceIDs.basic
        try self.writeLicence(["payload": ["response": "active", "token": TestData.Tokens.basic, "subscriptionName": TestData.SubscriptionName.appBAnnual, "expirationDate": "2035-01-01T00:00:00Z"], "signature": "WasVsa3NufBMRwOoEJLYFozKPkDAlhAnnIsNpR3vkRiUcKzHkxAMhdzOwKl2yrrLp0alfaojtXUkDs1Z5xsUCaEyQ5dy+PbGGXe30ZBy9VCC7AuPNntku+40ng3VJU1TpwaIOdKUzaWx6i4G6Y5JFOTqC1FyY4AbMKH7Pemg11VZMWdt+602cTNmJfzbkSPbLxcfLFYUojdoUG9K6b8k11KXGk0ph/oRD0dGz7syUSIXGeHGIQQPKkefR/PCBGz5Q4n2cTb8seOhmf7x4jAdnToFk3l2iwYkdfKwK6QFFyL+mZeD5sCjiuF79ll3x1P1w2vrRg/Yj4KIhoCLo5eWdA=="])
        self.performAndWaitFor("Wait for activation") { (expectation) in
            self.mockDelegate.activationExpectation = expectation
            self.controller.deactivate()
        }

        let activationResponse = try XCTUnwrap(self.mockDelegate.activationResponse)
        XCTAssertEqual(activationResponse.state, .deactivated)
    }
}


class MockSubscriptionDelegate: SubscriptionControllerDelegate {
    var activationResponse: ActivationResponse?
    var activationExpectation: XCTestExpectation?
    func didChangeSubscription(_ info: ActivationResponse, in controller: SubscriptionController) {
        self.activationResponse = info
        self.activationExpectation?.fulfill()
    }

    var error: NSError?
    var errorExpectation: XCTestExpectation?
    func didEncounterError(_ error: NSError, in controller: SubscriptionController) {
        self.error = error
        self.errorExpectation?.fulfill()
    }
}


class MockSubscriptionUIDelegate: SubscriptionControllerUIDelegate {
    var plansArgument: [SubscriptionPlan]?
    var showSubscriptionPlansExpectation: XCTestExpectation?
    func showSubscriptionPlans(_ plans: [SubscriptionPlan], for controller: SubscriptionController) {
        self.plansArgument = plans
        self.showSubscriptionPlansExpectation?.fulfill()
    }

    var devicesArgument: [SubscriptionDevice]?
    var showDevicesExpectation: XCTestExpectation?
    func showDevicesToDeactivate(_ devices: [SubscriptionDevice], for controller: SubscriptionController) {
        self.devicesArgument = devices
        self.showDevicesExpectation?.fulfill()
    }
}
