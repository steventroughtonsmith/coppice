//
//  HoverView.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

@objc protocol HoverViewDelegate: class {
    func mouseDidEnter(_ hoverView: HoverView)
    func mouseDidExit(_ hoverView: HoverView)
}

class HoverView: NSView {
    @IBOutlet weak var delegate: HoverViewDelegate?
    var hoverTrackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let trackingArea = self.hoverTrackingArea {
            self.removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
        self.hoverTrackingArea = trackingArea
    }

    override func mouseEntered(with event: NSEvent) {
        self.delegate?.mouseDidEnter(self)
    }

    override func mouseExited(with event: NSEvent) {
        self.delegate?.mouseDidExit(self)
    }
}
