//
//  HoverSegmentedControl.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

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
        var chevronFrame = CGRect(x: self.bounds.maxX - 10, y: self.bounds.maxY - 10, width: 6, height: 5)
        if #available(OSX 10.16, *) {
            chevronFrame = CGRect(x: self.bounds.maxX - 16, y: self.bounds.maxY - 15, width: 6, height: 5)
        }
        self.chevronImage.frame = chevronFrame
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

