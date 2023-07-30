//
//  InspectorUpsellView.swift
//  InspectorUpsellView
//
//  Created by Martin Pilkington on 18/10/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import AppKit

class InspectorUpsellView: NSView {
    var proFeature: ProFeature? {
        didSet {
            self.updateTrackingAreas()
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        NSColor(named: "CoppiceInspectorBackground")?.set()
        self.bounds.fill()

        NSColor(named: "CoppiceInspectorBorder")?.set()
        NSBezierPath(rect: self.bounds.insetBy(dx: -1, dy: 0.5)).stroke()

        NSColor(named: "CoppiceGreen")?.set()
        CGRect(x: 0, y: 0, width: 4, height: self.bounds.height).fill()
    }

    private var trackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        super.updateTrackingAreas()

        if let trackingArea = self.trackingArea {
            self.removeTrackingArea(trackingArea)
        }

        guard self.proFeature != nil else {
            return
        }

        let trackingArea = NSTrackingArea(rect: self.bounds, options: [.activeInKeyWindow, .mouseEnteredAndExited], owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
        self.trackingArea = trackingArea
    }

    private var popover: NSPopover? {
        didSet {
            oldValue?.close()
            self.popover?.show(relativeTo: self.bounds, of: self, preferredEdge: .maxX)
        }
    }

    override func mouseEntered(with event: NSEvent) {
        guard self.proFeature != nil else {
            return
        }

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.showProPopover), object: nil)
        self.perform(#selector(self.showProPopover), with: nil, afterDelay: 1)
    }

    @objc func showProPopover() {
        guard let proFeature = self.proFeature else {
            return
        }
        self.popover = CoppiceProUpsell.shared.createProPopover(for: proFeature, userAction: .hover)
    }

    override func mouseExited(with event: NSEvent) {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.showProPopover), object: nil)
        self.popover = nil
    }
}
