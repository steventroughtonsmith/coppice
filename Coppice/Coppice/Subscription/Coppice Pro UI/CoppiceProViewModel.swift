//
//  CoppiceProViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Foundation
import M3Subscriptions

protocol CoppiceProView: AnyObject {
    func selectSubscription(from subscriptions: [Subscription]) async throws -> Subscription
    func deactivateDevice(from devices: [SubscriptionDevice]) async throws -> SubscriptionDevice
}

class CoppiceProViewModel {
    weak var view: CoppiceProView?

    @Published private(set) var activation: Activation?

    //MARK: - Content View
    @Published private(set) var currentContentView: ContentView = .activated

    func switchToLogin() {
        guard self.currentContentView == .licence else {
            return
        }
        self.currentContentView = .login
    }

    func switchToLicence() {
        guard self.currentContentView == .login else {
            return
        }
        self.currentContentView = .licence
    }



    //MARK: - Activation Actions
    func activateWithLogin(email: String, password: String) async throws {

        //Login
        //Get subscription list
        //if > 1
            //show subs
        //activate
            //on too many devices
                //fetch list
                //activate again
        //Finish activation

        if let view = self.view {
            _ = try await view.selectSubscription(from: [
                .init(id: UUID().uuidString,
                      name: "Coppice Pro (Annual Subscription)",
                      expirationDate: Date(timeIntervalSinceNow: 900000),
                      hasExpired: false,
                      renewalStatus: .renew),
                .init(id: UUID().uuidString,
                      name: "Coppice Pro (Free Trial)",
                      expirationDate: Date(timeIntervalSinceNow: 90000),
                      hasExpired: false,
                      renewalStatus: .renew)
            ])
        }

        self.activation = Activation(planName: "Coppice Pro (Annual Subscription)",
                                     status: "Billing Failed (will expire on 6 August 2023)",
                                     deviceName: "Martin's Mac Studio")

        self.currentContentView = .activated
    }

    func activate(withLicenceAtURL url: URL) async throws {
        //Create licence
        //activate
            //on too many devices
                //fetch list
                //activate again
            //

        self.activation = Activation(planName: "Coppice Pro (Free Trial)",
                                     status: "Active (will expire on 6 August 2024)",
                                     deviceName: nil)

        if let view = self.view {
            _ = try await view.deactivateDevice(from: [
                .init(deactivationToken: UUID().uuidString,
                      name: "Martin's Mac Studio",
                      activationDate: Date(timeIntervalSinceNow: -500000)),
                .init(deactivationToken: UUID().uuidString,
                      name: "Martin's iMac",
                      activationDate: Date(timeIntervalSinceNow: -90000)),
                .init(deactivationToken: UUID().uuidString,
                      name: "Bob's MacBook Pro",
                      activationDate: Date(timeIntervalSinceNow: -1500000))
            ])
        }
        self.currentContentView = .activated
        //Determine if url is activation url or file url

//- On drop, check licence
    //- Send to server to activate
    //- On Success
        //Activate
    //- On network or server failure
        //Use licence
    //- On too many devices
        //fetch device list
        //on cancel don't activate
        //on select
            //deactivate selected device
            //activate
    }

    func deactivate() async throws {
    //on deactivate
        //Call deactivate
        //If logged in, log out
        self.currentContentView = .login
    }

    func rename(to newName: String) async throws {

    }
}

extension CoppiceProViewModel {
    enum Error: Swift.Error {
        case userCancelled
    }

    enum ContentView {
        case login
        case licence
        case activated
    }

    struct Activation {
        var planName: String
        var status: String
        var deviceName: String?
    }
}
