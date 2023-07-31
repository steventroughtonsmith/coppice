//
//  V2ControllerTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 30/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

@testable import M3Subscriptions
import XCTest

final class V2ControllerTests: APITestCase {
    var controller: API.V2.Controller!

    var mockAdapter: MockAPIAdapterV2!
    var licenceURL: URL!
    var activationURL: URL!
    var fakeKeychain: FakeKeychain!

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.licenceURL = try self.temporaryTestDirectory().appendingPathComponent("Licence.coppicelicence")
        self.activationURL = try self.temporaryTestDirectory().appendingPathComponent("Activation")
        self.mockAdapter = MockAPIAdapterV2()
        self.fakeKeychain = FakeKeychain()

        self.fakeKeychain.token = "mytoken123"

        self.controller = API.V2.Controller(licenceURL: self.licenceURL,
                                            activationURL: self.activationURL,
                                            adapter: self.mockAdapter,
                                            keychain: self.fakeKeychain)
    }

    //MARK: - init()
    func test_init_setsActivationSourceToNoneIfNoLicenceOrActivationFile() async throws {
        let controller = API.V2.Controller(licenceURL: self.licenceURL, activationURL: self.activationURL)

        guard case .none = controller.activationSource else {
            XCTFail("Activation source not .none")
            return
        }
    }

    func test_init_setsActivationSourceToNoneIfOnlyLicenceFileExistsButIsInvalid() async throws {
        let licencePayload: [String: Any] = [
            "licenceID": "1234567890",
            "subscriber": "Pilky",
            "subscriptionID": "abcdefghijklm",
            "subscriptionName": "Annual Subscription",
            "expirationTimestamp": 876_543_210,
        ]

        let data = try JSONSerialization.data(withJSONObject: [
            "payload": licencePayload,
            "signature": "invalidSignature",
        ])

        try data.write(to: self.licenceURL)

        let controller = API.V2.Controller(licenceURL: self.licenceURL, activationURL: self.activationURL)
        guard case .none = controller.activationSource else {
            XCTFail("Activation source not .none")
            return
        }
    }

    func test_init_setsActivationSourceToLicenceIfOnlyLicenceFileExistsAndIsValid() async throws {
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

        try data.write(to: self.licenceURL)

        let controller = API.V2.Controller(licenceURL: self.licenceURL, activationURL: self.activationURL)
        guard case .licence(let actualLicence) = controller.activationSource else {
            XCTFail("Activation source not .licence: \(controller.activationSource)")
            return
        }

        XCTAssertEqual(actualLicence.licenceID, "1234567890")
        XCTAssertEqual(actualLicence.subscriber, "Pilky")
        XCTAssertEqual(actualLicence.subscription.id, "abcdefghijklm")
        XCTAssertEqual(actualLicence.subscription.name, "Annual Subscription")
        XCTAssertEqual(actualLicence.subscription.expirationTimestamp, 876_543_210)
    }

    func test_init_setsActivationSourceToNoneIfOnlyActivationFileExistsButIsInvalid() async throws {
        var activationData = self.standardActivationData()
        activationData.signature = "invalidsignature"
        try activationData.write(to: self.activationURL)

        let controller = API.V2.Controller(licenceURL: self.licenceURL, activationURL: self.activationURL)
        guard case .none = controller.activationSource else {
            XCTFail("Activation source not .none")
            return
        }
    }

    func test_init_setsActivationSourceToWebsiteIfOnlyActivationFileExistsAndIsValid() async throws {
        let activationData = self.standardActivationData()
        try activationData.write(to: self.activationURL)

        let controller = API.V2.Controller(licenceURL: self.licenceURL, activationURL: self.activationURL)
        guard case .website(let activation) = controller.activationSource else {
            XCTFail("Activation source not .website")
            return
        }

        self.validateAgainstStandardActivation(activation)
    }

    func test_init_setsActivationSourceToLicenceIfBothFilesExistButOnlyLicenceIsValid() async throws {
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

        try data.write(to: self.licenceURL)

        var activationData = self.standardActivationData()
        activationData.signature = "invalidsignature"
        try activationData.write(to: self.activationURL)

        let controller = API.V2.Controller(licenceURL: self.licenceURL, activationURL: self.activationURL)
        guard case .licence(let actualLicence) = controller.activationSource else {
            XCTFail("Activation source not .licence: \(controller.activationSource)")
            return
        }

        XCTAssertEqual(actualLicence.licenceID, "1234567890")
        XCTAssertEqual(actualLicence.subscriber, "Pilky")
        XCTAssertEqual(actualLicence.subscription.id, "abcdefghijklm")
        XCTAssertEqual(actualLicence.subscription.name, "Annual Subscription")
        XCTAssertEqual(actualLicence.subscription.expirationTimestamp, 876_543_210)
    }

    func test_init_setsActivationSourceToWebsiteIfBothFilesExistAndAreValid() async throws {
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

        try data.write(to: self.licenceURL)

        let activationData = self.standardActivationData()
        try activationData.write(to: self.activationURL)

        let controller = API.V2.Controller(licenceURL: self.licenceURL, activationURL: self.activationURL)
        guard case .website(let activation) = controller.activationSource else {
            XCTFail("Activation source not .website")
            return
        }

        self.validateAgainstStandardActivation(activation)
    }


    //MARK: - login(email:password)
    func test_login_tellsAdapterToCallLoginAPIWithSuppliedArgumentsAndDefaultDeviceName() async throws {
        let loginMock = self.mockAdapter.loginMock
        loginMock.returnValue = APIData.loggedIn(token: "foo")
        try await self.controller.login(email: "foo@bar.com", password: "123abc")

        XCTAssertTrue(loginMock.wasCalled)
        XCTAssertEqual(loginMock.arguments.first?.0, "foo@bar.com")
        XCTAssertEqual(loginMock.arguments.first?.1, "123abc")
        XCTAssertEqual(loginMock.arguments.first?.2, Device.shared.defaultName)
    }

    func test_login_throwsIfAdapterThrows() async throws {
        self.mockAdapter.loginMock.error = API.V2.Error.noDeviceFound //Not actual error we'd get

        await XCTAssertThrowsErrorAsync(try await self.controller.login(email: "foo@bar.com", password: "123abc"))
    }

    func test_login_throwsLoginFailedIfResponseIsNotLoggedIn() async throws {
        self.mockAdapter.loginMock.returnValue = APIData.deactivated() //Not actual value we'd get
        await XCTAssertThrowsErrorAsync(try await self.controller.login(email: "foo@bar.com", password: "123abc")) { error in
            XCTAssertEqualsV2Error(error, .loginFailed)
        }
    }

    func test_login_throwsLoginFailedIfTokenMissing() async throws {
        self.mockAdapter.loginMock.returnValue = APIData.loggedIn(token: nil)
        await XCTAssertThrowsErrorAsync(try await self.controller.login(email: "foo@bar.com", password: "123abc")) { error in
            XCTAssertEqualsV2Error(error, .loginFailed)
        }
    }

    func test_login_addsTokenToKeychain() async throws {
        self.mockAdapter.loginMock.returnValue = APIData.loggedIn(token: "mytoken")
        try await self.controller.login(email: "foo@bar.com", password: "123abc")
        XCTAssertEqual(self.fakeKeychain.token, "mytoken")
    }


    //MARK: - logout()
    func test_logout_tellsAdapterToLogout() async throws {
        let logoutMock = self.mockAdapter.logoutMock
        logoutMock.returnValue = APIData.loggedOut()
        try await self.controller.logout()

        XCTAssertTrue(logoutMock.wasCalled)
    }

    func test_logout_throwsIfAdapterThrows() async throws {
        self.mockAdapter.logoutMock.error = API.V2.Error.tooManyDevices //Not actual error we'd get

        await XCTAssertThrowsErrorAsync(try await self.controller.logout())
    }

    func test_logout_throwsInvalidResponseIfResponseNotLoggedOut() async throws {
        self.mockAdapter.logoutMock.returnValue = APIData.deactivated() //Not actual value we'd get
        await XCTAssertThrowsErrorAsync(try await self.controller.logout()) { error in
            XCTAssertEqualsV2Error(error, .invalidResponse)
        }
    }

    func test_logout_removesTokenFromKeychain() async throws {
        self.fakeKeychain.token = "foobarbaz"

        self.mockAdapter.logoutMock.returnValue = APIData.loggedOut()
        try await self.controller.logout()

        XCTAssertNil(self.fakeKeychain.token)
    }


    //MARK: - saveLicence(_:)
    func test_saveLicence_writesLicenceToLicenceURL() async throws {
        _ = try self.saveLicence()

        XCTAssertTrue(FileManager.default.fileExists(atPath: self.licenceURL.path))
    }

    func test_saveLicence_setsActivationSourceToLicence() async throws {
        let licence = try self.saveLicence()

        guard case .licence(let actualLicence) = self.controller.activationSource else {
            XCTFail("Activation soruce is not licence")
            return
        }

        XCTAssertEqual(licence, actualLicence)
    }


    //MARK: - activate(subscriptionID:)
    func test_activate_tellsAdapterToUseTokenAuthentication() async throws {
        self.mockAdapter.activateMock.returnValue = self.standardActivationData()
        try await self.controller.activate()

        try self.validateTokenAuthentication()
    }

    func test_activate_tellsAdapterToUseLicenceAuthentication() async throws {
        self.fakeKeychain.token = nil
        let licence = try self.saveLicence()

        self.mockAdapter.activateMock.returnValue = self.standardActivationData()
        try await self.controller.activate()

        try self.validateLicenceAuthentication(licence)
    }

    func test_activate_tellsAdapterToCallActivateWithSharedDeviceAndSuppliedSubscription() async throws {
        self.fakeKeychain.token = "mytoken123"
        let activateMock = self.mockAdapter.activateMock
        activateMock.returnValue = APIData.active(activationID: "", deviceName: "", subscription: ("", 0, "", ""))
        try await self.controller.activate(subscriptionID: "foobarbaz")

        XCTAssertTrue(activateMock.wasCalled)
        let arguments = try XCTUnwrap(activateMock.arguments.first)
        XCTAssertEqual(arguments.0.id, Device.shared.id)
        XCTAssertEqual(arguments.0.appVersion, Device.shared.appVersion)
        XCTAssertEqual(arguments.0.type, .mac)
        XCTAssertEqual(arguments.1, "foobarbaz")
    }

    func test_activate_throwsNotActivatedIfResponseIsNotActive() async throws {
        self.mockAdapter.activateMock.returnValue = APIData.deactivated()
        await XCTAssertThrowsErrorAsync(try await self.controller.activate()) { error in
            XCTAssertEqualsV2Error(error, .notActivated)
        }
    }

    func test_activate_writesActivationToActivationURL() async throws {
        self.mockAdapter.activateMock.returnValue = self.standardActivationData()
        try await self.controller.activate()

        XCTAssertTrue(FileManager.default.fileExists(atPath: self.activationURL.path))

        let json = try JSONSerialization.jsonObject(with: try Data(contentsOf: self.activationURL)) as? [String: Any]
        let activation = try API.V2.Activation(apiData: try XCTUnwrap(APIData(json: try XCTUnwrap(json))))
        self.validateAgainstStandardActivation(activation)
    }

    func test_activate_setsActivationSourceToWebsite() async throws {
        self.mockAdapter.activateMock.returnValue = self.standardActivationData()
        try await self.controller.activate()

        guard case .website(let activation) = self.controller.activationSource else {
            XCTFail("Activation source is not website")
            return
        }

        self.validateAgainstStandardActivation(activation)
    }


    //MARK: - check()
    func test_check_throwsNotActivatedIfSourceIsNotWebsite() async throws {
        self.controller.setActivationSource(.none)
        await XCTAssertThrowsErrorAsync(try await self.controller.check()) { error in
            XCTAssertEqualsV2Error(error, .notActivated)
        }
    }

    func test_check_tellsAdapterToUseTokenAuthentication() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.checkMock.returnValue = self.standardActivationData()
        try await self.controller.check()

        try self.validateTokenAuthentication()
    }

    func test_check_tellsAdapterToUseLicenceAuthentication() async throws {
        self.fakeKeychain.token = nil
        let licence = try self.saveLicence()
        self.controller.setActivationSource(.website(try self.standardActivation()))

        self.mockAdapter.checkMock.returnValue = self.standardActivationData()
        try await self.controller.check()

        try self.validateLicenceAuthentication(licence)
    }

	func test_check_tellsAdapterToCallCheckMethodWithActivationIDAndSharedDevice() async throws {
        let activation = try self.standardActivation()
        self.controller.setActivationSource(.website(activation))

        self.mockAdapter.checkMock.returnValue = self.standardActivationData()
        try await self.controller.check()

        XCTAssertTrue(self.mockAdapter.checkMock.wasCalled)
        let arguments = try XCTUnwrap(self.mockAdapter.checkMock.arguments.first)
        XCTAssertEqual(arguments.0, activation.activationID)
        XCTAssertEqual(arguments.1.id, Device.shared.id)
        XCTAssertEqual(arguments.1.appVersion, Device.shared.appVersion)
        XCTAssertEqual(arguments.1.type, .mac)
    }

    func test_check_throwsNotActivatedIfResponseIsNotActive() async throws {
        let activation = try self.standardActivation()
        self.controller.setActivationSource(.website(activation))

        self.mockAdapter.checkMock.returnValue = APIData.noDeviceFound()
        await XCTAssertThrowsErrorAsync(try await self.controller.check()) { error in
            XCTAssertEqualsV2Error(error, .notActivated)
        }
    }

    func test_check_writesActivationToActivationURL() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))

        self.mockAdapter.checkMock.returnValue = APIData.active(activationID: "123456",
                                                                deviceName: "My New Machine",
                                                                subscription: ("abcdef", 976_543_210, "Annual Subscription", "cancelled"))

        try await self.controller.check()

        XCTAssertTrue(FileManager.default.fileExists(atPath: self.activationURL.path))

        let json = try JSONSerialization.jsonObject(with: try Data(contentsOf: self.activationURL)) as? [String: Any]
        let activation = try API.V2.Activation(apiData: try XCTUnwrap(APIData(json: try XCTUnwrap(json))))
        XCTAssertEqual(activation.activationID, "123456")
        XCTAssertEqual(activation.deviceName, "My New Machine")
        XCTAssertEqual(activation.subscription.id, "abcdef")
        XCTAssertEqual(activation.subscription.expirationTimestamp, 976_543_210)
        XCTAssertEqual(activation.subscription.name, "Annual Subscription")
        XCTAssertEqual(activation.subscription.renewalStatus, .cancelled)
    }

    func test_check_setsActivationSourceToWebsiteWithUpdatedActivation() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))

        self.mockAdapter.checkMock.returnValue = APIData.active(activationID: "123456",
                                                                deviceName: "My New Machine",
                                                                subscription: ("abcdef", 976_543_210, "Annual Subscription", "cancelled"))

        try await self.controller.check()

        guard case .website(let activation) = self.controller.activationSource else {
            XCTFail("Activation source is not website")
            return
        }

        XCTAssertEqual(activation.activationID, "123456")
        XCTAssertEqual(activation.deviceName, "My New Machine")
        XCTAssertEqual(activation.subscription.id, "abcdef")
        XCTAssertEqual(activation.subscription.expirationTimestamp, 976_543_210)
        XCTAssertEqual(activation.subscription.name, "Annual Subscription")
        XCTAssertEqual(activation.subscription.renewalStatus, .cancelled)
    }


    //MARK: - listSubscriptions()
    func test_listSubscriptions_tellsAdapterToUseTokenAuthentication() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listSubscriptionsMock.returnValue = APIData.subscriptions([])
        _ = try await self.controller.listSubscriptions()

        try self.validateTokenAuthentication()
    }

    func test_listSubscriptions_throwsInvalidAuthErrorIfUsingLicenceAuthentication() async throws {
        self.fakeKeychain.token = nil
        _ = try self.saveLicence()
        self.controller.setActivationSource(.website(try self.standardActivation()))

        self.mockAdapter.listSubscriptionsMock.returnValue = APIData.subscriptions([])
        await XCTAssertThrowsErrorAsync(try await self.controller.listSubscriptions()) { error in
            XCTAssertEqualsV2Error(error, .invalidAuthenticationMethod)
        }
    }

	func test_listSubscriptions_tellsAdapterToCallListSubscriptionWithAppBundleID() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listSubscriptionsMock.returnValue = APIData.subscriptions([])
        _ = try await self.controller.listSubscriptions()

        XCTAssertTrue(self.mockAdapter.listSubscriptionsMock.wasCalled)

        XCTAssertEqual(self.mockAdapter.listSubscriptionsMock.arguments.first, Bundle.main.bundleIdentifier)
    }

    func test_listSubscriptions_throwsInvalidResponseIfResponseIsNotSuccess() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listSubscriptionsMock.returnValue = APIData.deactivated()
        await XCTAssertThrowsErrorAsync(try await self.controller.listSubscriptions()) { error in
            XCTAssertEqualsV2Error(error, .invalidResponse)
        }
    }

    func test_listSubscriptions_throwsInvalidResponseIfPayloadMissingSubscription() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listSubscriptionsMock.returnValue = APIData.subscriptions(nil)
        await XCTAssertThrowsErrorAsync(try await self.controller.listSubscriptions()) { error in
            XCTAssertEqualsV2Error(error, .invalidResponse)
        }
    }

    func test_listSubscipitions_returnSubscriptionObjects() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listSubscriptionsMock.returnValue = APIData.subscriptions([
            ("1234", 876_543_210, "Annual Subscription", "cancelled", 4, 3),
            ("9876", 976_543_210, "Free Subscription", "renew", 5, 2),
        ])
        let subscriptions = try await self.controller.listSubscriptions()

        let sub1 = try XCTUnwrap(subscriptions.first)
        XCTAssertEqual(sub1.id, "1234")
        XCTAssertEqual(sub1.expirationTimestamp, 876_543_210)
        XCTAssertEqual(sub1.name, "Annual Subscription")
        XCTAssertEqual(sub1.renewalStatus, .cancelled)
        XCTAssertEqual(sub1.maxDeviceCount, 4)
        XCTAssertEqual(sub1.currentDeviceCount, 3)

        let sub2 = try XCTUnwrap(subscriptions.last)
        XCTAssertEqual(sub2.id, "9876")
        XCTAssertEqual(sub2.expirationTimestamp, 976_543_210)
        XCTAssertEqual(sub2.name, "Free Subscription")
        XCTAssertEqual(sub2.renewalStatus, .renew)
        XCTAssertEqual(sub2.maxDeviceCount, 5)
        XCTAssertEqual(sub2.currentDeviceCount, 2)
    }


    //MARK: - listDevices(subscriptionID:)
    func test_listDevices_tellsAdapterToUseTokenAuthentication() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listDevicesMock.returnValue = APIData.devices([])
        _ = try await self.controller.listDevices(subscriptionID: "Sub1")

        try self.validateTokenAuthentication()
    }

    func test_listDevices_tellsAdapterToUseLicenceAuthentication() async throws {
        self.fakeKeychain.token = nil
        let licence = try self.saveLicence()
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listDevicesMock.returnValue = APIData.devices([])
        _ = try await self.controller.listDevices(subscriptionID: "Sub1")

        try self.validateLicenceAuthentication(licence)
    }

	func test_listDevices_tellsAdapterToCallListDevicesWithSharedDeviceAndSubscription() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listDevicesMock.returnValue = APIData.devices([])
        _ = try await self.controller.listDevices(subscriptionID: "SubABC")

        XCTAssertTrue(self.mockAdapter.listDevicesMock.wasCalled)

        let arguments = try XCTUnwrap(self.mockAdapter.listDevicesMock.arguments.first)
        XCTAssertEqual(arguments.0, "SubABC")
        XCTAssertEqual(arguments.1.id, Device.shared.id)
        XCTAssertEqual(arguments.1.appVersion, Device.shared.appVersion)
        XCTAssertEqual(arguments.1.type, .mac)
    }

    func test_listDevices_throwsInvalidResponseIfResponseIsNotSuccess() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listDevicesMock.returnValue = APIData.deactivated()
        await XCTAssertThrowsErrorAsync(try await self.controller.listDevices(subscriptionID: "Sub1")) { error in
            XCTAssertEqualsV2Error(error, .invalidResponse)
        }
    }

    func test_listDevices_throwsInvalidResponseIfPayloadMissingDevices() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listDevicesMock.returnValue = APIData.devices(nil)
        await XCTAssertThrowsErrorAsync(try await self.controller.listDevices(subscriptionID: "Sub1")) { error in
            XCTAssertEqualsV2Error(error, .invalidResponse)
        }
    }

    func test_listDevices_returnsActivatedDeviceObjects() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.listDevicesMock.returnValue = APIData.devices([
            ("device1", 987_654, "My Machine", false),
            ("device2", 187_654_312, "My New Machine", true),
        ])
        let devices = try await self.controller.listDevices(subscriptionID: "Sub1")
        XCTAssertEqual(devices.count, 2)

        let device1 = try XCTUnwrap(devices.first)
        XCTAssertEqual(device1.id, "device1")
        XCTAssertEqual(device1.timestamp, 987_654)
        XCTAssertEqual(device1.deviceName, "My Machine")
        XCTAssertEqual(device1.isCurrent, false)

        let device2 = try XCTUnwrap(devices.last)
        XCTAssertEqual(device2.id, "device2")
        XCTAssertEqual(device2.timestamp, 187_654_312)
        XCTAssertEqual(device2.deviceName, "My New Machine")
        XCTAssertEqual(device2.isCurrent, true)
    }


    //MARK: - renameDevice(to:)
    func test_renameDevice_throwsNotActivatedIfActivationSourceIsNotWebsite() async throws {
        self.controller.setActivationSource(.none)
        await XCTAssertThrowsErrorAsync(try await self.controller.renameDevice(to: "My Awesome Device")) { error in
            XCTAssertEqualsV2Error(error, .notActivated)
        }
    }

    func test_renameDevice_tellsAdapterToUseTokenAuthentication() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.renameDeviceMock.returnValue = self.standardActivationData()
        try await self.controller.renameDevice(to: "My Awesome Device")

        try self.validateTokenAuthentication()
    }

    func test_renameDevice_throwsInvalidAuthErrorIfUsingLicenceAuthentication() async throws {
        self.fakeKeychain.token = nil
        _ = try self.saveLicence()
        self.controller.setActivationSource(.website(try self.standardActivation()))

        self.mockAdapter.renameDeviceMock.returnValue = APIData.subscriptions([])
        await XCTAssertThrowsErrorAsync(try await self.controller.renameDevice(to: "My Awesome Device")) { error in
            XCTAssertEqualsV2Error(error, .invalidAuthenticationMethod)
        }
    }

	func test_rename_tellsAdapterToCallRenameDeviceWithActivationIDAndSuppliedName() async throws {
        let activation = try self.standardActivation()
        self.controller.setActivationSource(.website(activation))
        self.mockAdapter.renameDeviceMock.returnValue = self.standardActivationData()
        try await self.controller.renameDevice(to: "My Awesome Device")

        XCTAssertTrue(self.mockAdapter.renameDeviceMock.wasCalled)
        let arguments = try XCTUnwrap(self.mockAdapter.renameDeviceMock.arguments.first)
        XCTAssertEqual(arguments.0, activation.activationID)
        XCTAssertEqual(arguments.1, "My Awesome Device")
    }

    func test_renameDevice_throwsNoActivatedIfResponseIsNotActive() async throws {
        let activation = try self.standardActivation()
        self.controller.setActivationSource(.website(activation))

        self.mockAdapter.renameDeviceMock.returnValue = APIData.noDeviceFound()
        await XCTAssertThrowsErrorAsync(try await self.controller.renameDevice(to: "My Awesome Device")) { error in
            XCTAssertEqualsV2Error(error, .notActivated)
        }
    }

    func test_rename_writesActivationToActivationURL() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))

        self.mockAdapter.renameDeviceMock.returnValue = APIData.active(activationID: "123456",
                                                                       deviceName: "My Awesome Device",
                                                                       subscription: ("abcdef", 976_543_210, "Annual Subscription", "cancelled"))

        try await self.controller.renameDevice(to: "My Awesome Device")

        XCTAssertTrue(FileManager.default.fileExists(atPath: self.activationURL.path))

        let json = try JSONSerialization.jsonObject(with: try Data(contentsOf: self.activationURL)) as? [String: Any]
        let activation = try API.V2.Activation(apiData: try XCTUnwrap(APIData(json: try XCTUnwrap(json))))
        XCTAssertEqual(activation.activationID, "123456")
        XCTAssertEqual(activation.deviceName, "My Awesome Device")
        XCTAssertEqual(activation.subscription.id, "abcdef")
        XCTAssertEqual(activation.subscription.expirationTimestamp, 976_543_210)
        XCTAssertEqual(activation.subscription.name, "Annual Subscription")
        XCTAssertEqual(activation.subscription.renewalStatus, .cancelled)
    }

    func test_rename_setsActivationSourceToWebsiteWithUpdatedActivation() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))

        self.mockAdapter.renameDeviceMock.returnValue = APIData.active(activationID: "123456",
                                                                       deviceName: "My Awesome Device",
                                                                       subscription: ("abcdef", 976_543_210, "Annual Subscription", "cancelled"))

        try await self.controller.renameDevice(to: "My Awesome Device")

        guard case .website(let activation) = self.controller.activationSource else {
            XCTFail("Activation source is not website")
            return
        }

        XCTAssertEqual(activation.activationID, "123456")
        XCTAssertEqual(activation.deviceName, "My Awesome Device")
        XCTAssertEqual(activation.subscription.id, "abcdef")
        XCTAssertEqual(activation.subscription.expirationTimestamp, 976_543_210)
        XCTAssertEqual(activation.subscription.name, "Annual Subscription")
        XCTAssertEqual(activation.subscription.renewalStatus, .cancelled)
    }


    //MARK: - deactivate(activationID:)
    func test_deactivate_tellsAdapterToUseTokenAuthentication() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        try await self.controller.deactivate()

        try self.validateTokenAuthentication()
    }

    func test_deactivate_tellsAdapterToLicenceTokenAuthentication() async throws {
        self.fakeKeychain.token = nil
        let licence = try self.saveLicence()

        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        try await self.controller.deactivate()

        try self.validateLicenceAuthentication(licence)
    }

	func test_deactivate_tellsAdapterToCallDeactivateWithSuppliedID() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        try await self.controller.deactivate(activationID: "otherdevice")

        XCTAssertTrue(self.mockAdapter.deactivateMock.wasCalled)
        XCTAssertEqual(self.mockAdapter.deactivateMock.arguments.first, "otherdevice")
    }

    func test_deactivate_tellsAdapterToCallDeactivateWithCurrentActivationIDIfNilSupplied() async throws {
        let activation = try self.standardActivation()
        self.controller.setActivationSource(.website(activation))
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        try await self.controller.deactivate()

        XCTAssertTrue(self.mockAdapter.deactivateMock.wasCalled)
        XCTAssertEqual(self.mockAdapter.deactivateMock.arguments.first, activation.activationID)
    }

    func test_deactivate_throwsNotActivatedIfNoActivationIDSuppliedAndActivationSourceIsNotWebsite() async throws {
        self.controller.setActivationSource(.none)
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        await XCTAssertThrowsErrorAsync(try await self.controller.deactivate()) { error in
            XCTAssertEqualsV2Error(error, .notActivated)
        }
    }

    func test_deactivate_throwsInvalidResponseIfResponseIsNotDeactivated() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.deactivateMock.returnValue = APIData.noDeviceFound()
        await XCTAssertThrowsErrorAsync(try await self.controller.deactivate()) { error in
            XCTAssertEqualsV2Error(error, .invalidResponse)
        }
    }

    func test_deactivate_deletesLicenceFile() async throws {
        try "Empty file".write(to: self.licenceURL, atomically: true, encoding: .utf8)

        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        try await self.controller.deactivate()

        XCTAssertFalse(FileManager.default.fileExists(atPath: self.licenceURL.path))
    }

    func test_deactivate_deletesActivationFile() async throws {
        try "Empty file".write(to: self.activationURL, atomically: true, encoding: .utf8)

        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        try await self.controller.deactivate()

        XCTAssertFalse(FileManager.default.fileExists(atPath: self.activationURL.path))
    }

    func test_deactivate_setsActivationSourceToNone() async throws {
        self.controller.setActivationSource(.website(try self.standardActivation()))
        self.mockAdapter.deactivateMock.returnValue = APIData.deactivated()
        try await self.controller.deactivate()

        guard case .none = self.controller.activationSource else {
            XCTFail("Activation source is not .none")
            return
        }
    }

    //MARK: - Helpers
    private func saveLicence() throws -> Licence {
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
        try self.controller.saveLicence(licence)

        return licence
    }

    private func standardActivationData() -> APIData {
        return APIData.active(activationID: "123456",
                              deviceName: "My Machine",
                              subscription: ("abcdef", 876_543_210, "Annual Subscription", "renew"))
    }

    private func standardActivation() throws -> API.V2.Activation {
        return try API.V2.Activation(apiData: self.standardActivationData())
    }

    private func validateAgainstStandardActivation(_ activationToTest: API.V2.Activation) {
        XCTAssertEqual(activationToTest.activationID, "123456")
        XCTAssertEqual(activationToTest.deviceName, "My Machine")
        XCTAssertEqual(activationToTest.subscription.id, "abcdef")
        XCTAssertEqual(activationToTest.subscription.expirationTimestamp, 876_543_210)
        XCTAssertEqual(activationToTest.subscription.name, "Annual Subscription")
        XCTAssertEqual(activationToTest.subscription.renewalStatus, .renew)
    }

    private func validateTokenAuthentication() throws {
        XCTAssertTrue(self.mockAdapter.withAuthenticationMock.wasCalled)
        guard case .token(let token) = try XCTUnwrap(self.mockAdapter.withAuthenticationMock.arguments.first) else {
            XCTFail("Authentication type not token")
            return
        }

        XCTAssertEqual(token, "mytoken123")
    }

    private func validateLicenceAuthentication(_ licence: Licence) throws {
        XCTAssertTrue(self.mockAdapter.withAuthenticationMock.wasCalled)
        guard case .licence(let actualLicence) = try XCTUnwrap(self.mockAdapter.withAuthenticationMock.arguments.first) else {
            XCTFail("Authentication type not licence")
            return
        }

        XCTAssertEqual(actualLicence, licence)
    }
    /*
     APIData
        logged_in: [token => 'token']
        no_subscription_found
        subscription_expired
        too_many_devices
        active: [activationID: '', device: [name: ''], subscription: [id: '', expirationTimestamp: 0123, name: '', renewalStatus: 'renew|cancelled|failed']]
        no_device_found
        success: [subscriptions => [[id:, expirationTimestamp: name: renwalStatus: maxDeviceCount: 0, currentDeviceCount: 0]]]
        success: [devices => [[activationID: '', activationTimestamp: 0123, name: ''?, isCurrent: true|false]]]
        deactivated
        invalid_licence
     */
}

func XCTAssertEqualsV2Error(_ error: Error, _ v2Error: API.V2.Error) {
    guard let apiError = error as? API.V2.Error else {
        XCTFail("Error not V2 Error")
        return
    }

    guard apiError.errorCode == v2Error.errorCode else {
        XCTFail("\(apiError) not equal to \(v2Error)")
        return
    }
}

extension APIData {
    static func loggedIn(token: String?) -> APIData {
        var data = APIData.empty
        data.response = .loggedIn
        if let token {
            data.payload = ["token": token]
        }
        return data
    }

    static func loggedOut() -> APIData {
        var data = APIData.empty
        data.response = .loggedOut
        return data
    }

    static func noSubscriptionFound() -> APIData {
        var data = APIData.empty
        data.response = .noSubscriptionFound
        return data
    }

    static func subscriptionExpired() -> APIData {
        var data = APIData.empty
        data.response = .expired
        return data
    }

    static func tooManyDevices() -> APIData {
        var data = APIData.empty
        data.response = .tooManyDevices
        return data
    }

    typealias ActivateSubscription = (id: String?, timestamp: Int?, name: String?, renewalStatus: String?)
    static func active(activationID: String?, deviceName: String?, subscription: ActivateSubscription?) -> APIData {
        var data = APIData.empty
        data.response = .active
        var payload: [String: Any] = ["response": "active"]
        if let activationID {
            payload["activationID"] = activationID
        }
        if let deviceName {
            payload["device"] = ["name": deviceName]
        }
        if let subscription {
            var sub: [String: Any] = [:]
            if let id = subscription.id {
                sub["id"] = id
            }
            if let timestamp = subscription.timestamp {
                sub["expirationTimestamp"] = timestamp
            }
            if let name = subscription.name {
                sub["name"] = name
            }
            if let renewalStatus = subscription.renewalStatus {
                sub["renewalStatus"] = renewalStatus
            }
            payload["subscription"] = sub
        }
        data.payload = payload
        data.signature = (try? APITestCase.signature(forPayload: payload)) ?? ""
        return data
    }

    static func noDeviceFound() -> APIData {
        var data = APIData.empty
        data.response = .noDeviceFound
        return data
    }

    typealias ListedSubscription = (id: String?, timestamp: Int?, name: String?, renewalStatus: String?, maxDevices: Int?, currentDevices: Int?)
    static func subscriptions(_ subscriptions: [ListedSubscription]?) -> APIData {
        var data = APIData.empty
        data.response = .success
        var payload: [String: Any] = ["response": "success"]
        if let subscriptions {
            var subs: [[String: Any]] = []
            for subscription in subscriptions {
                var sub: [String: Any] = [:]
                if let id = subscription.id {
                    sub["id"] = id
                }
                if let timestamp = subscription.timestamp {
                    sub["expirationTimestamp"] = timestamp
                }
                if let name = subscription.name {
                    sub["name"] = name
                }
                if let renewalStatus = subscription.renewalStatus {
                    sub["renewalStatus"] = renewalStatus
                }
                if let maxDeviceCount = subscription.maxDevices {
                    sub["maxDeviceCount"] = maxDeviceCount
                }
                if let currentDeviceCount = subscription.currentDevices {
                    sub["currentDeviceCount"] = currentDeviceCount
                }
                subs.append(sub)
            }

            payload["subscriptions"] = subs
        }
        data.payload = payload
        data.signature = (try? APITestCase.signature(forPayload: payload)) ?? ""
        return data
    }

    typealias ListedDevice = (id: String?, timestamp: Int?, name: String?, isCurrent: Bool?)
    static func devices(_ devices: [ListedDevice]?) -> APIData {
        var data = APIData.empty
        data.response = .success
        var payload: [String: Any] = ["response": "success"]
        if let devices {
            var devicesArray: [[String: Any]] = []
            for device in devices {
                var deviceJSON: [String: Any] = [:]
                if let id = device.id {
                    deviceJSON["activationID"] = id
                }
                if let timestamp = device.timestamp {
                    deviceJSON["activationTimestamp"] = timestamp
                }
                if let name = device.name {
                    deviceJSON["name"] = name
                }
                if let isCurrent = device.isCurrent {
                    deviceJSON["isCurrent"] = isCurrent
                }
                devicesArray.append(deviceJSON)
            }

            payload["devices"] = devicesArray
        }
        data.payload = payload
        data.signature = (try? APITestCase.signature(forPayload: payload)) ?? ""
        return data
    }

    static func deactivated() -> APIData {
        var data = APIData.empty
        data.response = .deactivated
        return data
    }

    static func invalidLicence() -> APIData {
        var data = APIData.empty
        data.response = .invalidLicence
        return data
    }
}
