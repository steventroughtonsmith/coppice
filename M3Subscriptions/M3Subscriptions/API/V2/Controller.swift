//
//  Controller.swift
//  M3Subscriptions
//
//  Created by Martin Pilkington on 07/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension API.V2 {
    public class Controller {
        //MARK: - Authentication
        public func login(email: String, password: String) async throws {
            
        }

        public func logout() throws {

        }

        public func saveLicence(_ licence: Any) throws {

        }


        //MARK: - Activation
        public func activate(subscriptionID: String? = nil) async throws {
            //version, deviceID, deviceType, deviceName
        }
        
        public func check() async throws {
            //activationID, version, deviceID
        }
        
        public func listSubscriptions() async throws -> [Subscription] {
            //bundleID:
            return []
        }
        
        public func listDevices(subscriptionID: String) async throws -> [ActivatedDevice] {
            //deviceID: String, deviceType: String
            return []
        }
        
        public func renameDevice(to name: String) async throws {
            //activationID, device name
        }
        
        public func deactivate(activationID: String? = nil) async throws {

        }
        
        

    }
}
