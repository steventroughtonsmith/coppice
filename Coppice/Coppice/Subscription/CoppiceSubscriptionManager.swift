//
//  CoppiceSubscriptionManager.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions
import Combine

class CoppiceSubscriptionManager: NSObject {
    let subscriptionController: SubscriptionController?

    @Published var activationResponse: ActivationResponse?
    @Published var currentCheckError: NSError?

    override init() {
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let licenceURL = appSupportURL.appendingPathComponent("licence")
            self.subscriptionController = SubscriptionController(licenceURL: licenceURL)
        } else {
            self.subscriptionController = nil
        }

        super.init()

        self.checkSubscriptionIfNeeded()
    }

    deinit {
        print("deinit subscription manager")
    }

    //MARK: - User Initiated actions
    func activate(withEmail email: String, password: String, on window: NSWindow) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.activate(withEmail: email, password: password) { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                window.presentError(error)
            }
            self.completeCheck()
        }
    }

    func deactivate(on window: NSWindow) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.deactivate { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                window.presentError(error)
            }
            self.completeCheck()
        }
    }

    func updateDeviceName(deviceName: String, on window: NSWindow) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.checkSubscription(updatingDeviceName: deviceName) { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                window.presentError(error)
            }
            self.completeCheck()
        }
    }

    //MARK: - Automatic actions
    private(set) var recheckTimer: Timer?
    private(set) var lastCheck: Date?

    func checkSubscriptionIfNeeded() {
        var checkInterval: TimeInterval = 60
        //Increase the times we check if billing has failed to 4 times a day
        if
            let response = self.activationResponse,
            response.deviceIsActivated,
            (response.subscription?.renewalStatus == .failed) {
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

    private func checkSubscription() {
        self.subscriptionController?.checkSubscription(completion: { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                self.currentCheckError = error
            }
            self.completeCheck()
        })
    }

    private func completeCheck() {
        if !Thread.current.isMainThread {
            OperationQueue.main.addOperation {
                self.completeCheck()
            }
        }
        guard
            let response = self.activationResponse,
            response.deviceIsActivated
        else {
            return
        }

        self.lastCheck = Date()
        self.recheckInAnHour()
    }

    private func recheckInAnHour() {
        self.recheckTimer = Timer.scheduledTimer(withTimeInterval: 10 , repeats: false) { [weak self] _ in
            self?.checkSubscriptionIfNeeded()
        }
    }
}
