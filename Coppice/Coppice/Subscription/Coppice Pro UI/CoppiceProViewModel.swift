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
    func selectSubscription(from subscriptions: [API.V2.Subscription]) async throws -> API.V2.Subscription
    func deactivateDevice(from devices: [API.V2.ActivatedDevice]) async throws -> API.V2.ActivatedDevice
}

class CoppiceProViewModel {
    weak var view: CoppiceProView?

    let subscriptionController: API.V2.Controller
    init(subscriptionController: API.V2.Controller) {
        self.subscriptionController = subscriptionController
    }


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
        do {
            try await self.subscriptionController.login(email: email, password: password)
            let subscriptions = try await self.subscriptionController.listSubscriptions()

            let selectedSubscription: API.V2.Subscription
            if subscriptions.count > 1, let view = self.view {
                selectedSubscription = try await view.selectSubscription(from: subscriptions)
            } else if subscriptions.count == 1 {
                selectedSubscription = subscriptions[0]
            } else {
                fatalError()
            }

            try await self.activate(subscription: selectedSubscription)
            self.currentContentView = .activated
        } catch {
            try self.subscriptionController.logout()
            //TODO: Handle error
        }
    }

    func activate(withLicenceAtURL url: URL) async throws {
        let licence = API.V2.Licence(url: url)
        do {
            try self.subscriptionController.saveLicence(licence)
        } catch {
            //TODO: Handle Error
        }

        do {
            try await self.activate(subscription: licence.subscription)
            self.currentContentView = .activated
        } catch let error as API.V2.Error {
            guard case .couldNotConnectToServer(let nsError) = error else {
                throw error
            }
            //TODO: Activate with licence
            print("error: \(nsError)")
        }
    }

    private func activate(subscription: API.V2.Subscription) async throws {
        let devices = try await self.subscriptionController.listDevices(subscriptionID: subscription.id)
        if (devices.count) >= subscription.maxDeviceCount! {
            guard let view = self.view else {
                fatalError()
            }
            let deviceToDeactivate = try await view.deactivateDevice(from: devices)
            try await self.subscriptionController.deactivate(activationID: deviceToDeactivate.id)
        }

        try await self.subscriptionController.activate(subscriptionID: subscription.id)
    }

    func deactivate() async throws {
        do {
            //TODO: Handle V1 deactivation
            try await self.subscriptionController.deactivate()
            self.currentContentView = .login
        } catch {
            //TODO: Handle error
        }
    //on deactivate
        //Call deactivate
        //If logged in, log out
    }

    func rename(to newName: String) async throws {
        do {
            try await self.subscriptionController.renameDevice(to: newName)
        } catch {
            //TODO: Handle Error
        }
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
