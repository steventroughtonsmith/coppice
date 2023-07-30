//
//  CoppiceProViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import M3Subscriptions

protocol CoppiceProContentView: AnyObject {
    var leftActionTitle: String { get }
    var leftActionIcon: NSImage { get }
    func performLeftAction(in viewController: CoppiceProViewController)

    var rightActionTitle: String { get }
    var rightActionIcon: NSImage { get }
    func performRightAction(in viewController: CoppiceProViewController)
}

class CoppiceProViewController: NSViewController {
    let viewModel: CoppiceProViewModel
    init(viewModel: CoppiceProViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CoppiceProViewController", bundle: nil)
        self.viewModel.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    @IBOutlet weak var headerBackground: CoppiceGreenView! {
        didSet {
            self.headerBackground.shape = .hillsBottom
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.currentContentViewController = self.viewModel.currentContentView.viewController(with: self.viewModel)
        self.updateLicenceUpgradeAlert()
        self.setupSubscribers()
    }


    @IBOutlet weak var contentContainerView: NSView!

    private var currentContentViewController: (NSViewController & CoppiceProContentView)? {
        didSet {
            guard (oldValue as NSViewController?) != (self.currentContentViewController as NSViewController?) else {
                return
            }

            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()

            if let newView = self.currentContentViewController {
                self.contentContainerView.addSubview(newView.view, withInsets: .zero)
                self.addChild(newView)
            }

            self.updateFooterButtons()
        }
    }


    //MARK: - Links
    @IBAction func openTerms(_ sender: Any) {
        NSWorkspace.shared.open(.termsAndConditions)
    }

    @IBAction func openPrivacyPolicy(_ sender: Any) {
        NSWorkspace.shared.open(.privacyPolicy)
    }


    //MARK: - Footer Buttons
    @IBOutlet weak var leftButton: RoundButton!
    @IBOutlet weak var rightButton: RoundButton!

    @IBAction func leftButtonClicked(_ sender: Any) {
        self.currentContentViewController?.performLeftAction(in: self)
    }

    @IBAction func rightButtonClicked(_ sender: Any) {
        self.currentContentViewController?.performRightAction(in: self)
    }

    private func updateFooterButtons() {
        self.leftButton.isHidden = (self.currentContentViewController == nil)
        self.rightButton.isHidden = (self.currentContentViewController == nil)

        guard let contentView = self.currentContentViewController else {
            return
        }

        self.leftButton.title = contentView.leftActionTitle
        self.leftButton.image = contentView.leftActionIcon

        self.rightButton.title = contentView.rightActionTitle
        self.rightButton.image = contentView.rightActionIcon
    }

    //MARK: - Upgrading
    @IBOutlet weak var licenceUpgradeAlert: NSBox!

    private func updateLicenceUpgradeAlert() {
        self.licenceUpgradeAlert.isHidden = !self.viewModel.needsLicenceUpgrade
    }

    @IBAction func upgradeLicence(_ sender: Any) {
        self.viewModel.startLicenceUpgrade()
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case currentContentView
        case needsLicenceUpgrade
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    private func setupSubscribers() {
        self.subscribers[.currentContentView] = self.viewModel.$currentContentView.sink { [weak self] newContentView in
            guard
                let self,
                newContentView != self.viewModel.currentContentView
            else {
                return
            }

            DispatchQueue.main.async {
                self.currentContentViewController = newContentView.viewController(with: self.viewModel)
            }
        }
        self.subscribers[.needsLicenceUpgrade] = self.viewModel.$needsLicenceUpgrade
            .map { !$0 }
            .assign(to: \.isHidden, on: self.licenceUpgradeAlert)
    }
}

extension CoppiceProViewController: CoppiceProView {
    func selectSubscription(from subscriptions: [API.V2.Subscription]) async throws -> API.V2.Subscription {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let subscriptionVC = MultipleSubscriptionsViewController(subscriptions: subscriptions) { selectedSubscription in
                    guard let selectedSubscription else {
                        continuation.resume(throwing: CoppiceProViewModel.Error.userCancelled)
                        return
                    }
                    continuation.resume(returning: selectedSubscription)
                }
                self.presentAsSheet(subscriptionVC)
            }
        }
    }

    func deactivateDevice(from devices: [API.V2.ActivatedDevice]) async throws -> API.V2.ActivatedDevice {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                let devicesVC = TooManyDevicesViewController(devices: devices) { selectedDevice in
                    guard let selectedDevice else {
                        continuation.resume(throwing: CoppiceProViewModel.Error.userCancelled)
                        return
                    }
                    continuation.resume(returning: selectedDevice)
                }
                self.presentAsSheet(devicesVC)
            }
        }
    }
}

extension CoppiceProViewModel.ContentView {
    func viewController(with viewModel: CoppiceProViewModel) -> (NSViewController & CoppiceProContentView) {
        switch self {
        case .login:
            return LoginCoppiceProContentViewController(viewModel: viewModel)
        case .licence:
            return LicenceCoppiceProContentViewController(viewModel: viewModel)
        case .activated:
            return ActivatedCoppiceProContentViewController(viewModel: viewModel)
        }
    }
}
