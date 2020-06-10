//
//  CheckAPITests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 08/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class CheckAPITests: XCTestCase {
    func test_run_calling_requestsCheckAPIEndpoint() throws {
        let mockAdapter = MockNetworkAdapter()
        let api = CheckAPI(networkAdapter: mockAdapter, device: Device(), token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledEndpoint, "check")
    }

    func test_run_calling_usesPostMethod() throws {
        let mockAdapter = MockNetworkAdapter()
        let api = CheckAPI(networkAdapter: mockAdapter, device: Device(), token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        XCTAssertEqual(mockAdapter.calledMethod, "POST")
    }

    func test_run_calling_setsToken_Version_DeviceTypeAndDeviceIDJSONAsBody() throws {
        let mockAdapter = MockNetworkAdapter()
        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertEqual(json?["deviceID"] as? String, device.id)
        XCTAssertEqual(json?["deviceType"] as? String, device.type.rawValue)
        XCTAssertEqual(json?["token"] as? String, "tucan42")
    }

    func test_run_calling_setsDeviceNameInBodyJSONIfSetOnDevice() throws {
        let mockAdapter = MockNetworkAdapter()
        let device = Device(name: "POSSUMZ!!1!")
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertEqual(json?["deviceName"] as? String, "POSSUMZ!!1!")
    }

    func test_run_calling_doesntSetDeviceNameInBodyJSONIfNotSetOnDevice() throws {
        let mockAdapter = MockNetworkAdapter()
        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { _ in
                expectation.fulfill()
            }
        }

        let bodyData = try XCTUnwrap(mockAdapter.calledBody)
        let json = try JSONSerialization.jsonObject(with: bodyData, options: []) as? [String: Any]
        XCTAssertNil(json?["deviceName"] as? String)
    }


    //MARK: - Error Handling
    func test_run_errorHandling_returnsFailureIfErrorIsSupplied() throws {
        let expectedError = NSError(domain: "com.mcubedsw.test", code: -42, userInfo: nil)

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .failure(expectedError)

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
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

    func test_run_errorHandling_returnsFailureIfReceived_no_device_found_Response() throws {
        let payload = ["response": "no_device_found"]
        let signature = "3BLTKt7ToQUlKSDFFPctzZz4fwsChOSWqMBKrPuD1BnJ5hl7/iJAcirzJds0f6afSJrNCiy0MVIbaazoyYrv3hF6EOBhipHe5mwtIjkZrf74aMgYcDb9v9P7JfGUfzax9HBGtplfAaZaGlO94auGkiRxe/1LOFCUIu/l+zeYU+TkrSRnqUyvXl7RnS3MhK7j8BWjlTaOx5WdU+scEweETdN9V31YhQZX7LmEebpSvZObfvgm2LAntLArXpIChgAb0js7gCneDooHWyaICvgHJJuUlVRijOANAi9+21dNdl3tlwidGUDo91Uq906GIBdBWfhz+9S2VBYpgxlWH4u7Nw=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .noDeviceFound = failure else {
                XCTFail("Result is not a noDeviceFound failure")
                return
        }
    }

    func test_run_errorHandling_returnsFailureIfReceived_no_subscription_found_Response() throws {
        let payload = ["response": "no_subscription_found"]
        let signature = "eWy4/6I/UMDLGBjVYpT/zfquz46ouKq7pqM6tZTFilfzaX4WvlBBfQVknlNxxHs3It4wc3kTwalHGpWas0TawrZvVK92eA6NVPJeGfCQbzy0BTrGQZvfTW+hERA+20O3KyKtZbIDShJTnrOU46QWseoEBrtDZh3JwYSlCQhAwsRw6VQ6TQS1jAOuApqzAoDAJahhos2t0nI6SWGQ6WSmtjO3DwjRQRGEJu2ToJ4f6xPEDkB5pNSSV6OimG5F1nb7CF4MdGvnLeloF9jDLVoNQoUkhhtplZY4b11LzQpN7C/aof7d339mN6TNopgj5v6l9JGXHTdOrrLVMZEmM8ehjA=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
        self.performAndWaitFor("Call API") { (expectation) in
            api.run { result in
                actualResult = result
                expectation.fulfill()
            }
        }

        guard
            case .failure(let failure) = try XCTUnwrap(actualResult),
            case .noSubscriptionFound = failure else {
                XCTFail("Result is not a noSubscriptionFound failure")
                return
        }
    }

    func test_run_errorHandling_returnsFailureIncludingSubscriptionIfReceived_subscription_expired_Response() throws {
        let payload = ["response": "subscription_expired", "subscriptionName": "Plan C", "expirationDate": "2020-01-02T03:04:05Z"]
        let signature = "Syj/uI3VvxI+cJj9MvfSeyUdU3xZiUmEbUO3clzcM2znhQRJMQNrayF+nTkOunj+S59x2TIFIS6n2AdWAn9bfPDpsTuibWlRWZFELiidlJDL4+mn+yZG8jLJGJoNcLV4zXuZrD4mbnSI2/rH8p4QybW59NanmC8t6mt89W9JCAUICfCLfZBnYMBx/3RR6TBY4b79p4PV84KG2i77Z2ga1wgkO852jGVwS9eG+8ekgALnMw6X/YLgZpqkQHuD39eCSURvglVMMC84+vrtdROghhjD4htuSwYgDmkx93+J6aOUGTjDT7iUTS3+AkYFOSd6FbdI/qpR5xKcMN1+I+CrvQ=="
        let json: [String: Any] = ["payload": payload, "signature": signature]
        let apiData = try XCTUnwrap(APIData(json: json))

        let mockAdapter = MockNetworkAdapter()
        mockAdapter.resultToReturn = .success(apiData)

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
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


    //MARK: - Success
    func test_run_returnsSubscriptionInfoWithActiveStateIfReceived_active_Response() throws {
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

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
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

    func test_run_returnsSubscriptionInfoWithBillingFailedStateIfReceived_billing_failed_Response() throws {
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

        let device = Device()
        let api = CheckAPI(networkAdapter: mockAdapter, device: device, token: "tucan42")

        var actualResult: Result<ActivationResponse, CheckAPI.Failure>?
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
