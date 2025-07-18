//
//  PreferencesWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions
import Sparkle

class PreferencesWindowController: NSWindowController {
    let updaterController: SPUStandardUpdaterController
    init(updaterController: SPUStandardUpdaterController) {
        self.updaterController = updaterController
        super.init(window: nil)
    }

    @available(*, unavailable)
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

    let coppiceProPreferences = CoppiceProPreferencesViewController()

    override func windowDidLoad() {
        super.windowDidLoad()

        self.tabController.delegate = self

        let generalPrefs = GeneralPreferencesViewController()
        if let generalItem = generalPrefs.tabViewItem {
            self.tabController.addTabViewItem(generalItem)
        }

        if let updatePrefs = UpdatePreferencesViewController(updaterController: self.updaterController).tabViewItem {
            self.tabController.addTabViewItem(updatePrefs)
        }

        if let coppicePro = self.coppiceProPreferences.tabViewItem {
            self.tabController.addTabViewItem(coppicePro)
        }

        self.window?.contentViewController = self.tabController

        if let window = self.window, let generalItem = generalPrefs.tabViewItem {
            self.tabController.updateFrame(of: window, for: generalItem, animated: false)
            window.title = generalItem.label
        }
    }

    func showCoppicePro() {
        self.tabController.selectedTabViewItemIndex = (self.tabController.tabViewItems.count - 1)
    }

    func showCoppiceProTrial() {
        self.showCoppicePro()
        self.coppiceProPreferences.coppiceProViewController.showTrialInfo(nil)
    }

    func activate(withLicenceURL url: URL) {
        self.showCoppicePro()
        self.coppiceProPreferences.coppiceProViewController.activate(withLicenceURL: url)
    }
}


extension PreferencesWindowController: PreferencesTabViewDelegate {
    func escapeWasPressed(in tabView: PreferencesTabView) {
        self.window?.close()
    }
}


