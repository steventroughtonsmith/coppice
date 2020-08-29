//
//  M3AccountViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import M3Subscriptions

class CoppiceProViewController: PreferencesViewController {
    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "CoppiceProViewController", bundle: nil)
        self.startObservation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    //MARK: - Tab Info
    override var tabLabel: String {
        return NSLocalizedString("Coppice Pro", comment: "Pro Preferences Title")
    }

    override var tabImage: NSImage? {
        return NSImage(named: "PrefsPro")
    }

    //MARK: - View Controllers
    lazy var deactivatedViewController: DeactivatedSubscriptionViewController = {
        let vc = DeactivatedSubscriptionViewController(subscriptionManager: self.subscriptionManager)
        vc.delegate = self
        return vc
    }()

    lazy var activatedViewController: ActivatedSubscriptionViewController = {
        return ActivatedSubscriptionViewController(subscriptionManager: self.subscriptionManager)
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.appearance = NSAppearance(named: .aqua)
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(named: "CoppiceGreenPale")?.cgColor
    }

    private func updateView(with response: ActivationResponse?) {
        guard
            let activationResponse = response,
            (activationResponse.state == .active) || (activationResponse.state == .billingFailed)
        else {
            self.currentContentView = self.deactivatedViewController
            return
        }
        self.currentContentView = self.activatedViewController
    }

    var currentContentView: NSViewController? {
        didSet {
            guard self.currentContentView != oldValue else {
                return
            }
            oldValue?.removeFromParent()
            oldValue?.view.removeFromSuperview()
            if let newValue = self.currentContentView {
                self.addChild(newValue)
                self.view.addSubview(newValue.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }


    //MARK: - Subscription Manager
    var responseObservation: AnyCancellable?
    func startObservation() {
        self.responseObservation = self.subscriptionManager.$activationResponse.sink { [weak self] (response) in
            self?.update(with: response)
        }
    }

    private func update(with response: ActivationResponse?) {
        OperationQueue.main.addOperation {
            self.updateView(with: response)
        }
    }
}

extension CoppiceProViewController: DeactivatedSubscriptionViewControllerDelegate {
    func didChangeMode(in viewController: DeactivatedSubscriptionViewController) {
        self.updateSize()
    }
}
