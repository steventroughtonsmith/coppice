//
//  InspectorRowView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class InspectorRowView: NSView, NIBInstantiable {
    static var nibName: String = "InspectorRowView"

    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var dataContainer: NSView!

    var dataView: InspectorDataView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let newDataView = self.dataView {
                self.dataContainer.addSubview(newDataView, withInsets: NSEdgeInsetsZero)
                self.label.stringValue = newDataView.title

                if let baselineView = newDataView.baselineView {
                    self.label.firstBaselineAnchor.constraint(equalTo: baselineView.firstBaselineAnchor).isActive = true
                } else {
                    self.label.centerYAnchor.constraint(equalTo: newDataView.centerYAnchor).isActive = true
                }
            }
        }
    }
}
