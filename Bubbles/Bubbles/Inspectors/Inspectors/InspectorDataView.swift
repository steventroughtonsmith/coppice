//
//  InspectorDataView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class InspectorDataView: NSView {
    @IBInspectable var title: String = ""

    @IBOutlet var baselineView: NSView?
}
