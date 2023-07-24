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
}

/*FLOWS

# Login
 User: enters login details
    call /login
    on success call /listSubscriptions
    on multiple: show subscriptions
    on single or sub select: call /activate

    on too many devices show alert and then deactivate one

# Licence
    call /activate

    on too many devices show alert and then deactivate one

# Check
    call /check (with login token or licence)

# Rename
    call /rename

# Deactivate
    call /deactivate (with login token or licence)
*/

class CoppiceSubscriptionManager: NSObject {
    let subscriptionController: SubscriptionController.V1?
    weak var delegate: CoppiceSubscriptionManagerDelegate?

    @Published var activationResponse: ActivationResponse? {
        didSet {
            self.notifyOfChanges()
        }
    }

    @Published var currentCheckError: NSError?

    static var shared = CoppiceSubscriptionManager()

    override init() {
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let licenceURL = appSupportURL.appendingPathComponent("licence")
            self.subscriptionController = SubscriptionController.V1(activationDetailsURL: licenceURL)
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
        Task {
            do {
                let response = try await controller.activate(withEmail: activationContext.email, password: activationContext.password, subscription: activationContext.subscription, deactivatingDevice: activationContext.deviceToDeactivate)
                self.activationResponse = response
                self.currentCheckError = nil
            } catch let error as NSError {
                guard error.domain == SubscriptionErrorFactory.domain else {
                    self.handle(error, on: window, with: errorHandler)
                    return
                }
                if (error.code == SubscriptionErrorCodes.multipleSubscriptionsFound.rawValue) {
                    self.showMultipleSubscriptionsSheet(with: activationContext, for: error, on: window, errorHandler: errorHandler)
                } else if (error.code == SubscriptionErrorCodes.tooManyDevices.rawValue) {
                    self.showTooManyDevicesSubscriptionSheet(with: activationContext, for: error, on: window, errorHandler: errorHandler)
                } else {
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

        Task {
            do {
                let response = try await controller.deactivate()
                self.activationResponse = response
                self.currentCheckError = nil
            } catch {
                self.handle(error as NSError, on: window, with: errorHandler)
            }
            self.completeCheck()
        }
    }

    //TODO: Make Async Throws
    func updateDeviceName(deviceName: String, completion: @escaping (Result<ActivationResponse, Error>) -> Void) {
        guard let controller = self.subscriptionController else {
            return
        }

        Task {
            do {
                let response = try await controller.checkSubscription(updatingDeviceName: deviceName)
                self.activationResponse = response
                self.currentCheckError = nil
                completion(.success(response))
            } catch {
                completion(.failure(error))
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
            (response.subscription?.renewalStatus == .failed)
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
        guard let controller = self.subscriptionController else {
            return
        }

        Task {
            do {
                let response = try await controller.checkSubscription()
                self.activationResponse = response
                self.currentCheckError = nil
            } catch {
                self.handleCheckError(error as NSError
                )
            }
            self.completeCheck()
        }
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
            self.subscriptionController?.deleteActivation()
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


    //MARK: - Notify of changes
    func notifyOfChanges() {
        guard let response = self.activationResponse else {
            return
        }

        guard
            let currentSubscription = response.subscription,
            let previousSubscription = response.previousSubscription
        else {
            return
        }

        //Just expired
        if (currentSubscription.hasExpired && !previousSubscription.hasExpired) {
            self.delegate?.showInfoAlert(InfoAlert(id: "test", level: .warning, title: "Your Coppice Pro subscription has expired.", message: "You can always upgrade again through our website.", autodismiss: false),
                                         for: self)
            return
        }
        //Just renewed
        if (currentSubscription.hasExpired == false) && (currentSubscription.expirationDate > previousSubscription.expirationDate) {
            self.delegate?.showInfoAlert(InfoAlert(id: "test", level: .info, title: "Thank you for renewing your subscription!"),
                                         for: self)
            return
        }
        //Billing failed
        if (currentSubscription.hasExpired == false) && (currentSubscription.renewalStatus == .failed) {
            self.delegate?.showInfoAlert(InfoAlert(id: "test", level: .error, title: "We were unable to renew your Coppice Pro subscription.", message: "Please log into your M Cubed Account and update your billing info.", autodismiss: false),
                                         for: self)
            return
        }
    }


    //MARK: - Pro Upsell
    enum ProPopoverUserAction {
        case hover
        case click
    }

    func createProPopover(for feature: ProFeature, userAction: ProPopoverUserAction) -> NSPopover {
        let upsellVC = ProUpsellViewController()
        upsellVC.currentFeature = feature
        let popover = NSPopover()
        popover.contentViewController = upsellVC
        switch userAction {
        case .hover:
            popover.behavior = .applicationDefined
            upsellVC.showFindOutMore = false
        case .click:
            popover.behavior = .transient
            upsellVC.showFindOutMore = true
        }
        return popover
    }

    func showProPopover(for feature: ProFeature, from view: NSView, preferredEdge: NSRectEdge) {
        let popover = self.createProPopover(for: feature, userAction: .click)
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: preferredEdge)
    }

    lazy var proImage: NSImage = {
        let localizedPro = NSLocalizedString("PRO", comment: "Coppice Pro short name")
        let attributedPro = NSAttributedString(string: localizedPro, attributes: [
            .foregroundColor: NSColor.white,
            .font: NSFont.boldSystemFont(ofSize: 11),
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
        NSWorkspace.shared.open(URL(string: "https://mcubedsw.com/coppice#pro")!)
    }


    //MARK: - Debug
    #if DEBUG
    private var previousActivationResponse: ActivationResponse?

    var proDisabled = false {
        didSet {
            guard self.proDisabled != oldValue else {
                return
            }

            if self.proDisabled {
                self.previousActivationResponse = self.activationResponse
                self.activationResponse = nil
            } else {
                self.activationResponse = self.previousActivationResponse
                self.previousActivationResponse = nil
            }
        }
    }
    #endif
}
