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

//TODO: Remove actions except for check
//TODO: Add check for V1 for check and deactivate
//TODO: Otherwise use check for V2
//TODO: Add migration check
class CoppiceSubscriptionManager: NSObject {
    let subscriptionController: API.V1.SubscriptionController?
    weak var delegate: CoppiceSubscriptionManagerDelegate?

    @Published var activationResponse: API.V1.ActivationResponse? {
        didSet {
            self.notifyOfChanges()
        }
    }

    @Published var currentCheckError: NSError?

    static var shared = CoppiceSubscriptionManager()

    override init() {
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let licenceURL = appSupportURL.appendingPathComponent("licence")
            self.subscriptionController = API.V1.SubscriptionController(activationDetailsURL: licenceURL)
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
    }

    func deactivate(on window: NSWindow, errorHandler: @escaping ErrorHandler) {

    }

    //TODO: Make Async Throws
    func updateDeviceName(deviceName: String, completion: @escaping (Result<API.V1.ActivationResponse, Error>) -> Void) {

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
//    private var previousActivationResponse: ActivationResponse?

    var proDisabled = false {
        didSet {
//            guard self.proDisabled != oldValue else {
//                return
//            }
//
//            if self.proDisabled {
//                self.previousActivationResponse = self.activationResponse
//                self.activationResponse = nil
//            } else {
//                self.activationResponse = self.previousActivationResponse
//                self.previousActivationResponse = nil
//            }
        }
    }
    #endif
}
