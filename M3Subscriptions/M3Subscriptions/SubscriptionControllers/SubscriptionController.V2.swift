//
//  SubscriptionController.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension SubscriptionController {
    public class V2 {
        //MARK: - Authentication
        public func login(email: String, password: String, deviceName: String) async throws {
            
        }
        
        public func logout() async throws {
            
        }
        
        public func saveLicence() {
            
        }
        
        
        //MARK: - Activation
        public func activate(deviceName: String, subscriptionID: String? = nil) async throws {
            //version, deviceID, deviceType
        }
        
        public func check() async throws {
            //activationID, version, deviceID
        }
        
        public func listSubscriptions() async throws -> [Subscription] {
            //bundleID:
            return []
        }
        
        public func listDevices(subscriptionID: String) async throws -> [SubscriptionDevice] {
            //deviceID: String, deviceType: String
            return []
        }
        
        public func renameDevice(to name: String) async throws {
            //activationID, device name
        }
        
        public func deactivate() async throws {
            
        }
        
        

    }
}
