//
//  CoppiceProPreferencesViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/07/2023.
//  Copyright © 2023 M Cubed Software. All rights reserved.
//

import Cocoa

class CoppiceProPreferencesViewController: PreferencesViewController {
    //MARK: - Prefs tab
    override var tabLabel: String {
        return NSLocalizedString("Coppice Pro", comment: "Pro Preferences Title")
    }

    override var tabImage: NSImage? {
        return NSImage(named: "PrefsPro")
    }


    //MARK: - View
    private let contentVC = CoppiceProViewController(viewModel: .init())
    override func loadView() {
        self.view = NSView()
        self.view.addSubview(self.contentVC.view, withInsets: .zero)
        self.addChild(self.contentVC)
    }
}
