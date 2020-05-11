//
//  NoCanvasViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class NoCanvasViewController: NSViewController, SplitViewContainable {
    lazy var splitViewItem: NSSplitViewItem = {
        let splitViewItem = NSSplitViewItem(viewController: self)
        splitViewItem.holdingPriority = NSLayoutConstraint.Priority(rawValue: 249)
        return splitViewItem
    }()
}
