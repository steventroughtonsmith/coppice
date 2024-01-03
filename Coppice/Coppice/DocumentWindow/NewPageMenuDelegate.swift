//
//  NewPageMenuDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class NewPageMenuDelegate: NSObject, NSMenuDelegate {
    var action: Selector = #selector(newPage(_:))
    var includeKeyEquivalents: Bool?
    var includeIcons = false

    func numberOfItems(in menu: NSMenu) -> Int {
        return Page.ContentType.allCases.count
    }

    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
        self.update(item, with: Page.ContentType.allCases[index], includeKeyEquivalents: self.includeKeyEquivalents ?? menu.isInMainMenu)
        return true
    }

    private func update(_ item: NSMenuItem, with contentType: Page.ContentType, includeKeyEquivalents: Bool = false) {
        item.title = contentType.localizedName
        item.representedObject = contentType.rawValue
        item.target = nil
        item.action = self.action
        if (self.includeIcons) {
            item.image = contentType.icon
        }
        if includeKeyEquivalents {
            item.keyEquivalent = contentType.keyEquivalent
            item.keyEquivalentModifierMask = contentType.keyEquivalentModifierMask
        }
    }

    @IBAction func newPage(_ sender: Any?) {}
}

extension NewPageMenuDelegate: NSTouchBarDelegate {
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        guard let contentType = Page.ContentType(rawValue: identifier.rawValue) else {
            return nil
        }
        let item = NSButtonTouchBarItem(identifier: identifier,
                                        image: contentType.addIcon,
                                        target: nil,
                                        action: self.action)
        return item
    }
}
