//
//  NewPageMenuDelegate.swift
//  Bubbles
//
//  Created by Martin Pilkington on 05/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class NewPageMenuDelegate: NSObject, NSMenuDelegate {
    func numberOfItems(in menu: NSMenu) -> Int {
        let caseCount = PageContentType.allCases.count
        guard menu.supermenu == nil else {
            return caseCount
        }
        return caseCount + 1
    }

    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
        //We're in a menu hierarchy
        guard menu.supermenu == nil else {
            print("menu")
            self.update(item, with: PageContentType.allCases[index], includeKeyEquivalents: menu.isInMainMenu)
            return true
        }

        print("control")
        //We're the root menu in a control
        if index == 0 {
            item.image = NSImage(named: "AddPage")
            item.title = ""
        } else {
            self.update(item, with: PageContentType.allCases[index - 1])
        }
        return true
    }

    private func update(_ item: NSMenuItem, with contentType: PageContentType, includeKeyEquivalents: Bool = false) {
        item.title = contentType.localizedName
        item.representedObject = contentType.rawValue
        item.target = nil
        item.action = #selector(newPage(_:))
        if includeKeyEquivalents {
            item.keyEquivalent = contentType.keyEquivalent
            print("\(contentType.keyEquivalentModifierMask)")
            item.keyEquivalentModifierMask = contentType.keyEquivalentModifierMask
        }
    }

    @IBAction func newPage(_ sender: Any?) {}
}
