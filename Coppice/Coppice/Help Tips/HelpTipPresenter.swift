//
//  HelpTipPresenter.swift
//  Coppice
//
//  Created by Martin Pilkington on 19/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class HelpTipPresenter: NSObject {
    static let shared = HelpTipPresenter()

    enum Identifier {
        case textPageLink
    }

    @discardableResult func showTip(with identifier: Identifier, fromToolbarItemWithIdentifier toolbarIdentifier: NSToolbarItem.Identifier) -> Bool {
        guard
            let window = NSApplication.shared.mainWindow,
            let toolbar = window.toolbar,
            let item = toolbar.items.first(where: { $0.itemIdentifier == toolbarIdentifier }),
            let itemView = item.view
        else {
            return false
        }

        return self.showTip(with: identifier, fromView: itemView, preferredEdge: .maxY)
    }

    @discardableResult func showTip(with identifier: Identifier, fromView view: NSView, preferredEdge: NSRectEdge) -> Bool {
        guard let helpTip = self.helpTipViewController(for: identifier) else {
            return false
        }

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = helpTip
        popover.show(relativeTo: view.bounds, of: view, preferredEdge: preferredEdge)
        return true
    }

    private func helpTipViewController(for identifier: Identifier) -> HelpTipViewController? {
        return HelpTipViewController(helpTip: .init(title: NSLocalizedString("Page Links", comment: "Link Help Tip Title"),
                                                    body: NSLocalizedString("To add a link on this page:\n1. Select some text\n2. Click Link to Page (⌘L)\n3. Choose the page to link to", comment: "Link Help Tip Body"),
                                                    movieName: "LinksHelp"))
    }
}
