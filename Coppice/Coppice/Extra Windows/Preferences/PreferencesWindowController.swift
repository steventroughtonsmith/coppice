//
//  PreferencesWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Sparkle

class PreferencesWindowController: NSWindowController {

    let updaterController: SPUStandardUpdaterController
    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
        super.init(window: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    let tabController: PreferencesTabView = {
        let controller = PreferencesTabView()
        controller.tabStyle = .toolbar
//        controller.transitionOptions = .crossfade
        return controller
    }()

    override var windowNibName: NSNib.Name? {
        return "PreferencesWindow"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        self.tabController.delegate = self

        let generalPrefs = GeneralPreferencesViewController()
        let generalItem = generalPrefs.createTabItem()
        self.tabController.addTabViewItem(generalItem)

        let updatePrefs = UpdatePreferencesViewController(updaterController: self.updaterController)
        self.tabController.addTabViewItem(updatePrefs.createTabItem())

        let subscribe = SubscribeViewController()
        self.tabController.addTabViewItem(subscribe.createTabItem())

        self.window?.contentViewController = self.tabController

        if let window = self.window {
            self.tabController.updateFrame(of: window, for: generalItem, animated: false)
            window.title = generalItem.label
        }
    }
}


extension PreferencesWindowController: PreferencesTabViewDelegate {
    func escapeWasPressed(in tabView: PreferencesTabView) {
        self.window?.close()
    }
}


