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

class HoverSegmentedControl: NSSegmentedControl {    
    private var hoverTrackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let area = self.hoverTrackingArea {
            self.removeTrackingArea(area)
        }
        
        let area = NSTrackingArea(rect: self.bounds, options: [.mouseEnteredAndExited, .enabledDuringMouseDrag, .activeInKeyWindow], owner: self, userInfo: nil)
        self.hoverTrackingArea = area
        self.addTrackingArea(area)
    }
    
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.addSubview(self.chevronImage)
        self.chevronImage.frame = CGRect(x: self.bounds.maxX - 16, y: self.bounds.maxY - 15, width: 6, height: 5)
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.chevronImage.removeFromSuperview()
        
    }
    
    private var chevronImage: NSImageView = {
        let imageView = NSImageView(image: NSImage(named: "DownChevron")!)
        return imageView
    }()
}
