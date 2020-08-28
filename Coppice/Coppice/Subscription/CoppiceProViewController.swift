//
//  M3AccountViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/08/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class CoppiceProViewController: PreferencesViewController {

    override var tabLabel: String {
        return NSLocalizedString("Coppice Pro", comment: "Pro Preferences Title")
    }

    override var tabImage: NSImage? {
        return NSImage(named: "PrefsPro")
    }

    lazy var deactivatedViewController: DeactivatedSubscriptionViewController = {
        let vc = DeactivatedSubscriptionViewController()
        vc.delegate = self
        return vc
    }()

    lazy var activatedViewController: ActivatedSubscriptionViewController = {
        return ActivatedSubscriptionViewController()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.view.appearance = NSAppearance(named: .aqua)
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor(named: "CoppiceGreenPale")?.cgColor
        self.view.addSubview(self.deactivatedViewController.view, withInsets: NSEdgeInsetsZero)
    }
    
}

extension CoppiceProViewController: DeactivatedSubscriptionViewControllerDelegate {
    func didChangeMode(in viewController: DeactivatedSubscriptionViewController) {
        self.updateSize()
    }
}
