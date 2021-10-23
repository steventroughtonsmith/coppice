//
//  NSMenuItem+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSMenu {
    var isInMainMenu: Bool {
        var supermenu = self.supermenu
        while supermenu != nil {
            if supermenu == NSApplication.shared.mainMenu {
                return true
            }
            supermenu = supermenu?.supermenu
        }
        return false
    }

    func removeSection(startingAtItemWithAction selector: Selector) {
        let initialIndex = self.indexOfItem(withTarget: nil, andAction: selector)
        guard initialIndex != -1 else {
            return
        }

        while self.numberOfItems > initialIndex {
            guard let item = self.item(at: initialIndex) else {
                break
            }
            self.removeItem(item)
            if item.isSeparatorItem {
                break
            }
        }
    }
}
