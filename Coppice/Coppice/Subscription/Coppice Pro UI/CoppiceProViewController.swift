//
//  CoppiceProViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

protocol CoppiceProContentView: AnyObject {
    var leftActionTitle: String { get }
    var leftActionIcon: NSImage { get }
    func performLeftAction(in viewController: CoppiceProViewController)

    var rightActionTitle: String { get }
    var rightActionIcon: NSImage { get }
    func performRightAction(in viewController: CoppiceProViewController)
}

class CoppiceProViewController: NSViewController {
    @IBOutlet weak var headerBackground: CoppiceGreenView! {
        didSet {
            self.headerBackground.shape = .hillsBottom
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.currentContentViewController = self.currentContentView.viewController
    }


    @IBOutlet weak var contentContainerView: NSView!

    var currentContentView: ContentView = .activated {
        didSet {
            guard self.currentContentView != oldValue else {
                return
            }

            self.currentContentViewController = self.currentContentView.viewController
        }
    }

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
}

extension CoppiceProViewController {
    enum ContentView {
        case login
        case licence
        case activated

        var viewController: (NSViewController & CoppiceProContentView) {
            switch self {
            case .login:
                return LoginCoppiceProContentViewController()
            case .licence:
                return LicenceCoppiceProContentViewController()
            case .activated:
                return ActivatedCoppiceProContentViewController()
            }
        }
    }
}
