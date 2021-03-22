//
//  PreferencesTabView.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import Carbon.HIToolbox

protocol PreferencesTabViewDelegate: AnyObject {
    func escapeWasPressed(in tabView: PreferencesTabView)
}


class PreferencesTabView: NSTabViewController {
    var tabHeights: [NSTabViewItem: CGFloat] = [:]
    var width: CGFloat = 480

    weak var delegate: PreferencesTabViewDelegate?

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

    func recalculateHeight(for tabViewItem: NSTabViewItem) {
        self.tabHeights[tabViewItem] = self.height(for: tabViewItem)
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

    override func keyDown(with event: NSEvent) {
        if (event.keyCode == UInt16(kVK_Escape)) {
            self.delegate?.escapeWasPressed(in: self)
        }
    }
}

class PreferencesViewController: NSViewController {
    var preferenceTabView: PreferencesTabView? {
        var currentViewController: NSViewController? = self
        while (currentViewController != nil) {
            if let preferencesTabView = (currentViewController as? PreferencesTabView) {
                return preferencesTabView
            }
            currentViewController = currentViewController?.parent
        }
        return nil
    }

    var tabLabel: String {
        return "Unknown"
    }

    var tabImage: NSImage? {
        return nil
    }

    private(set) weak var tabViewItem: NSTabViewItem?

    override init(nibName nibNameOrNil: NSNib.Name?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)

        let item = NSTabViewItem(viewController: self)
        item.label = self.tabLabel
        item.image = self.tabImage
        self.tabViewItem = item
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateSize(animated: Bool = true) {
        guard let tabViewItem = self.tabViewItem else {
            return
        }
        self.preferenceTabView?.recalculateHeight(for: tabViewItem)

        guard let window = self.view.window else {
            return
        }
        self.preferenceTabView?.updateFrame(of: window, for: tabViewItem, animated: animated)
    }
}

