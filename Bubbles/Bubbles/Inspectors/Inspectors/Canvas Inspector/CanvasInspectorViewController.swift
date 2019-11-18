//
//  CanvasInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasInspectorViewController: BaseInspectorViewController {
    override var dataViewsNibName: NSNib.Name? {
        return "CanvasInspectorDataViews"
    }

    override var dataViewIdentifiers: [NSUserInterfaceItemIdentifier] {
        return [
            NSUserInterfaceItemIdentifier("canvas.title")
        ]
    }
}
