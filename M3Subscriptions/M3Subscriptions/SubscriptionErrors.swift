//
//  SubscriptionErrors.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 11/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

enum SubscriptionErrorCodes: Int {
    case unknown = -1
    case other = 0
    case loginFailed = 1
    case multipleSubscriptions
    case noSubscriptionFound
    case subscriptionExpired
    case tooManyDevices
    case noDeviceFound
}

class SubscriptionErrorFactory {
    static let domain = "com.mcubedsw.Subscriptions"

    static func error(for: ActivateAPI.Failure) -> NSError {
        return self.createError(code: .unknown, localizedDescription: "", localizedRecoverySuggestion: "")
    }

    static func error(for: CheckAPI.Failure) -> NSError {
        return self.createError(code: .unknown, localizedDescription: "", localizedRecoverySuggestion: "")
    }

    static func error(for failure: DeactivateAPI.Failure) -> NSError {
        switch failure {
        case .noDeviceFound:
            return self.createError(code: .noDeviceFound,
                                    localizedDescription: SubscriptionStrings.Deactivation.noDeviceFoundDescription,
                                    localizedRecoverySuggestion: SubscriptionStrings.Deactivation.noDeviceFoundRecovery)
        case .generic(let error):
            return self.createError(code: .other,
                                    localizedDescription: SubscriptionStrings.Deactivation.genericDescription,
                                    localizedRecoverySuggestion: SubscriptionStrings.Deactivation.genericRecovery,
                                    additionalOptions: (error != nil) ? [NSUnderlyingErrorKey: error!] : nil)
        }
    }

    static func createError(code: SubscriptionErrorCodes, localizedDescription: String, localizedRecoverySuggestion: String, additionalOptions: [String: Any]? = nil) -> NSError {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: localizedDescription,
            NSLocalizedRecoverySuggestionErrorKey: localizedRecoverySuggestion
        ]
        if let options = additionalOptions {
            userInfo.merge(options, uniquingKeysWith: { arg1, arg2 in arg1 })
        }
        return NSError(domain: self.domain, code: code.rawValue, userInfo: userInfo)
    }
}

struct SubscriptionStrings {
    static let unknownDescription = NSLocalizedString("Oops. Something went wrong.", comment: "Unknown Error Description")
    static let unknownRecovery = NSLocalizedString("Please try again. If the problem persists please contact M Cubed Support.", comment: "Unknown Error Recovery")

    struct Deactivation {
        static let genericDescription = NSLocalizedString("Deactivation Failed", comment: "Generic Deactivation Error Description")
        static let genericRecovery = NSLocalizedString("Please check your internet connection and try again. If the problem persists please contact M Cubed Support.", comment: "Generic Deactivation Error Description")

        static let noDeviceFoundDescription = NSLocalizedString("Your Device Was Already Deactivated", comment: "No Device Found Deactivation Error Description")
        static let noDeviceFoundRecovery = NSLocalizedString("If you think this is a mistake, please log into your M Cubed Account and try deactivating from there", comment: "No Device Found Deactivation Error Description")
    }
}
