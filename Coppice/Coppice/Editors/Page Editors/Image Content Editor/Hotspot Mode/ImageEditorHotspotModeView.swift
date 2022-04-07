//
//  ImageEditorHotspotModeView.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit

class ImageEditorHotspotModeView: NSView {
    @IBOutlet var hotspotView: ImageEditorHotspotView!
    @IBOutlet var segmentedControl: NSSegmentedControl!

    private var hoverTrackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        if let trackingArea = self.hoverTrackingArea {
            self.removeTrackingArea(trackingArea)
        }

        let newTrackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseMoved], owner: self, userInfo: nil)
        self.hoverTrackingArea = newTrackingArea
        self.addTrackingArea(newTrackingArea)
    }

    override func mouseMoved(with event: NSEvent) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.switchToHiddenMode), object: nil)

        let point = self.convert(event.locationInWindow, from: nil)
        if self.hotspotView.frame.contains(point), self.segmentedControl.frame.contains(point) {
            self.perform(#selector(self.switchToHiddenMode), with: nil, afterDelay: 1)
        }
        self.mode = .normal
    }

    @objc private func switchToHiddenMode() {
        self.mode = .segmentedHidden
    }

    enum Mode: Equatable {
        case normal
        case segmentedHidden
    }

    private var mode: Mode = .normal {
        didSet {
            switch self.mode {
            case .normal:
                self.segmentedControl.animator().alphaValue = 1
            case .segmentedHidden:
                self.segmentedControl.animator().alphaValue = 0.2
            }
        }
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        var view = super.hitTest(point)
        if self.mode == .segmentedHidden, view == self.segmentedControl {
            view = self.hotspotView
        }
        return view
    }
}
