//
//  SubscriptionErrors.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 11/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V1 {
    public enum SubscriptionErrorCodes: Int {
        case unknown = -1
        case other = 0
        case loginFailed = 1
        case noSubscriptionFound
        case multipleSubscriptionsFound
        case subscriptionExpired
        case noDeviceFound
        case tooManyDevices
        case notActivated
        case couldNotConnectToServer
    }
    
    public class SubscriptionErrorFactory {
        public static let domain = "com.mcubedsw.Subscriptions"
        
        public struct InfoKeys {
            public static let subscription = "M3SubscriptionErrorSubscriptionKey"
            public static let subscriptionPlans = "M3SubscriptionErrorSubscriptionPlansKey"
            public static let devices = "M3SubscriptionErrorDevicesKey"
            public static let context = "M3SubscriptionErrorContextKey"
            public static let moreInfoTitle = "M3SubscriptionErrorMoreInfoTitleKey"
            public static let moreInfoURL = "M3SubscriptionErrorMoreInfoURLKey"
        }
        
        public enum ErrorContext: String {
            case activate
            case check
            case deactivate
        }
        
        static func error(for failure: Error) -> NSError {
            if let activationFailure = failure as? API.V1.ActivateAPI.Failure {
                return self.error(for: activationFailure)
            } else if let checkFailure = failure as? API.V1.CheckAPI.Failure {
                return self.error(for: checkFailure)
            } else if let deactivateFailure = failure as? API.V1.DeactivateAPI.Failure {
                return self.error(for: deactivateFailure)
            }
            return failure as NSError
        }
        
        static func error(for failure: API.V1.ActivateAPI.Failure) -> NSError {
            switch failure {
            case .generic(let error as NSError) where error.domain == NSURLErrorDomain:
                return self.createError(code: .couldNotConnectToServer, context: .activate, additionalOptions: [NSUnderlyingErrorKey: error])
            case .generic(let error):
                return self.createError(code: .other, context: .activate, additionalOptions: (error != nil) ? [NSUnderlyingErrorKey: error!] : nil)
            case .invalidRequest:
                return self.createError(code: .other, context: .activate)
            case .loginFailed:
                return self.createError(code: .loginFailed, context: .activate, additionalOptions: [
                    InfoKeys.moreInfoTitle: NSLocalizedString("Forgot Password…", comment: "Forgot password button"),
                    InfoKeys.moreInfoURL: URL(string: "https://mcubedsw.com/forgot_password")!,
                ])
            case .noSubscriptionFound:
                return self.createError(code: .noSubscriptionFound, context: .activate, additionalOptions: [
                    InfoKeys.moreInfoTitle: NSLocalizedString("Find Out More…", comment: "Find out more about Coppice Pro button"),
                    InfoKeys.moreInfoURL: URL(string: "https://coppiceapp.com/pro")!,
                ])
            case .subscriptionExpired(let subscription):
                var additionalOptions: [String: Any] = [
                    InfoKeys.moreInfoTitle: NSLocalizedString("Renew", comment: "Renew Coppice Pro button"),
                    InfoKeys.moreInfoURL: URL(string: "https://coppiceapp.com/pro")!,
                ]
                if let subscription = subscription {
                    additionalOptions[InfoKeys.subscription] = subscription
                }
                return self.createError(code: .subscriptionExpired, context: .activate, additionalOptions: additionalOptions)
            case .tooManyDevices(let devices):
                return self.createError(code: .tooManyDevices, context: .activate, additionalOptions: [InfoKeys.devices: devices])
            case .multipleSubscriptions(let plans):
                return self.createError(code: .multipleSubscriptionsFound, context: .activate, additionalOptions: [InfoKeys.subscriptionPlans: plans])
            }
        }
        
        static func error(for failure: API.V1.CheckAPI.Failure) -> NSError {
            switch failure {
            case .generic(let error as NSError) where error.domain == NSURLErrorDomain:
                return self.createError(code: .couldNotConnectToServer, context: .check, additionalOptions: [NSUnderlyingErrorKey: error])
            case .generic(let error):
                return self.createError(code: .other, context: .check, additionalOptions: (error != nil) ? [NSUnderlyingErrorKey: error!] : nil)
            case .noDeviceFound:
                return self.createError(code: .noDeviceFound, context: .check)
            case .noSubscriptionFound:
                return self.createError(code: .noSubscriptionFound, context: .check)
            case .subscriptionExpired(let subscription):
                return self.createError(code: .subscriptionExpired, context: .check, additionalOptions: (subscription != nil) ? [InfoKeys.subscription: subscription!] : nil)
            }
        }
        
        static func error(for failure: API.V1.DeactivateAPI.Failure) -> NSError {
            switch failure {
            case .noDeviceFound:
                return self.createError(code: .noDeviceFound, context: .deactivate)
            case .generic(let error as NSError) where error.domain == NSURLErrorDomain:
                return self.createError(code: .couldNotConnectToServer, context: .deactivate, additionalOptions: [NSUnderlyingErrorKey: error])
            case .generic(let error):
                return self.createError(code: .other, context: .deactivate, additionalOptions: (error != nil) ? [NSUnderlyingErrorKey: error!] : nil)
            }
        }
        
        static func notActivatedError() -> NSError {
            return self.createError(code: .notActivated, context: .activate)
        }
        
        private static func createError(code: SubscriptionErrorCodes, context: ErrorContext, additionalOptions: [String: Any]? = nil) -> NSError {
            var userInfo: [String: Any] = [
                NSLocalizedDescriptionKey: code.localizedDescription(for: context),
                NSLocalizedRecoverySuggestionErrorKey: code.localizedRecoverySuggestion(for: context),
                InfoKeys.context: context.rawValue,
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
}

extension API.V1.SubscriptionErrorCodes {
    fileprivate func localizedDescription(for context: API.V1.SubscriptionErrorFactory.ErrorContext) -> String {
        switch self {
        case .unknown:
            return NSLocalizedString("Oops. Something went wrong.", comment: "Unknown Error Description")
        case .other:
            if case .deactivate = context {
                return NSLocalizedString("Deactivation Failed", comment: "Generic Deactivation Error Description")
            }
        case .loginFailed:
            return NSLocalizedString("Your Login Details Were Incorrect", comment: "Login Failed Error Description")
        case .noSubscriptionFound:
            guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
                return NSLocalizedString("No Subscription Found", comment: "No Subscription Found Error Description Format")
            }
            let format = NSLocalizedString("No Subscription Found For %@", comment: "No Subscription Found for <app> Error Description Format")
            return String(format: format,  appName)
        case .multipleSubscriptionsFound:
            guard let appName = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String else {
                return NSLocalizedString("Multiple Subscriptions Found", comment: "Multiple Subscriptions Found Error Description Format")
            }
            let format = NSLocalizedString("Multiple Subscriptions Found For %@", comment: "Multiple Subscriptions Found for <app> Error Description Format")
            return String(format: format,  appName)
        case .subscriptionExpired:
            return NSLocalizedString("Your Subscription Has Expired", comment: "Subscription Expired Error Description")
        case .noDeviceFound:
            return NSLocalizedString("Your Device Was Not Found on Your Account", comment: "No Device Found Subscription Error Description")
        case .tooManyDevices:
            return NSLocalizedString("You Have Reached Your Device Limit", comment: "Device Limit Reached Error Description")
        case .notActivated:
            return NSLocalizedString("Your Device Is Not Activated", comment: "Device Not Activated Error Description")
        case .couldNotConnectToServer:
            return NSLocalizedString("Could Not Contact M Cubed's Servers", comment: "Could Not Connect To Server Error Description")
        }
        return NSLocalizedString("Oops. Something went wrong.", comment: "Unknown Error Description")
    }

    fileprivate func localizedRecoverySuggestion(for context: API.V1.SubscriptionErrorFactory.ErrorContext) -> String {
        switch self {
        case .unknown:
            return NSLocalizedString("Please try again. If the problem persists please contact M Cubed Support.", comment: "Unknown Error Recovery")
        case .other:
            if case .deactivate = context {
                return NSLocalizedString("Please check your internet connection and try again. If the problem persists please contact M Cubed Support.", comment: "Generic Deactivation Error Description")
            }
        case .loginFailed:
            return NSLocalizedString("Please check your details and try again.", comment: "Login Failed Error Recovery")
        case .noSubscriptionFound:
            return NSLocalizedString("Upgrade to Coppice Pro to get access to all of Coppice's functionality.", comment: "No Subscription Found Error Recovery")
        case .multipleSubscriptionsFound:
            return NSLocalizedString("Please choose which subscription to activate this device on", comment: "Multiple Subscriptions Found Error Recovery")
        case .subscriptionExpired:
            return NSLocalizedString("You can renew your subscription by purchasing through our website.", comment: "Subscription Expired Error Recovery")
        case .noDeviceFound:
            return NSLocalizedString("Please re-activate if you wish to continue using this device with your subscription.", comment: "No Device Found Subscription Error Recovery")
        case .tooManyDevices:
            return NSLocalizedString("If you wish to activate this device, please select another device to deactivate", comment: "Device Limit Reached Limit Reached Error Recovery")
        case .notActivated:
            return NSLocalizedString("Please try activating again. If the problem persists please contact M Cubed Support", comment: "Not Activated Error Recovery")
        case .couldNotConnectToServer:
            return NSLocalizedString("Please check your internet connection and try again. If the problem persists please contact M Cubed Support", comment: "Could Not Connect To Server Error Recovery")
        }
        return NSLocalizedString("Please try again. If the problem persists please contact M Cubed Support.", comment: "Unknown Error Recovery")
    }
}
