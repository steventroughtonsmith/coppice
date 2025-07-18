//
//  CoppiceSubscriptionManager.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import M3Subscriptions

protocol CoppiceSubscriptionManagerDelegate: AnyObject {
    func showCoppicePro(with error: NSError, for subscriptionManager: CoppiceSubscriptionManager)
    func showInfoAlert(_ infoAlert: InfoAlert, for subscriptionManager: CoppiceSubscriptionManager)
    func presentViewController(_ viewController: NSViewController, for subscriptionManager: CoppiceSubscriptionManager) -> Bool
}

class CoppiceSubscriptionManager: NSObject {
    private(set) static var shared: CoppiceSubscriptionManager!
    static func initializeManager() throws {
        let url = try CoppiceApplication.appSupportDirectory
        CoppiceSubscriptionManager.shared = CoppiceSubscriptionManager(appSupportURL: url)
    }

    //MARK: - Init
    let v1Controller: API.V1.SubscriptionController?
    let v2Controller: API.V2.Controller
    init(appSupportURL: URL) {
        let licenceURL = appSupportURL.appendingPathComponent("Licence.coppicelicence")
        let activationURL = appSupportURL.appendingPathComponent("Activation")
        let trialLicenceURL = appSupportURL.appendingPathComponent(".Trial.coppicelicence")
        self.v2Controller = API.V2.Controller(licenceURL: licenceURL, activationURL: activationURL, trialLicenceURL: trialLicenceURL)

        //Activation details were never put in the /Coppice directory
        let v1ActivationDetails = appSupportURL.deletingLastPathComponent().appendingPathComponent("licence")
        if case .none = self.v2Controller.activationSource, FileManager.default.fileExists(atPath: v1ActivationDetails.path) {
            self.v1Controller = API.V1.SubscriptionController(activationDetailsURL: v1ActivationDetails)
        } else {
            self.v1Controller = nil
        }

        super.init()

        if let controller = self.v1Controller {
            self.subscribers[.v1SubscriberResponse] = controller.$lastResponse.sink { [weak self] response in
                if response?.isActive == false {
                    self?.state = .unknown
                }
            }
        }

        self.subscribers[.v2ActivationSource] = self.v2Controller.$activationSource.receive(on: DispatchQueue.main).sink { [weak self] source in
            self?.state = (source.isActivated) ? .enabled : .unknown
        }

        self.checkSubscriptionIfNeeded()
        DispatchQueue.main.async {
            self.notifyOfAPIUpgradeIfNeeded()
        }
    }

    deinit {
        print("deinit subscription manager")
    }

    //MARK: - Delegate
    weak var delegate: CoppiceSubscriptionManagerDelegate?

    //MARK: - State
    @Published var currentCheckError: NSError?

    enum State {
        case unknown
        case enabled
        case expired
    }

    @Published private(set) var state: State = .unknown
    #if DEBUG
    func debug_updateState(_ state: State) {
        self.state = state
    }
    #endif


    //MARK: - API Version
    enum APIVersion {
        case v1
        case v2
    }

    var activeAPIVersion: APIVersion {
        if case .none = self.v2Controller.activationSource, self.v1Controller != nil {
            return .v1
        }
        return .v2
    }

    private var hasNotifiedSinceLaunch: Bool = false
    private func notifyOfAPIUpgradeIfNeeded() {
        guard
            self.hasNotifiedSinceLaunch == false,
            self.activeAPIVersion == .v1
        else {
            return
        }


        let alert = InfoAlert(id: "apiUpgrade",
                              level: .warning,
                              title: "Coppice has updated its licence system",
                              message: "Go to Coppice > Settings… > Coppice Pro to upgrade and get access to the latest features",
                              autodismiss: false)
        self.delegate?.showInfoAlert(alert, for: self)
        self.hasNotifiedSinceLaunch = true
    }

    //MARK: - Automatic actions
    private(set) var recheckTimer: Timer?
    private(set) var lastCheck: Date?

    func checkSubscriptionIfNeeded() {
        var checkInterval: TimeInterval = 86400
        //Increase the times we check if billing has failed to 4 times a day
        if
            case .website(let activation) = self.v2Controller.activationSource,
            (activation.subscription.renewalStatus == .failed)
        {
            checkInterval /= 4
        }

        guard let lastCheck = self.lastCheck else {
            self.checkSubscription()
            return
        }

        if (Date().timeIntervalSince(lastCheck) > min(checkInterval, 86400)) {
            self.checkSubscription()
        } else {
            self.recheckInAnHour()
        }
    }

    func checkSubscription() {
        Task {
            do {
                if self.activeAPIVersion == .v1, let controller = self.v1Controller {
                    let activationResponse = try await controller.checkSubscription()
                    self.state = activationResponse.isActive ? .enabled : .unknown
                } else if case .licence(let licence) = self.v2Controller.activationSource {
                    do {
                        //Only activate if licence is an active trial or a full licence
                        if licence.isActive || licence.subscription.renewalStatus != .trial {
                            try await self.activate(licence: licence)
                        }
                    } catch API.V2.Error.invalidLicence {
                        throw API.V2.Error.invalidLicence
                    } catch {
                        print("Failed to activate, fall back to licence state")
                    }
                    self.updateStateFromActivationSource()
                } else {
                    try await self.v2Controller.check()
                    self.updateStateFromActivationSource()
                }
                self.currentCheckError = nil
            } catch let error as API.V2.Error {
                self.handleCheckError(error)
            } catch {
                print("Unknown error!")
            }
            Task { @MainActor in
                self.completeCheck()
            }
        }
    }


    private func activate(licence: API.V2.Licence) async throws {
        let (maxDeviceCount, devices) = try await self.v2Controller.listDevices(subscriptionID: licence.subscription.id)
        //If we're over the limit and our current device is not one of the listed devices then ask to deactivate one
        if (devices.count) >= maxDeviceCount, devices.contains(where: { $0.isCurrent == true }) == false {
            let deviceToDeactivate = try await self.deactivateDevice(from: devices)
            try await self.v2Controller.deactivate(activationID: deviceToDeactivate.id)
        }

        try await self.v2Controller.activate(subscriptionID: licence.subscription.id)
    }

    private func deactivateDevice(from devices: [API.V2.ActivatedDevice]) async throws -> API.V2.ActivatedDevice {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let devicesVC = TooManyDevicesViewController(devices: devices) { selectedDevice in
                    guard let selectedDevice else {
                        continuation.resume(throwing: CoppiceProViewModel.Error.userCancelled)
                        return
                    }
                    continuation.resume(returning: selectedDevice)
                }
                guard self.delegate?.presentViewController(devicesVC, for: self) ?? false else {
                    continuation.resume(throwing: CoppiceProViewModel.Error.userCancelled)
                    return
                }
            }
        }
    }

    private func handleCheckError(_ error: API.V2.Error) {
        switch error {
        case .subscriptionExpired:
            self.state = .expired
        case .invalidAuthenticationMethod, .invalidLicence, .noSubscriptionFound, .noDeviceFound, .notActivated:
            Task { @MainActor in
                self.delegate?.showCoppicePro(with: error as NSError, for: self)
                self.state = .unknown
            }
        case .generic, .invalidResponse, .couldNotConnectToServer:
            self.updateStateFromActivationSource()
        case .tooManyDevices, .loginFailed, .trialUsed, .noTrialAvailable:
            break //ignore
        }
    }

    private func updateStateFromActivationSource() {
        guard self.v2Controller.activationSource.isActivated else {
            self.state = .unknown
            return
        }

        self.state = self.v2Controller.activationSource.isValid ? .enabled : .expired
    }

    private func completeCheck() {
        guard self.state == .enabled else {
            self.recheckTimer?.invalidate()
            self.recheckTimer = nil
            return
        }

        self.lastCheck = Date()
        self.recheckInAnHour()
    }

    private func recheckInAnHour() {
        self.recheckTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: false) { [weak self] _ in
            self?.checkSubscriptionIfNeeded()
        }
    }


    //MARK: - Notify of changes
    func notifyOfChanges() {
        guard
            case .website(let activation) = self.v2Controller.activationSource,
            let delegate = self.delegate
        else {
            return
        }

        let infoAlert: InfoAlert
        switch activation.secondaryState {
        case .justExpired:
            infoAlert = InfoAlert(id: "justExpired",
                                  level: .warning,
                                  title: "Your Coppice Pro subscription has expired.",
                                  message: "You can always upgrade again through our website.",
                                  autodismiss: false)
        case .justRenewed:
            infoAlert = InfoAlert(id: "justRenewed", level: .info, title: "Thank you for renewing your subscription!")
        case .billingFailed:
            infoAlert = InfoAlert(id: "billingFailed",
                                  level: .error,
                                  title: "We were unable to renew your Coppice Pro subscription.",
                                  message: "Please log into your M Cubed Account and update your billing info.",
                                  autodismiss: false)
        case .none:
            return
        }

        delegate.showInfoAlert(infoAlert, for: self)
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case v1SubscriberResponse
        case v2ActivationSource
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]


    //MARK: - Debug
    #if DEBUG
    private var previousState: State?

    var proDisabled = false {
        didSet {
            guard self.proDisabled != oldValue else {
                return
            }

            if self.proDisabled {
                self.previousState = self.state
                self.state = .unknown
            } else if let previousState = self.previousState {
                self.state = previousState
            }
        }
    }
    #endif
}
