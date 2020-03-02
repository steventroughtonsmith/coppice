//
//  SplitViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

protocol SplitViewControllerDelegate: class {
    func collapsedStatedDidChange(in splitViewController: SplitViewController)
}

class SplitViewController: NSObject {
    weak var delegate: SplitViewControllerDelegate?
    weak var splitView: NSSplitView? {
        didSet {
            self.splitView?.delegate = self
            self.updateStoredSizes()
        }
    }

    private var lastSidebarSize: CGFloat = 0
    private var lastInspectorSize: CGFloat = 0

    var isSidebarCollapsed: Bool {
        get {
            guard let splitView = self.splitView, splitView.arrangedSubviews.count == 3 else {
                return false
            }
            return splitView.isSubviewCollapsed(splitView.arrangedSubviews[0])
        }
        set {
            guard let splitView = self.splitView, splitView.isSubviewCollapsed(splitView.arrangedSubviews[0]) != newValue else {
                return
            }
            self.isCollapsingView = true
            if newValue {
                splitView.setPosition(splitView.minPossiblePositionOfDivider(at: 0), ofDividerAt: 0)
            } else {
                splitView.setPosition(self.lastSidebarSize, ofDividerAt: 0)
            }
            self.isCollapsingView = false
        }
    }
    var isInspectorCollapsed: Bool {
        get {
            guard let splitView = self.splitView, splitView.arrangedSubviews.count == 3 else {
                return false
            }
            return splitView.isSubviewCollapsed(splitView.arrangedSubviews[2])
        }
        set {
            guard let splitView = self.splitView, splitView.isSubviewCollapsed(splitView.arrangedSubviews[2]) != newValue else {
                return
            }
            self.isCollapsingView = true
            if newValue {
                splitView.setPosition(splitView.maxPossiblePositionOfDivider(at: 1), ofDividerAt: 1)
            } else {
                splitView.setPosition(splitView.frame.width - self.lastInspectorSize, ofDividerAt: 1)
            }
            self.isCollapsingView = false
        }
    }

    private var isCollapsingView = false

    private func updateStoredSizes() {
        guard let views = self.splitView?.arrangedSubviews, views.count == 3, !self.isCollapsingView else {
            return
        }
        if (views[0].frame.width > 0) {
            self.lastSidebarSize = views[0].frame.width
        }
        if (views[2].frame.width > 0) {
            self.lastInspectorSize = views[2].frame.width
        }
    }


    @IBAction func toggleSidebar(_ sender: Any?) {
        self.isSidebarCollapsed = !self.isSidebarCollapsed
    }

    @IBAction func toggleInspectors(_ sender: Any?) {
        self.isInspectorCollapsed = !self.isInspectorCollapsed
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(toggleSidebar(_:)) {
            menuItem.title = (self.isSidebarCollapsed ? NSLocalizedString("Hide Sidebar", comment: "Hide sidebar menu item") :
                                                        NSLocalizedString("Show Sidebar", comment: "Show sidebar menu item"))
            return true
        }
        if menuItem.action == #selector(toggleInspectors(_:)) {
            menuItem.title = (self.isInspectorCollapsed ? NSLocalizedString("Hide Inspectors", comment: "Hide inspectors menu item") :
                                                          NSLocalizedString("Show Inspectors", comment: "Show inspectors menu item"))
            return true
        }
        return false
    }
}


extension SplitViewController: NSSplitViewDelegate {
    func splitView(_ splitView: NSSplitView, canCollapseSubview subview: NSView) -> Bool {
        return (subview == splitView.arrangedSubviews.first) || (subview == splitView.arrangedSubviews.last)
    }

    func splitViewWillResizeSubviews(_ notification: Notification) {
        self.updateStoredSizes()
    }

    func splitViewDidResizeSubviews(_ notification: Notification) {
        self.delegate?.collapsedStatedDidChange(in: self)
    }
}
