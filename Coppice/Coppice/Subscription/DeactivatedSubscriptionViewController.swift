//
//  DeactivatedSubscriptionViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

protocol DeactivatedSubscriptionMode: class {
    var header: String { get }
    var subheader: String { get }
    var actionName: String { get }
    var toggleName: String { get }
    func performAction()
}

protocol DeactivatedSubscriptionViewControllerDelegate: class {
    func didChangeMode(in viewController: DeactivatedSubscriptionViewController)
}

class DeactivatedSubscriptionViewController: NSViewController {
    weak var delegate: DeactivatedSubscriptionViewControllerDelegate?

    @IBOutlet weak var contentViewContainer: NSView!
    @IBOutlet weak var headerLabel: NSTextField!
    @IBOutlet weak var subheaderLabel: NSTextField!
    @IBOutlet weak var primaryButton: NSButton!
    @IBOutlet weak var toggleButton: NSButton!

    let subscriptionManager: CoppiceSubscriptionManager
    init(subscriptionManager: CoppiceSubscriptionManager) {
        self.subscriptionManager = subscriptionManager
        super.init(nibName: "DeactivatedSubscriptionViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.

        self.contentViewContainer.wantsLayer = true
        self.contentViewContainer.layer?.backgroundColor = NSColor(named: "CoppiceProContentBackground")?.cgColor

        self.apply(self.signInVC)
    }

    //MARK: - Modes
    private lazy var subscribeVC: SubscribeViewController = {
        return SubscribeViewController(subscriptionManager: self.subscriptionManager)
    }()
    private lazy var signInVC: SignInViewController = {
        return SignInViewController(subscriptionManager: self.subscriptionManager)
    }()

    var currentMode: (NSViewController & DeactivatedSubscriptionMode)?

    func apply(_ mode: (NSViewController & DeactivatedSubscriptionMode)) {
        self.currentMode?.view.removeFromSuperview()
        self.currentMode?.removeFromParent()

        self.contentViewContainer.addSubview(mode.view, withInsets: NSEdgeInsetsZero)
        self.addChild(mode)

        self.headerLabel.stringValue = mode.header
        self.subheaderLabel.stringValue = mode.subheader
        self.primaryButton.title = mode.actionName
        self.toggleButton.title = mode.toggleName

        self.currentMode = mode
        self.delegate?.didChangeMode(in: self)
    }


    //MARK: - Actions
    @IBAction func performPrimaryAction(_ sender: Any?) {
        self.currentMode?.performAction()
    }



    @IBAction func toggleMode(_ sender: Any?) {
//        if (self.currentMode as NSViewController?) == self.signInVC {
//            self.apply(self.subscribeVC)
//        }
//        else {
//            self.apply(self.signInVC)
//        }
    }

    @IBAction func showTerms(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://www.mcubedsw.com/terms")!)
    }

    @IBAction func showPrivacyPolicy(_ sender: Any?) {
        NSWorkspace.shared.open(URL(string: "https://www.mcubedsw.com/privacy")!)
    }
}
