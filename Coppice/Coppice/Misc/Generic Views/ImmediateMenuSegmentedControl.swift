//
//  ImmediateMenuSegmentedControl.swift
//  Coppice
//
//  Created by Martin Pilkington on 29/06/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class ImmediateMenuSegmentedControl: NSSegmentedControl {

    override func mouseDown(with event: NSEvent) {
        let typedCell = (self.cell as? ImmediateMenuSegmentedCell)
        let location = self.convert(event.locationInWindow, from: nil)
        if self.subviews.count == self.segmentCount, //Ensure the only views are the subviews for the segment
           let index = self.subviews.firstIndex(where: { $0.frame.contains(location) }),
           self.menu(forSegment: index) != nil {
            typedCell?.blockAction = true
        } else {
            typedCell?.blockAction = false
        }
        super.mouseDown(with: event)

    }
}

class ImmediateMenuSegmentedCell: NSSegmentedCell {
    //We want to block the action so the menu is shown immediately
    var blockAction = false
    override var action: Selector? {
        get { return self.blockAction ? nil : super.action }
        set { super.action = newValue }
    }
}
