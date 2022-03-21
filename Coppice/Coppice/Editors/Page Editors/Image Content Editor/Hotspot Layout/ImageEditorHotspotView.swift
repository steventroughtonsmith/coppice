//
//  ImageEditorHotspotView.swift
//  Coppice
//
//  Created by Martin Pilkington on 09/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorHotspotView: NSView {
    override var acceptsFirstResponder: Bool {
        return true
    }

    override var isFlipped: Bool {
        return true
    }

    var imageSize: CGSize = .zero {
        didSet {
            self.invalidateIntrinsicContentSize()
            self.updateAspectRatioConstraint()
        }
    }

    var maintainsAspectRatio: Bool = true {
        didSet {
            self.updateAspectRatioConstraint()
        }
    }

    var layoutEngine: ImageEditorHotspotLayoutEngine? {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    private var aspectRatioConstraint: NSLayoutConstraint? {
        didSet {
            oldValue?.isActive = false
            self.aspectRatioConstraint?.isActive = true
        }
    }

    private func updateAspectRatioConstraint() {
        guard self.maintainsAspectRatio, self.imageSize.width > 0, self.imageSize.height > 0 else {
            self.aspectRatioConstraint = nil
            return
        }
        self.aspectRatioConstraint = self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: self.imageSize.width / self.imageSize.height)
    }

    override var intrinsicContentSize: NSSize {
        guard self.imageSize.width > 0, self.imageSize.height > 0 else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }
        return self.imageSize
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        guard let layoutEngine = self.layoutEngine else {
            return
        }

        let scale = self.frame.width / self.imageSize.width

        let hotspotFill = NSColor(white: 1, alpha: 0.2)
        let selectedHotspotFill = NSColor.controlAccentColor.withAlphaComponent(0.2)
        let hotspotStroke = NSColor(white: 0, alpha: 0.6)

        for hotspot in layoutEngine.hotspots {
            (hotspot.isSelected ? selectedHotspotFill : hotspotFill).setFill()
            hotspotStroke.setStroke()

            let hotspotPath = hotspot.hotspotPath(forScale: scale)
            hotspotPath.lineWidth = 2
            hotspotPath.fill()
            hotspotPath.stroke()

            if hotspot.isClicked {
                NSColor(white: 0, alpha: 0.15).setFill()
                hotspotPath.fill()
            } else if hotspot.isHighlighted {
                NSColor(white: 1, alpha: 0.15).setFill()
                hotspotPath.fill()
            }

            hotspot.editingBoundsPaths(forScale: scale).forEach { self.strokeEditingPath($0) }

            NSColor.white.setFill()
            hotspotStroke.setStroke()
            hotspot.editingHandleRects(forScale: scale).forEach {
                let bezierPath = NSBezierPath(ovalIn: $0)
                bezierPath.fill()
                bezierPath.stroke()
            }
        }
    }

    private func strokeEditingPath(_ editingPath: (path: NSBezierPath, phase: CGFloat)) {
        editingPath.path.lineWidth = 2
        NSColor.black.setStroke()
        editingPath.path.stroke()
        NSColor.white.setStroke()
        let steps: [CGFloat] = [4.0, 4.0]
        editingPath.path.setLineDash(steps, count: 2, phase: editingPath.phase)
        editingPath.path.stroke()
    }


    //MARK: - Conversion
    private func convertRectFromImageSpace(_ rect: CGRect) -> CGRect {
        let aspectRatio = self.frame.width / self.imageSize.width
        return CGRect(origin: rect.origin.multiplied(by: aspectRatio), size: rect.size.multiplied(by: aspectRatio))
    }

    func convertPointToImageSpace(_ point: CGPoint) -> CGPoint {
        return point.multiplied(by: self.imageSize.width / self.frame.width)
    }


    //MARK: - Events
    override func mouseDown(with event: NSEvent) {
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pointInImage = self.convertPointToImageSpace(pointInView)
        self.layoutEngine?.downEvent(at: pointInImage, modifiers: event.layoutEventModifiers, eventCount: event.clickCount)
    }

    override func mouseDragged(with event: NSEvent) {
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pointInImage = self.convertPointToImageSpace(pointInView)
        self.layoutEngine?.draggedEvent(at: pointInImage, modifiers: event.layoutEventModifiers, eventCount: event.clickCount)
    }

    override func mouseUp(with event: NSEvent) {
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pointInImage = self.convertPointToImageSpace(pointInView)
        self.layoutEngine?.upEvent(at: pointInImage, modifiers: event.layoutEventModifiers, eventCount: event.clickCount)
    }

    override func mouseMoved(with event: NSEvent) {
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pointInImage = self.convertPointToImageSpace(pointInView)
        self.layoutEngine?.movedEvent(at: pointInImage)
    }

    override func flagsChanged(with event: NSEvent) {
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pointInImage = self.convertPointToImageSpace(pointInView)
        self.layoutEngine?.flagsChanged(at: pointInImage, modifiers: event.layoutEventModifiers)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        return self.layoutEngine?.performKeyEquivalent(with: event.keyCode, modifiers: event.layoutEventModifiers) ?? false
    }

    //MARK: - Selection
    @IBAction override func selectAll(_ sender: Any?) {
        self.layoutEngine?.selectAll()
    }

    @IBAction func deselectAll(_ sender: Any?) {
        self.layoutEngine?.deselectAll()
    }


    //MARK: - Tracking Areas
    private var moveTrackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        if let moveTrackingArea = self.moveTrackingArea {
            self.removeTrackingArea(moveTrackingArea)
            self.moveTrackingArea = nil
        }

        let newTrackingArea = NSTrackingArea(rect: self.bounds, options: [.mouseMoved, .activeInKeyWindow], owner: self, userInfo: nil)
        self.moveTrackingArea = newTrackingArea
        self.addTrackingArea(newTrackingArea)
    }

    //MARK: - Layout Notification
    func layoutEngineDidChange() {
        self.setNeedsDisplay(self.bounds)
    }
}
