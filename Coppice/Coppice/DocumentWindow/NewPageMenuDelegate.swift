//
//  NewPageMenuDelegate.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class NewPageMenuDelegate: NSObject, NSMenuDelegate {
    var action: Selector = #selector(newPage(_:))
    var includeKeyEquivalents: Bool?
    var includeIcons = false

    func numberOfItems(in menu: NSMenu) -> Int {
        return PageContentType.allCases.count
    }

    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
        self.update(item, with: PageContentType.allCases[index], includeKeyEquivalents: self.includeKeyEquivalents ?? menu.isInMainMenu)
        return true
    }

    private func update(_ item: NSMenuItem, with contentType: PageContentType, includeKeyEquivalents: Bool = false) {
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
