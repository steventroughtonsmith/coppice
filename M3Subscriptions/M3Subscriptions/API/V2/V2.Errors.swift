//
//  V2.Errors.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 24/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public enum Error: Swift.Error {
        case generic(Swift.Error)
        case invalidAuthenticationMethod //All
        case loginFailed //All
        case invalidLicence //D, C
        case noSubscriptionFound //C, A, R, Ld
        case subscriptionExpired //C, A, R
        case tooManyDevices //A
        case noDeviceFound //D, C, R
        case notActivated //C
        case couldNotConnectToServer(NSError) //All
        case invalidResponse
        case noTrialAvailable
        case trialUsed
    }
}

extension API.V2.Error {
    init?(apiResponse: APIData.Response) {
        switch apiResponse {
        case .active, .deactivated, .success, .loggedIn, .loggedOut: // Not errors
            return nil
        case .multipleSubscriptions: // No longer errors
            self = .invalidResponse
        case .loginFailed:
            self = .loginFailed
        case .noSubscriptionFound:
            self = .noSubscriptionFound
        case .noDeviceFound:
            self = .noDeviceFound
        case .tooManyDevices:
            self = .tooManyDevices
        case .expired:
            self = .subscriptionExpired
        case .invalidLicence:
            self = .invalidLicence
        case .noTrialAvailable:
            self = .noTrialAvailable
        case .trialUsed:
            self = .trialUsed
        case .other:
            self = .invalidResponse
        }
    }
}

extension API.V2.Error: CustomNSError {
    public static var errorDomain: String {
        return "com.mcubedsw.API.V2"
    }

    public var errorCode: Int {
        switch self {
        case .generic:                      return 1
        case .invalidAuthenticationMethod:  return 2
        case .loginFailed:                  return 3
        case .invalidLicence:               return 4
        case .noSubscriptionFound:          return 5
        case .subscriptionExpired:          return 6
        case .tooManyDevices:               return 7
        case .noDeviceFound:                return 8
        case .notActivated:                 return 9
        case .couldNotConnectToServer:      return 10
        case .invalidResponse:              return 11
        case .noTrialAvailable:             return 12
        case .trialUsed:                    return 13
        }
    }

    public var errorUserInfo: [String: Any] {
        var userInfo: [String: Any] = [
            NSLocalizedDescriptionKey: self.errorDescription ?? "Something went wrong",
            NSLocalizedRecoverySuggestionErrorKey: self.recoverySuggestion ?? "",
        ]
        switch self {
        case .generic(let error as NSError):
			userInfo[NSUnderlyingErrorKey] = error
        case .couldNotConnectToServer(let error):
            userInfo[NSUnderlyingErrorKey] = error
        default:
            break
        }
        return userInfo
    }
}

extension API.V2.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .generic:
            return NSLocalizedString("Oops. Something went wrong.", comment: "Unknown Error Description")
        case .invalidAuthenticationMethod:
            return NSLocalizedString("Invalid authentication method", comment: "Invalid Auth Method Description")
        case .loginFailed:
            return NSLocalizedString("Your Login Details Were Incorrect", comment: "Login Failed Error Description")
        case .invalidLicence:
            return NSLocalizedString("Your Licence Was Invalid", comment: "Invalid Licence Error Description")
        case .noSubscriptionFound:
            return NSLocalizedString("No Subscription Found", comment: "No Subscription Found Error Description Format")
        case .subscriptionExpired:
            return NSLocalizedString("Your Subscription Has Expired", comment: "Subscription Expired Error Description")
        case .tooManyDevices:
            return NSLocalizedString("You Have Reached Your Device Limit", comment: "Device Limit Reached Error Description")
        case .noDeviceFound:
            return NSLocalizedString("Your Device Was Not Found on Your Account", comment: "No Device Found Subscription Error Description")
        case .notActivated:
            return NSLocalizedString("Your Device Is Not Activated", comment: "Device Not Activated Error Description")
        case .couldNotConnectToServer:
            return NSLocalizedString("Could Not Contact M Cubed's Servers", comment: "Could Not Connect To Server Error Description")
        case .invalidResponse:
            return NSLocalizedString("Oops. Something went wrong", comment: "Action failed Error Description")
        case .noTrialAvailable:
            return NSLocalizedString("Trial Not Available", comment: "No Trial Available Error Description")
        case .trialUsed:
            return NSLocalizedString("Free Trial Used", comment: "Trial Used Error Description")
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .generic:
            return NSLocalizedString("Please try again. If the problem persists please contact M Cubed Support.", comment: "Unknown Error Recovery")
        case .invalidAuthenticationMethod:
            return NSLocalizedString("Please check your details and try again.", comment: "Invalid Authentication Method Error Recovery")
        case .loginFailed:
            return NSLocalizedString("Please check your details and try again.", comment: "Login Failed Error Recovery")
        case .invalidLicence:
            return NSLocalizedString("Please try again. If the problem persists re-generate your licence from the M Cubed Website", comment: "Invalid Licence Error Recovery")
        case .noSubscriptionFound:
            return NSLocalizedString("Upgrade to Coppice Pro to get access to all of Coppice's functionality.", comment: "No Subscription Found Error Recovery")
        case .subscriptionExpired:
            return NSLocalizedString("You can renew your subscription at https://mcubedsw.com.", comment: "Subscription Expired Error Recovery")
        case .tooManyDevices:
            return NSLocalizedString("If you wish to activate this device, please select another device to deactivate", comment: "Device Limit Reached Limit Reached Error Recovery")
        case .noDeviceFound:
            return NSLocalizedString("Please re-activate if you wish to continue using this device with your subscription.", comment: "No Device Found Subscription Error Recovery")
        case .notActivated:
            return NSLocalizedString("Please try activating again. If the problem persists please contact M Cubed Support", comment: "Not Activated Error Recovery")
        case .couldNotConnectToServer:
            return NSLocalizedString("Please check your internet connection and try again. If the problem persists please contact M Cubed Support", comment: "Could Not Connect To Server Error Recovery")
        case .invalidResponse:
            return NSLocalizedString("Coppice got bad data back from the server. Please try again.", comment: "Action failed Error Description")
        case .noTrialAvailable:
            return NSLocalizedString("There is no trial currently available for Coppice. Try again later", comment: "Trial unavailable Recovery Suggestion")
        case .trialUsed:
            return NSLocalizedString("You have already used your free trial of Coppice Pro. Please purchase from https://mcubedsw.com/coppice to continue using Coppice Pro", comment: "Trial used Recovery Suggestion")
        }
    }
}
