//
//  Licence.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public struct Licence {
        public var licenceID: String
        public var subscription: Subscription
        public var subscriber: String
        public var signature: String

        public init(url: URL) throws {
            let data: Data
            if url.scheme == "coppice" {
                data = try Self.data(fromFile: url)
            } else if url.isFileURL {
                data = try Self.data(fromURL: url)
            } else {
                throw API.V2.Error.invalidLicence
            }

            guard
                let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                let payload = json["payload"] as? [String: Any],
                let signature = json["signature"] as? String,
                APIData.verify(payload: payload, signature: signature) == signature
            else {
                throw API.V2.Error.invalidLicence
            }

            guard
                let licenceID = payload["licenceID"] as? String,
                let subscriber = payload["subscriber"] as? String,
                let subscriptionID = payload["subscriptionID"] as? String,
                let subscriptionName = payload["subscriptionName"] as? String,
                let expirationTimestamp = payload["expirationTimestamp"] as? TimeInterval
            else {
                throw API.V2.Error.invalidLicence
            }


            self.licenceID = licenceID
            self.subscription = Subscription(id: subscriptionID,
                                             expirationTimestamp: expirationTimestamp,
                                             name: subscriptionName,
                                             renewalStatus: .unknown)
            self.subscriber = subscriber
            self.signature = signature
        }

        func write(to file: URL) throws {
            let payload: [String: Any] = [
                "licenceID": self.licenceID,
                "subscriber": self.subscriber,
                "subscriptionID": self.subscription.id,
                "subscriptionName": self.subscription.name,
                "expirationTimestamp": self.subscription.expirationTimestamp,
            ]

            let json: [String: Any] = ["payload": payload, "signature": self.signature]
            let data = try JSONSerialization.data(withJSONObject: json, options: .sortedKeys)
            try data.write(to: file, options: .atomic)
        }

        private static func data(fromFile url: URL) throws -> Data {
            guard let data = try? Data(contentsOf: url) else {
                throw API.V2.Error.invalidLicence
            }
            return data
        }

        private static func data(fromURL url: URL) throws -> Data {
            guard
                let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                urlComponents.host == "activate",
                let licenceItem = urlComponents.queryItems?.first,
                licenceItem.name == "licence",
                let jsonString = licenceItem.value?.removingPercentEncoding,
                let data = Data(base64Encoded: jsonString)
            else {
                throw API.V2.Error.invalidLicence
            }

            return data
        }
    }
}

extension API.V2.Licence {
    enum Error: Swift.Error {
        case invalidURL
        case invalidLicence
    }
}
