//
//  PreferencesWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class PreferencesWindowController: NSWindowController {

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

        let generalPrefs = GeneralPreferencesViewController()
        let generalItem = generalPrefs.createTabItem()
        self.tabController.addTabViewItem(generalItem)

        let updatePrefs = UpdatePreferencesViewController()
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


class PreferencesTabView: NSTabViewController {
    var tabHeights: [NSTabViewItem: CGFloat] = [:]
    var width: CGFloat = 480

    override func addTabViewItem(_ tabViewItem: NSTabViewItem) {
        self.tabHeights[tabViewItem] = self.height(for: tabViewItem)
        super.addTabViewItem(tabViewItem)
    }

    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)

        self.view.window?.title = tabViewItem?.label ?? "Preferences"
    }

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)

        guard let item = tabViewItem, let window = self.view.window else {
            return
        }

        self.updateFrame(of: window, for: item, animated: true)
    }

    func updateFrame(of window: NSWindow, for tabViewItem: NSTabViewItem, animated: Bool) {
        let newHeight = self.tabHeights[tabViewItem] ?? 0
        let currentHeight = window.contentView?.frame.height ?? self.tabView.frame.height

        let difference = newHeight - currentHeight

        var windowFrame = window.frame
        windowFrame.origin.y -= difference
        windowFrame.size.height += difference

        window.setFrame(windowFrame, display: false, animate: animated)
    }

    private func height(for tabViewItem: NSTabViewItem) -> CGFloat {
        guard let view = tabViewItem.viewController?.view ?? tabViewItem.view else {
            return 0
        }

        let widthConstraint = view.widthAnchor.constraint(equalToConstant: self.width)
        widthConstraint.isActive = true
        view.layoutSubtreeIfNeeded()
        let height = view.fittingSize.height
        widthConstraint.isActive = false
        return height
    }
}
