//
//  ActivateAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class ActivateAPITests: XCTestCase {
    func test_run_calling_requestsActivateAPIEndpoint() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledEndpoint, "activate")
    }

    func test_run_calling_usesPOSTMethod() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledMethod, "POST")
    }

    func test_run_calling_setsEmail_PasswordAndBundleIDJSONOnBody() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertEqual(json?["email"] as? String, "foo@bar.com")
        XCTAssertEqual(json?["password"] as? String, "123456")
        XCTAssertEqual(json?["bundleID"] as? String, "com.mcubedsw.Coppice")
    }

    func test_run_calling_setsDeviceID_DeviceName_DeviceTypeAndAppVersionJSONOnBody() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foo Bar Baz")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertEqual(json?["deviceID"] as? String, device.id)
        XCTAssertEqual(json?["deviceType"] as? String, device.type.rawValue)
        XCTAssertEqual(json?["deviceName"] as? String, "Foo Bar Baz")
        XCTAssertEqual(json?["version"] as? String, device.appVersion)
    }

    func test_run_calling_setsSubscriptionIDJSONOnBodyIfSetInActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice", subscriptionID: "Sub123")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertEqual(json?["subscriptionID"] as? String, "Sub123")
    }

    func test_run_calling_doesntSetSubscriptionIDJSONOnBodyIfNotSetOnActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertNil(json?["subscriptionID"])
    }

    func test_run_calling_setsDeviceDeactivationTokenJSONOnBodyIfSetInActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice", deviceDeactivationToken: "Deactivate987")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertEqual(json?["deactivatingDeviceToken"] as? String, "Deactivate987")
    }

    func test_run_calling_doesntSetDeviceDeactivationTokenJSONOnBodyIfNotSetOnActivationRequest() throws {
        let mockAdapter = MockNetworkAdapter()
        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: Device(name: "Foobar"))
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertNil(json?["deviceDeactivationToken"])
    }


    //MARK: - Error handling
    func test_run_errorHandling_returnsInvalidRequestIfDeviceNameIsNotSet() throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .failure(expectedError)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device()
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .invalidRequest = failure else {
                XCTFail("Result is not an invalidRequest error")
                return
        }
    }

    func test_run_errorHandling_returnsFailureIfErrorIsSupplied() throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .failure(expectedError)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .generic(let error) = failure else {
                XCTFail("Result is not a generic error")
                return
        }

        XCTAssertEqual(error as NSError?, expectedError)
    }

    func test_run_errorHandling_returnsFailureIfReceived_login_failed_Response() throws {
        let payload = ["response": "login_failed"]
        let signature = "MPPHM9TT6mODQxeKt2IhYd2nyzFTuKCNUVmarQ8Ttvc9Y/grkj2aGRmTzLkrF3p+Cs+Oq3S+StJbE6TCgXjWnEOj6/+8XFbUeeJ4R643jilwQ+LO0FcbUURQiyjUBoXK9THSBSrgmHezJ1OZmJ+4DonPAMwuAo+z2NjLw87jjNc9COvvWf1SdjW3zJaejrzdgGgIPeWEf/36RpPMwATEd8HJkuAPyQ29y7FmCFFzcwicakS7HwIO3aVpt/8rHM9ZilsHMmSvRFvn6dAG4Jkm8q/Surb6AfIwLmYeP29K5EKHv03VP7hF4e5PugjDsQHvtprN6iAjlMB6w7hybHV+ig=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .loginFailed = failure else {
                XCTFail("Result is not a loginFailed error")
                return
        }
    }

    func test_run_errorHandling_returnsFailureAndSubscriptionPlansIfReceived_multiple_subscriptions_Response() throws {
        let plan1: [String: Any] = ["id": "plan1", "name": "Plan A", "expirationDate": "2022-01-01T01:01:01Z", "maxDeviceCount":5, "currentDeviceCount":4]
        let plan2: [String: Any] = ["id": "plan2", "name": "Plan B", "expirationDate": "2021-12-21T12:21:12Z", "maxDeviceCount":3, "currentDeviceCount":3]
        let payload: [String: Any] = ["response": "multiple_subscriptions", "subscriptions": [plan1, plan2]]
        let signature = "iZrDGvxXzh2FRD9feKGQIamGYO2a73p5dIHDrWC2eNkto+kEGVNr+S276kBai1v4E82L4WLBeHvGMXvgQHNXTKtmItX+nnXY60L79mZYo6FojOFDBqEea3TCzYrYuoXmutU2sz9aF5om5tb1ITTdYZRovxX2nlTMF+GtAPYyL6S50dgIitDTpm82ZjipUc+0uyqESs/1iPLLpl3B4OENlnXFolcwRcvidoo7xQ+3NXxAsUstEN9boOgG0A1T+z24ycsOT5zqCKFcs3lZSmEjKtaaR2z5X/DsAWCWN5QfZFRFTMWQ8qB/ZfdMezxrJd58oVYTcXbZD5bbiPG+AYwcYw=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .multipleSubscriptions(let subscriptions) = failure else {
                XCTFail("Result is not a multipleSubscriptions failure")
                return
        }

        let actualPlan1 = try XCTUnwrap(subscriptions.first)
        XCTAssertEqual(actualPlan1.id, "plan1")
        XCTAssertEqual(actualPlan1.name, "Plan A")
        XCTAssertDateEquals(actualPlan1.expirationDate, 2022, 1, 1, 1, 1, 1)
        XCTAssertEqual(actualPlan1.maxDeviceCount, 5)
        XCTAssertEqual(actualPlan1.currentDeviceCount, 4)

        let actualPlan2 = try XCTUnwrap(subscriptions.last)
        XCTAssertEqual(actualPlan2.id, "plan2")
        XCTAssertEqual(actualPlan2.name, "Plan B")
        XCTAssertDateEquals(actualPlan2.expirationDate, 2021, 12, 21, 12, 21, 12)
        XCTAssertEqual(actualPlan2.maxDeviceCount, 3)
        XCTAssertEqual(actualPlan2.currentDeviceCount, 3)
    }

    func test_run_errorHandling_returnsFailureIfReceived_no_subscription_found_Response() throws {
        let payload = ["response": "no_subscription_found"]
        let signature = "eWy4/6I/UMDLGBjVYpT/zfquz46ouKq7pqM6tZTFilfzaX4WvlBBfQVknlNxxHs3It4wc3kTwalHGpWas0TawrZvVK92eA6NVPJeGfCQbzy0BTrGQZvfTW+hERA+20O3KyKtZbIDShJTnrOU46QWseoEBrtDZh3JwYSlCQhAwsRw6VQ6TQS1jAOuApqzAoDAJahhos2t0nI6SWGQ6WSmtjO3DwjRQRGEJu2ToJ4f6xPEDkB5pNSSV6OimG5F1nb7CF4MdGvnLeloF9jDLVoNQoUkhhtplZY4b11LzQpN7C/aof7d339mN6TNopgj5v6l9JGXHTdOrrLVMZEmM8ehjA=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .noSubscriptionFound = failure else {
                XCTFail("Result is not a noSubscriptionFound error")
                return
        }
    }

    func test_run_errorHandling_returnsFailureAndSubscriptionIfReceived_subscription_expired_Response() throws {
        let payload = ["response": "subscription_expired", "subscriptionName": "Plan C", "expirationDate": "2020-01-02T03:04:05Z"]
        let signature = "Syj/uI3VvxI+cJj9MvfSeyUdU3xZiUmEbUO3clzcM2znhQRJMQNrayF+nTkOunj+S59x2TIFIS6n2AdWAn9bfPDpsTuibWlRWZFELiidlJDL4+mn+yZG8jLJGJoNcLV4zXuZrD4mbnSI2/rH8p4QybW59NanmC8t6mt89W9JCAUICfCLfZBnYMBx/3RR6TBY4b79p4PV84KG2i77Z2ga1wgkO852jGVwS9eG+8ekgALnMw6X/YLgZpqkQHuD39eCSURvglVMMC84+vrtdROghhjD4htuSwYgDmkx93+J6aOUGTjDT7iUTS3+AkYFOSd6FbdI/qpR5xKcMN1+I+CrvQ=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .subscriptionExpired(let subscription) = failure else {
                XCTFail("Result is not a subscriptionExpired failure")
                return
        }

        let actualSubscription = try XCTUnwrap(subscription)

        XCTAssertEqual(actualSubscription.name, "Plan C")
        XCTAssertDateEquals(actualSubscription.expirationDate, 2020, 1, 2, 3, 4, 5)
    }

    func test_run_errorHandling_returnsFailureAndDevicesIfReceived_too_many_devices_Response() throws {
        let device1: [String: Any] = ["name": "My iMac", "deactivationToken": "tokeniMac", "activationDate": "2022-10-10T10:10:10Z"]
        let device2: [String: Any] = ["name": "My Mac Pro", "deactivationToken": "mactokenpro", "activationDate": "2031-03-31T03:31:03Z"]
        let payload: [String: Any] = ["response": "too_many_devices", "devices": [device1, device2]]
        let signature = "l46mZZF1Ou1eanqwWhdbj7iYHJ11ZQOnKvGM1ka8YbtU6maPHVBMsNKd/DEyQwxcP85AWp7fF/+aky+nJ3v2tUfYlxAScb7jfEKa4iiqXkC1VHWmsz2OHyf+txzONXtRLAB5pvbSX1PYWJZjImNb5OUKz6SiurkElwvNCQk0+gvk3l9Nm7uP4EwRZ8UDH8kpyu9uXXnb8uCSxFeWL+GnHAXJD5Zv8UGfqDKkWeFmUSM72Y8WCnaUWVgLm2lXetMXG2xNB5K5K48IpLfFnRI0SkXvFnJCwhjN8s+dggYXK53JtqeKIidf1W2TgkIG6qxsJVSwc/XMu8o9ggDYMg654w=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .tooManyDevices(let devices) = failure else {
                XCTFail("Result is not a tooManyDevices failure")
                return
        }

        let actualDevice1 = try XCTUnwrap(devices.first)
        XCTAssertEqual(actualDevice1.name, "My iMac")
        XCTAssertEqual(actualDevice1.deactivationToken, "tokeniMac")
        XCTAssertDateEquals(actualDevice1.activationDate, 2022, 10, 10, 10, 10, 10)

        let actualDevice2 = try XCTUnwrap(devices.last)
        XCTAssertEqual(actualDevice2.name, "My Mac Pro")
        XCTAssertEqual(actualDevice2.deactivationToken, "mactokenpro")
        XCTAssertDateEquals(actualDevice2.activationDate, 2031, 3, 31, 3, 31, 3)
    }


    //MARK: - Success
    func test_run_returnsSubscriptionInfoWithActivateStateIfReceived_active_Response() throws {
        let payload = [
            "response": "active",
            "subscriptionName": "Plan C",
            "expirationDate": "2020-01-02T03:04:05Z",
            "token": "tucan43"
        ]
        let signature = "oDaGs16HxslmzsSZNli4ArXZTmzRVnxYsKX4PqPev7mBf8hNsbZhwv+NrJYO8owT5GaN+noT/5787HLmS0AfzBBfL/+Me+r+iKEzDyPmsSEP7zc68sUluQxhGbQEuMND2cse5EZJX/4rCoxCawWvCjn9FB+KrJmjpHS2Trf8pK6Sc+1XleBKA89C90T8bF8TmCd0FXzx3XIqk4CA2T2EtW3xwvdiJ2rZikozVbo7NhY/+uGXlXbxKlK6xGCcLyjWsf269FAWUpuDc4xZDSd6KQzBsBO6Hlsw1j3Z6zTL05IWlkcIM0tNov7v/BR+jipaVYGKWj0mdE7urnmBrs1yew=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard case .success(let response) = try XCTUnwrap(actualResult) else {
            XCTFail("Result is not a success")
            return
        }

        XCTAssertEqual(response.state, .active)
        XCTAssertEqual(response.token, "tucan43")

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, "Plan C")
        XCTAssertDateEquals(subscription.expirationDate, 2020, 1, 2, 3, 4, 5)
    }

    func test_run_returnsSubscriptionInfoWithActivateStateIfReceived_billing_failed_Response() throws {
        let payload = [
            "response": "billing_failed",
            "subscriptionName": "Plan C",
            "expirationDate": "2020-01-02T03:04:05Z",
            "token": "tucan43"
        ]
        let signature = "z4CQvo6geKD35Tit+/Jwbe34dQTiNJokyH0PKnsj/orLefTgZ5SQp8RnJRbzzPuJe5ISognc3yFU9lwVaV+pfNWuUjB2We+qrGpVieqeX+6JFm1Qg0WEDlnPmEQu69nzU9SZURQUERj0e5p4OjDI0czFRFqgRjaGawXN4zi44O3nqCEBKzwca/1DMqLXwSRns+MpFwLHYLFgUUh6HvhJQTdZA7azJT1d9EidCksjOKq5KeOA3LJFxza1tzQJgB8ONyUVy7XZH3Gurq458TFXcrKWAzK6sl6LAxBRp5phVPxkQTEMb1sP/s/r7pQk7tLpfVVrsudE3QGSduLKb5Kagg=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let request = ActivationRequest(email: "foo@bar.com", password: "123456", bundleID: "com.mcubedsw.Coppice")
        let device = Device(name: "Foobar")
        let api = ActivateAPI(networkAdapter: mockAdapter, request: request, device: device)

        var actualResult: Result<ActivationResponse, ActivateAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard case .success(let response) = try XCTUnwrap(actualResult) else {
            XCTFail("Result is not a success")
            return
        }

        XCTAssertEqual(response.state, .billingFailed)
        XCTAssertEqual(response.token, "tucan43")

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, "Plan C")
        XCTAssertDateEquals(subscription.expirationDate, 2020, 1, 2, 3, 4, 5)
    }
}
