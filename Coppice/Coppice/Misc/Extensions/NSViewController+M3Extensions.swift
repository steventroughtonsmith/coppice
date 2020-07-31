//
//  NSViewController+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSViewController {
    var windowController: NSWindowController? {
        return self.view.window?.windowController
    }

    var splitViewController: NSSplitViewController? {
        var currentParent = self.parent
        while currentParent != nil {
            if let splitVC = currentParent as? NSSplitViewController {
                return splitVC
            }
            currentParent = currentParent?.parent
        }
        return nil
    }

    var splitViewItem: NSSplitViewItem? {
        return self.splitViewController?.splitViewItem(for: self)
    }
}
