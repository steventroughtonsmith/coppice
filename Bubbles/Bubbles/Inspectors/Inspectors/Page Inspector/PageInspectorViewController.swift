//
//  PageInspectorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageInspectorViewController: BaseInspectorViewController {
    override var dataViewsNibName: NSNib.Name? {
        return "PageInspectorDataViews"
    }

    override var dataViewIdentifiers: [NSUserInterfaceItemIdentifier] {
        return [
            NSUserInterfaceItemIdentifier("page.title")
        ]
    }
}


