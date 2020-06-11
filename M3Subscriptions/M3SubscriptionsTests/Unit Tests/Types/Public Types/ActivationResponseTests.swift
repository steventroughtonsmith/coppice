//
//  ActivationResponseTests.swift
//  M3SubscriptionsTests
//
//  Created by Martin Pilkington on 09/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import M3Subscriptions

class ActivationResponseTests: XCTestCase {
    func test_init_returnsNilIfSubscriptionNameIsMissingAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "pz91p8fHEQcj9QU1c6vRfDucQWT0OFqQ5sp2tEo8G+udLQZWpvl7yVMoIH4Is0uZdGoU4gu0of2rwWPW0bYBpGCjI4U4oMLM+HkU0LRWn/n3slqE+NBJJYUwzjuPbOV3p6xAWCQ7nkXIlYdiao6iZQYsVFZYbYumn7Mr4HuT1l09GCOmB9tUVU6MT27dcxIJU3yEaUNN2CFba+hEu3TgPyFk+MPmoZPriO0ob4t3cX0RsqriAfwkjl9PczUt7SRhoApiLWT23GwSNLYl13Obrab0W5iQ+BkMXY+8TGy7IqPOvpzu56A2VvFvYUN2VXVrKJUMVPK9+Jnxviruuekcxw=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        XCTAssertNil(ActivationResponse(data: data))
    }

    func test_init_returnsNilIfSubscriptionNameIsNotStringAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": 19251212512,
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "E4z7pJnghh1PlO0CKIcns7AmILO5PJEB9Aoc0/05cs6byG711aAzM26ndtBM2NmEEIkfM27En6TxHVULepetpAdZIHtB+gmYtZfynenL6fXzfiYHyP2v8bfsJ3+1sjVz2okKPcELvJTHEzsBF8l4kjDE+ZFS0um7qAkc9GmYoLApNpF281gYY3+LTFnwk7ezex0AFXS7O9oiiSI7cfQBQ+CyiQoCX1hE2iH0D9mtpN1Zi/IC//Wl6qtD9rca/XqfoCrnPqmFtG6cXv9quZRQr93Y8AYNCr/cA9YOx2K6ch5vFTPgudt133DO515nqrH+KNw26cu+zSV3uievGZxPeg=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        XCTAssertNil(ActivationResponse(data: data))
    }

    func test_init_returnsNilIfExpirationDateIsMissingAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
        ]
        let signature = "ZuSnNg47Fndq8Ok00AzHi4MmpTSQTZnXMiix2K+IzZz7jyPXq73ka3Bo32+tDv2h5yq00xRe0Gn6EN2q0qIkRGrHSP73WO1Mp6XihMBAmnX4SiHK/a/y9kHeVLijx6FSTSL/UtUB2yg3osuLqKizwZiQA5om+ph3ex78aM1veHJKs9C5odruzshF9LkWPB8jC+ZCTiCZ+DeUiiZvTWPTvP0bnFRsgUE6Q98E7f429o+Eq0B6+EV2QPITeJhE9ar157VYiwJUHjarJhhKrUdBY96Iz6XCJmRRbPUKgeuJaUfc+rEaNkWoDq2g8DJKCGK+rxioTe6HZLmda/TTJniFIQ=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        XCTAssertNil(ActivationResponse(data: data))
    }

    func test_init_returnsNilIfExpirationDateIsNotStringAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": 2000
        ]
        let signature = "Vi9rZ/07kmatfD/Lt1EHYBORNM94iKwoFxRXJNFK/D3qMpkIm6ivTYQUtcPYUNo2jkuJhpt9qChR/wSr8rERrngd6nFQWrkhMzVB+IdsIQZl0ZIcLBIvJ/3MF71NTlIQOK9kdl934SuF0/5kLAo8FOIYc0IH8xii/hu85lTRpZsNo0V4KeDTOW7FOEmmntHwxLJjNmG0QmkWSuYwt6Wp3xm7ff5xv892zu/wFwhJRev/EQXhJk3bgsItT99HR2uxCzcIUN3oej2fvGroJhjzpb38yfTJ6K5K+JNZng56akw4LFIStEw7Ci5Mb4YdK6mPtbjCJGAbdHrFbo8+xd9/sg=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        XCTAssertNil(ActivationResponse(data: data))
    }

    func test_init_returnsNilIfExpirationDateIsNotISO8601DateAndStateRequiresSubscription() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "Not a date!"
        ]
        let signature = "r43O5Pu/nXYVTE3GyBi/x0qv2aAbr6ve4Rb3quiDXJimQRmOsET8HTSG4d8Sn+On0hhbKxyG5/jiIjTSAGiuwW62sEt0Cte7lg1BpLrhjr3nCEzyuJWlmpMqmeDFpiVVxVSaN265qimTcMiMzoTRWgTiURmcmkacWfGCTaHMecxpFp3K9dUN8ySLB20hKrk72tD39JZy1U5LWseUxPsZTyn9IME4YOJLucz4rlqYQuN6w4PZFNBDn3ktVHA31aGe/A6l2zaaJFh/tzHi91e8KLofLOxY1SBp0zkZYjKN7YzjJp306P1Qj84TJLD08lAUIWgd1J6EFQUhgFrjiJdBTA=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        XCTAssertNil(ActivationResponse(data: data))
    }

    func test_init_returnsActivationResponseWithCorrectProperties() throws {
        let payload: [String: Any] = [
            "response": "foo",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "PY7RGNM+7DnIkV+6KS+xqMNNnQIucwhRN0aqQvpj5RJ5vc8bi0IECinjMAD4FInIsBwjcEVU1m/fLIq4K3aSv2l/g4J0B8Z2+rCIecsC+llJjTyVD4BmxSssQjXguJWHp7lTNa2ghAcHkN8ZtND19ypPVTCIR34zY1fsOdVb8BTWG3Yi050udeoieJ4yYPqJKER2jtNvS9IXIlmUyoc1BOeuL2lw8F+R1zQ5UE7Jr49/aopWVo0ypEEDA8GRNc5T35Kpa0x1OPmZRJvJF9xAZYgerUahvX/FQBHrg5D3aG26m/gBL03o0oDn8kojfZsFT6OCl66Sm3YCAQAWlabvvw=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .unknown)

        let subscription = try XCTUnwrap(response.subscription)
        XCTAssertEqual(subscription.name, "My Subscription Plan")

        let calendar = NSCalendar(calendarIdentifier: .ISO8601)
        calendar?.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar?.components([.year, .month, .day, .hour, .minute, .second], from: subscription.expirationDate)
        XCTAssertEqual(components?.year, 2005)
        XCTAssertEqual(components?.month, 10)
        XCTAssertEqual(components?.day, 15)
        XCTAssertEqual(components?.hour, 20)
        XCTAssertEqual(components?.minute, 15)
        XCTAssertEqual(components?.second, 10)
    }


    //MARK: - .state
    func test_state_setsStateTo_active_ifResponseIs_active() throws {
        let payload: [String: Any] = [
            "response": "active",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "BCZeqr7dDEafv0zeIMwoOBYK3i9o1vTEWMeXtnK5RIWR1SwANPPr+WSV/PjBaGcRK3QS7WGZXejyEDCYupcRoHyEOUS/KzwZxVdB1hQCGFv+60dEuOOp1ikl6f7HesUCV0z8pVxDnSLyYcdBmm2EKPFHrAdiyJyrB/Ud+Qpihtu2FJFWHHSybHYw6IrkkmJb2atz+jEu55yaPRcstYIwn7VcfJ2zl1QonfUuUS+tyu4Mbsl6rqG+NoDMgFJIjXBRTJjmizAkQy4tKHhmB8WgA82aac2d1uUAnsnBh1L4l8YWdngx3xw8/xVo480wAf99o/AZC2CkSA4gX0E72Qelsg=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .active)
    }

    func test_state_setsStateTo_billingFailed_ifResponseIs_billing_failed() throws {
        let payload: [String: Any] = [
            "response": "billing_failed",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "Cow5AimxoJGucbN3sk2E7GApI/ICBAS6wdPrWwMvjyQIPZ9lyMbWlk8bN+rCd+kSsox/q6HHc4kNlEpMwx2cDyBO4/FvQlPa0dEGA83BB99JXgYbB99EVg8j1w5FUbVkmxPyw1ipLL6ZwWgPHQzJhtjiGeDKDQhHGcv8G8tVhH9uar4Wnq9MyHC8YYjhrseDz9A/W7fQdmZsA774pFG2qO58FLaQJQnkgaMIOCCUTIyZh5Kh4XsbYSAgIyy89+4ljzR5z4ZbqVcSa3HQx2RejQgCf0EIITYOXLht362HjANCcZRNOKscAHF9ePGfbJrF2svwuZ2pZ5Kme+dvGvcXfA=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .billingFailed)
    }

    func test_state_setsStateTo_deactivated_ifResponseIs_deactivated() throws {
        let payload: [String: Any] = [
            "response": "deactivated",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "bgcmq/04XunfcO08KlN0+F6J2NAl1vr24Eg3M33/gWcI2E3rTPxyvEtVE1K31H8a8ABeBOfy13vRU+K1Ec5Lhk13ZBr7M1JN5BpYfdcnd70qgF4GfhLxz7VduU7KeAAZYVKX3EPjp4lq0O2mVzcb/GtiOHgV0LriF7Afg5NtViNarN6KJgJhZNJ3yT6ywxoxIHrF2XWjm5OfmyPuNYwnPoWKSBOBDX5wZ4z+wPLksZDCk7jvJKsR7L3xDhq2je/uerbj3ZbXOooDk70EBb+TnVASriROI90r12AdV1wDs3wbNxlbz278AlsP65rl80q/W5nWDqLrw8/IWmWoYaHL7Q=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .deactivated)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_no_device_found() throws {
        let payload: [String: Any] = [
            "response": "no_device_found",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "a/IZ4X2pEedphXy4epLCm2wK2q/ZsZSM/lXtL3QLEQwySIScp3jHSi2V6HVoaa0YkAVzaWFMYB+c3jp/bWAZOhLCRI++1dIfuFEKYqq8LtsL7xEvqD5TFwf88ecE2r7oI+aMf3n6kqTzOrdTu5mlPbcUhkommWXDSH1DRFN6fscjCZ1sdQ7jTrPuu7Rwj40djqRolwdSekZ15IvpAJc9ofU0RjR3onOWQNRrF/T69Y3MTOLGOFtv+SnEdkxm7SJRNgAncnc0ZlFay0I7kKDnGC8HMJP3E/5Lix9bz9+5McLfMo1peXy8Tk2c76crRq7hpcQyb0YrC323HNPyrN3iTw=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_subscription_expired() throws {
        let payload: [String: Any] = [
            "response": "expired",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "G0cinNUDwUSkumfeXvmHYsDSNFdcBU+YNIaZB3lk7TURq8UVLrFh6K3IX0mgYFPnl1SlJprk9fJrTkA26BrnHgW69mdulp4+WXb3frfbeVYMQY7Ji4LVtS4RmOktoi4CLrGHnZJlynVIHMpUeLuMoreylK9uvLH4sOm33sgAN3GFiLsRknJonBH3+xF12gfV6CoNnMfeBfW/UfK5MomOovL/2EpTlqSA2cWL4/UbRl4xnYnaBvZ3hoyCc1SKF5LaX9pyDWS5YPYODzmSxU68pqkaEKMZLRJKNNZPIo1x6JKfKrsNSMu8+y5mrrjB7qF+bZkzc8dseJHzjvkg95JTVA=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_no_subscription_found() throws {
        let payload: [String: Any] = [
            "response": "no_subscription_found",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "UroS0bqXCLpzEHynsSaKOQKmAPwD4Vdh2Q2zvtDuIO4MWXCsIX4qWPnXggjqnMfjpWp+Ibxula2Vyntf5EhoLaSaJHEHlSbkylwkUvLUyP6c+9mGBwOCf40ON6CUHDtqL3pFAnQB98ILi4N9OLyA2e0LS2OqIaogCdO4jr7yjB3gPemKDiZt8/9LmPdfaxC5WgdE9bp8Tuh4iOcbLuxkDvy1ARecTjWFx5e8cuw3hxf6+R5OEkSJ4DhGgzMOjAMb2YPNk28asy8cySD75wykkH8ZtrzUgbrJgwiNU2uidm4S8zz7iKxud+HhY6nbfg/oUUTfn3zk+DDQi+m2iVhK4Q=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_multiple_subscriptions() throws {
        let payload: [String: Any] = [
            "response": "multiple_subscriptions",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "b07ip7E57jp+Nx9MEoo2+Fwe764FVc1gBWSfsVu9VgOe+p1IVfD9vdBSYWk6T8sDJMeRBn/DtaGQFVhNZjc0oZX6X8XweYxp4HCrKWbc172C8P1SjaNUjzZWHKXyndovCOPF/tsAVFTZ3iYYiToX0h9iMlJnjDZJG4MxDiwc7IAUUk7BTS0MvIhRJuO44okK3c6wCoQ7wQRUFIzIlrpfEVbFMEpIaB//vzV7lX6aljSNUWvRoQPKQWov6E22D7YD1jmcGw3A80UI2yyuLKYMnAUbit3m4JNqBXaDS05zyo4IHMFlxe6Fr8y/1IxpiLx8Arb/rXqPjSN6l2qxzzRb2A=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIs_login_failed() throws {
        let payload: [String: Any] = [
            "response": "login_failed",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "fxtCBH8Bv1sHah8hL7fdYGV4JvEyfb/qJQxp+j32SRXQrsgOrxaYzNoaJTBny0aqOtgvxNSyfMminwRSh2aQOGZNsd818SLP0NLfI3MpXzZlmpImfRPLMov0pafwzLt2zuyeUTs7ck/iIf/Us5kqmQjmRcPZDwkaFJbIHo9UcHcSWhdNxiI8lWQFY2WiBGpVYuZiMA4COqXmOwTQcLfBdTPenkEkLRHPwL/DZOis5pWcIorRv7DwNzopOf0SWL08BrlegxXVGBUT7LYbeofU5KHbfVmJD6Eq9K9N8TzGu+2ESh4USUuBAoGfh+O21H8R6l59BJkXb/tmmcGYGXxjSw=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .unknown)
    }

    func test_state_setsStateTo_unknown_ifResponseIsSomeRandomText() throws {
        let payload: [String: Any] = [
            "response": "the quick brown fox jumped over the lazy dog",
            "subscriptionName": "My Subscription Plan",
            "expirationDate": "2005-10-15T20:15:10Z"
        ]
        let signature = "O+i11F3Sa6STFdZiES0sZJ7App5dxHJgGeLrxYFlAWoksVOabctd9kzZVry8CKTTKOb9KIh4JSN41U9rfRPwKvbQNQDYiBNaHYIIuekb0fuUaG7cAhK3gRfeeIuearc7GxwqV5l4cud5heaVN8r8slDvwoaUHN/sAGCNusUq5ABITWVRmlxzW+5DZvN0d7AsRyU+6smsZTmMLgpT2yM6H+kHFr15VJNybT83vXdrEJVdh6Tfeky0E2jaV1x2sAtkpPtVKNMkaTy3IX/Rw7vy5rY9EpSnWm7s0BQpUqVCWemq0L0L5uT/cPhswDAXh11txsNraWUSOBi4r1+tclnZ1A=="
        let data = try XCTUnwrap(APIData(json: ["payload": payload, "signature": signature]))
        let response = try XCTUnwrap(ActivationResponse(data: data))
        XCTAssertEqual(response.state, .unknown)
    }
}
