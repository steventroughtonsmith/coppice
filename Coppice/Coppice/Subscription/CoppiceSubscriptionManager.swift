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

    static var shared = CoppiceSubscriptionManager()

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
    typealias ErrorHandler = (NSError) -> Bool
    func activate(withEmail email: String, password: String, on window: NSWindow, errorHandler: @escaping ErrorHandler) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.activate(withEmail: email, password: password) { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                self.handle(error, on: window, with: errorHandler)
            }
            self.completeCheck()
        }
    }

    func deactivate(on window: NSWindow, errorHandler: @escaping ErrorHandler) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.deactivate { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                self.handle(error, on: window, with: errorHandler)
            }
            self.completeCheck()
        }
    }

    func updateDeviceName(deviceName: String, on window: NSWindow, errorHandler: @escaping ErrorHandler) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.checkSubscription(updatingDeviceName: deviceName) { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                self.handle(error, on: window, with: errorHandler)
            }
            self.completeCheck()
        }
    }


    //MARK: - Error Handling
    private func handle(_ error: NSError, on window: NSWindow, with errorHandler: ErrorHandler) {
        guard let errorCode = SubscriptionErrorCodes(rawValue: error.code) else {
            if errorHandler(error) == false {
                self.show(basicError: error, on: window)
            }
            return
        }

        switch errorCode {
        case .multipleSubscriptionsFound:
            self.showMultipleSubscriptionsSheet(for: error, on: window)
        case .tooManyDevices:
            self.showTooManyDevicesSubscriptionSheet(for: error, on: window)
        default:
            if errorHandler(error) == false {
                self.show(basicError: error, on: window)
            }
        }
    }

    private func showMultipleSubscriptionsSheet(for error: NSError, on window: NSWindow) {
        print("multiple subscriptions: \(error)")
    }

    private func showTooManyDevicesSubscriptionSheet(for error: NSError, on window: NSWindow) {
        print("too many devices: \(error)")
    }

    private func show(basicError error: NSError, on window: NSWindow) {
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: window) { (response) in
            print("response: \(response)")
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
        self.recheckTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: false) { [weak self] _ in
            self?.checkSubscriptionIfNeeded()
        }
    }


    //MARK: - Pro Upsell
    func showProPopover(from view: NSView, preferredEdge: NSRectEdge) {
        let upsellVC = ProUpsellViewController()
        let popover = NSPopover()
        popover.contentViewController = upsellVC
        popover.behavior = .transient
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: preferredEdge)
    }

    lazy var proImage: NSImage = {
        let localizedPro = NSLocalizedString("PRO", comment: "Coppice Pro short name")
        let attributedPro = NSAttributedString(string: localizedPro, attributes: [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 11)
        ])

        let bounds = attributedPro.boundingRect(with: CGSize(width: 100, height: 100), options: .usesLineFragmentOrigin)

        let verticalPadding: CGFloat = 1
        let horizontalPadding: CGFloat = 8
        let imageSize = bounds.rounded().size.plus(width: horizontalPadding * 2, height: verticalPadding * 2)

        let image = NSImage(size: imageSize, flipped: false) { (rect) -> Bool in
            let path = NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4)
            NSColor(named: "CoppiceGreen")?.setFill()
            path.fill()


            attributedPro.draw(at: CGPoint(x: horizontalPadding, y: verticalPadding))

            return true
        }
        image.accessibilityDescription = localizedPro
        return image
    }()

    var proTooltip: String {
        return NSLocalizedString("This feature requires a Coppice Pro subscription", comment: "")
    }
}
