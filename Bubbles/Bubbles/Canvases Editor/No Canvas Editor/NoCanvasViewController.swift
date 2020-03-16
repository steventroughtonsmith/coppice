//
//  NoCanvasViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class NoCanvasViewController: NSViewController {
}

extension NoCanvasViewController: SplitViewContainable {
    var splitViewItem: NSSplitViewItem {
        return NSSplitViewItem(viewController: self)
    }
}
