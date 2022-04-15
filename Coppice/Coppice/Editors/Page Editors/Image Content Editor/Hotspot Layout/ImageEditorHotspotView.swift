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

    var cropRect: CGRect = .zero {
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
        guard self.maintainsAspectRatio, self.cropRect.width > 0, self.cropRect.height > 0 else {
            self.aspectRatioConstraint = nil
            return
        }
        self.aspectRatioConstraint = self.widthAnchor.constraint(equalTo: self.heightAnchor, multiplier: self.cropRect.width / self.cropRect.height)
    }

    override var intrinsicContentSize: NSSize {
        guard self.cropRect.width > 0, self.cropRect.height > 0 else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }
        return self.cropRect.size
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        guard let layoutEngine = self.layoutEngine else {
            return
        }

        let scale = self.frame.width / self.cropRect.width

        let hotspotFill = NSColor(white: 1, alpha: 0.2)
        let selectedHotspotFill = NSColor.controlAccentColor.withAlphaComponent(0.2)
        let hotspotStroke = NSColor(white: 0, alpha: 0.6)

        for hotspot in layoutEngine.visibleHotspots {
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
        let aspectRatio = self.frame.width / self.cropRect.width
        return CGRect(origin: rect.origin.multiplied(by: aspectRatio), size: rect.size.multiplied(by: aspectRatio))
    }

    func convertPointToImageSpace(_ point: CGPoint) -> CGPoint {
        return point.multiplied(by: self.cropRect.width / self.frame.width)
    }

	//MARK: - Finding hotspots
	func containsHotspots(at point: CGPoint) -> Bool {
		return self.layoutEngine?.hotspot(at: point) != nil
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

    //MARK: - Highlight
    func highlight(_ rect: CGRect) {
        guard self.highlightView == nil else {
            return
        }

        let view = NSView(frame: rect.flipped(in: self.bounds).insetBy(dx: -2, dy: -2))
        view.wantsLayer = true
        view.layer?.borderColor = NSColor.findHighlightColor.cgColor
        view.layer?.borderWidth = 2
        view.layer?.cornerRadius = 5
        view.layer?.backgroundColor = NSColor.findHighlightColor.withAlphaComponent(0.3).cgColor
        self.highlightView = view

        NSAnimationContext.runAnimationGroup { _ in
            let animation = CAKeyframeAnimation(keyPath: #keyPath(CALayer.transform))
            var transform = CATransform3DIdentity
            transform = CATransform3DTranslate(transform, view.bounds.width / 2, view.bounds.height / 2, 0)
            transform = CATransform3DScale(transform, 1.3, 1.3, 1)
            transform = CATransform3DTranslate(transform, -view.bounds.width / 2, -view.bounds.height / 2, 0)

            animation.values = [CATransform3DIdentity, transform, CATransform3DIdentity]
            animation.keyTimes = [0, 0.3, 1]
            animation.duration = 0.2
            animation.timingFunctions = [CAMediaTimingFunction(name: .linear), CAMediaTimingFunction(name: .easeOut)]

            view.layer?.add(animation, forKey: "flashAnimation")
        } completionHandler: {
            NSView.animate(withDuration: 0.5) {
                view.alphaValue = 0
            } completion: {
                self.highlightView = nil
            }
        }
    }

    private var highlightView: NSView? {
        didSet {
            oldValue?.removeFromSuperview()
            if let newView = highlightView {
                self.addSubview(newView)
            }
        }
    }
}
