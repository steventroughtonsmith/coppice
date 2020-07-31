//
//  NoCanvasViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class NoCanvasViewController: NSViewController, SplitViewContainable {
    func createSplitViewItem() -> NSSplitViewItem {
        let splitViewItem = NSSplitViewItem(viewController: self)
        splitViewItem.holdingPriority = NSLayoutConstraint.Priority(rawValue: 249)
        return splitViewItem
    }
}
