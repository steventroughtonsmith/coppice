//
//  CoppiceProViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Combine
import Foundation
import M3Subscriptions

protocol CoppiceProView: AnyObject {
    func selectSubscription(from subscriptions: [API.V2.Subscription]) async throws -> API.V2.Subscription
    func deactivateDevice(from devices: [API.V2.ActivatedDevice]) async throws -> API.V2.ActivatedDevice
}

class CoppiceProViewModel {
    weak var view: CoppiceProView?

    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager = .shared) {
        self.subscriptionManager = subscriptionManager

        self.subscribers[.coppiceProState] = subscriptionManager.$state.receive(on: DispatchQueue.main).sink { [weak self] newValue in
            self?.handleStateChange(newValue: newValue)
            self?.updateNeedsLicenceUpgrade()
        }
        self.updateNeedsLicenceUpgrade()
    }


    @Published private(set) var activation: Activation?

    private func handleStateChange(newValue: CoppiceSubscriptionManager.State) {
        guard newValue == .enabled else {
            self.currentContentView = .licence
            self.activation = nil
            return
        }

        defer {
            self.currentContentView = (self.activation != nil) ? .activated : .licence
        }

        switch self.subscriptionManager.activeAPIVersion {
        case .v1:
            guard
                let activationResponse = self.subscriptionManager.v1Controller?.lastResponse,
                let subscription = activationResponse.subscription
            else {
                self.activation = nil
                return
            }
            self.activation = Activation(planName: subscription.name,
                                         expirationTimestamp: subscription.expirationDate.timeIntervalSince1970,
                                         renewalStatus: subscription.renewalStatus,
                                         deviceName: activationResponse.deviceName)
        case .v2:
            let subscription: API.V2.Subscription
            let deviceName: String?
            switch self.subscriptionManager.v2Controller.activationSource {
            case .none:
                self.activation = nil
                return
            case .licence(let licence):
                subscription = licence.subscription
                deviceName = nil
            case .website(let activation):
                subscription = activation.subscription
                deviceName = activation.deviceName
            }
            self.activation = Activation(planName: subscription.name,
                                         expirationTimestamp: subscription.expirationTimestamp,
                                         renewalStatus: subscription.renewalStatus,
                                         deviceName: deviceName)
        }
    }


    //MARK: - Content View
    @Published private(set) var currentContentView: ContentView = .login

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
            try await self.subscriptionManager.v2Controller.login(email: email, password: password)
            let subscriptions = try await self.subscriptionManager.v2Controller.listSubscriptions()

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
            try await self.subscriptionManager.v2Controller.logout()
            //TODO: Handle error
            print("Activation failed: \(error)")
        }
    }

    func activate(withLicenceAtURL url: URL) async throws {
        let licence = try API.V2.Licence(url: url)
        do {
            try self.subscriptionManager.v2Controller.saveLicence(licence)
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
            print("error: \(nsError)")
        }
    }

    private func activate(subscription: API.V2.Subscription) async throws {
        let (maxDeviceCount, devices) = try await self.subscriptionManager.v2Controller.listDevices(subscriptionID: subscription.id)
        //If we're over the limit and our current device is not one of the listed devices then ask to deactivate one
        if (devices.count) >= maxDeviceCount, devices.contains(where: { $0.isCurrent == true }) == false {
            guard let view = self.view else {
                fatalError()
            }
            let deviceToDeactivate = try await view.deactivateDevice(from: devices)
            try await self.subscriptionManager.v2Controller.deactivate(activationID: deviceToDeactivate.id)
        }

        try await self.subscriptionManager.v2Controller.activate(subscriptionID: subscription.id)
    }

    func deactivate() async throws {
        do {
            switch self.subscriptionManager.activeAPIVersion {
            case .v1:
                _ = try await self.subscriptionManager.v1Controller?.deactivate()
            case .v2:
                try await self.subscriptionManager.v2Controller.deactivate()
                try await self.subscriptionManager.v2Controller.logout()
            }
            self.currentContentView = .login
        } catch {
            //TODO: Handle error
            print("Error deactivating: \(error)")
        }
    }

    var canRename: Bool {
        guard
            self.subscriptionManager.state == .enabled,
            self.subscriptionManager.activeAPIVersion == .v2,
            case .website = self.subscriptionManager.v2Controller.activationSource
        else {
            return false
        }
        return true
    }

    func rename(to newName: String) async throws {
        do {
            guard self.canRename else {
                return
            }
            try await self.subscriptionManager.v2Controller.renameDevice(to: newName)
        } catch {
            //TODO: Handle Error
        }
    }

    //MARK: - Licence Upgrade
    @Published var needsLicenceUpgrade: Bool = false

    private func updateNeedsLicenceUpgrade() {
        guard
            self.subscriptionManager.state == .enabled,
            self.subscriptionManager.activeAPIVersion == .v1
        else {
            self.needsLicenceUpgrade = false
            return
        }
        self.needsLicenceUpgrade = true
    }

    func startLicenceUpgrade() {
        self.currentContentView = .login
    }


    //MARK: - Subscribers
    private enum SubscriberKey {
        case coppiceProState
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    //MARK: - Status Helper Functions
    static func localizedStatus(expirationTimestamp: TimeInterval, renewalStatus: RenewalStatus) -> String {
        if expirationTimestamp < Date().timeIntervalSince1970 {
            return NSLocalizedString("Expired", comment: "Expired subscription state")
        }
        if renewalStatus == .failed {
            return NSLocalizedString("Billing Failed", comment: "Billing Failed subscription state")
        }

        return NSLocalizedString("Active", comment: "Active subscription state")
    }

    static func localizedStatusDetails(expirationTimestamp: TimeInterval, renewalStatus: RenewalStatus) -> String {
        let format: String
        if expirationTimestamp < Date().timeIntervalSince1970 {
            format = NSLocalizedString("(expired on %@)", comment: "'expired on <date>' expired subscription info label")
        } else {
            switch renewalStatus {
            case .renew:
                format = NSLocalizedString("(will renew on %@)", comment: "'will renew on <date>' active subscription info label")
            case .cancelled, .failed:
                format = NSLocalizedString("(will expire on %@)", comment: "'will expire on <date>' active subscription that will expire (due to billing failure or the user cancelling) info label")
            default:
                return ""
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .none

        let date = Date(timeIntervalSince1970: expirationTimestamp)
        return String(format: format, dateFormatter.string(from: date))
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
        var expirationTimestamp: TimeInterval
        var renewalStatus: RenewalStatus
        var deviceName: String?
    }
}
