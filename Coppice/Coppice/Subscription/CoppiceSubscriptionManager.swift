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

protocol CoppiceSubscriptionManagerDelegate: AnyObject {
    func showCoppicePro(with error: NSError, for subscriptionManager: CoppiceSubscriptionManager)
}

class CoppiceSubscriptionManager: NSObject {
    let subscriptionController: SubscriptionController?
    weak var delegate: CoppiceSubscriptionManagerDelegate?

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
        self.activate(with: ActivationContext(email: email, password: password), on: window, errorHandler: errorHandler)
    }

    private func activate(with activationContext: ActivationContext, on window: NSWindow, errorHandler: @escaping ErrorHandler) {
        guard let controller = self.subscriptionController else {
            return
        }
        controller.activate(withEmail: activationContext.email, password: activationContext.password, subscription: activationContext.subscription, deactivatingDevice: activationContext.deviceToDeactivate) { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                guard error.domain == SubscriptionErrorFactory.domain else {
                    self.handle(error, on: window, with: errorHandler)
                    return
                }
                if (error.code == SubscriptionErrorCodes.multipleSubscriptionsFound.rawValue) {
                    self.showMultipleSubscriptionsSheet(with: activationContext, for: error, on: window, errorHandler: errorHandler)
                }
                else if (error.code == SubscriptionErrorCodes.tooManyDevices.rawValue) {
                    self.showTooManyDevicesSubscriptionSheet(with: activationContext, for: error, on: window, errorHandler: errorHandler)
                }
                else {
                    self.handle(error, on: window, with: errorHandler)
                }
            }
            self.completeCheck()
        }
    }

    struct ActivationContext {
        var email: String
        var password: String
        var subscription: M3Subscriptions.Subscription? = nil
        var deviceToDeactivate: M3Subscriptions.SubscriptionDevice? = nil
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
        if errorHandler(error) == false {
            self.show(basicError: error, on: window)
        }
    }

    private func showMultipleSubscriptionsSheet(with activationContext: ActivationContext, for error: NSError, on window: NSWindow, errorHandler: @escaping ErrorHandler) {
        guard let subscriptions = error.userInfo[SubscriptionErrorFactory.InfoKeys.subscriptionPlans] as? [M3Subscriptions.Subscription] else {
            return
        }
        let sheet = MultipleSubscriptionsViewController(subscriptions: subscriptions) { subscription in
            guard let subscription = subscription else {
                return
            }
            var context = activationContext
            context.subscription = subscription
            self.activate(with: context, on: window, errorHandler: errorHandler)
        }
        window.contentViewController?.presentAsSheet(sheet)
    }

    private func showTooManyDevicesSubscriptionSheet(with activationContext: ActivationContext, for error: NSError, on window: NSWindow, errorHandler: @escaping ErrorHandler) {
        guard let devices = error.userInfo[SubscriptionErrorFactory.InfoKeys.devices] as? [M3Subscriptions.SubscriptionDevice] else {
            return
        }
        let sheet = TooManyDevicesViewController(devices: devices) { device in
            guard let device = device else {
                return
            }
            var context = activationContext
            context.deviceToDeactivate = device
            self.activate(with: context, on: window, errorHandler: errorHandler)
        }
        window.contentViewController?.presentAsSheet(sheet)
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
        var checkInterval: TimeInterval = 86400
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

    func checkSubscription() {
        self.subscriptionController?.checkSubscription(completion: { (result) in
            switch result {
            case .success(let response):
                self.activationResponse = response
                self.currentCheckError = nil
            case .failure(let error):
                self.handleCheckError(error)
            }
            self.completeCheck()
        })
    }

    private func handleCheckError(_ error: NSError) {
        guard let errorCode = SubscriptionErrorCodes(rawValue: error.code) else {
            self.currentCheckError = error
            return
        }

        switch errorCode {
        case .noDeviceFound:
            self.currentCheckError = nil
            self.activationResponse = ActivationResponse.deactivated()
            self.delegate?.showCoppicePro(with: error, for: self)
            self.subscriptionController?.deleteLicence()
        default:
            self.currentCheckError = error
        }
    }

    private func completeCheck() {
        guard
            let response = self.activationResponse,
            response.deviceIsActivated
        else {
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


    //MARK: - Pro Upsell
    func showProPopover(for feature: ProFeature, from view: NSView, preferredEdge: NSRectEdge) {
        let upsellVC = ProUpsellViewController()
        upsellVC.currentFeature = feature
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

    func openProPage() {
        NSWorkspace.shared.open(URL(string: "https://coppiceapp.com/pro")!)
    }
}
