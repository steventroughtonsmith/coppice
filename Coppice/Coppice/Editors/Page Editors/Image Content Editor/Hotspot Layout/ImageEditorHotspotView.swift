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
            oldValue?.delegate = nil
            self.layoutEngine?.delegate = self
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

        for hotspot in layoutEngine.hotspots {
            NSColor.black.withAlphaComponent(0.8).setFill()
            NSColor.white.setStroke()
            hotspot.hotspotPath(forScale: scale).fill()
            hotspot.hotspotPath(forScale: scale).stroke()

            NSColor.white.setFill()
            hotspot.editingHandleRects(forScale: scale).forEach { $0.fill() }
        }
    }


    //MARK: - Conversion
    private func convertRectFromImageSpace(_ rect: CGRect) -> CGRect {
        let aspectRatio = self.frame.width / self.imageSize.width
        return CGRect(origin: rect.origin.multiplied(by: aspectRatio), size: rect.size.multiplied(by: aspectRatio))
    }

    private func convertPointToImageSpace(_ point: CGPoint) -> CGPoint {
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

    override func flagsChanged(with event: NSEvent) {
        let pointInView = self.convert(event.locationInWindow, from: nil)
        let pointInImage = self.convertPointToImageSpace(pointInView)
        self.layoutEngine?.flagsChanged(at: pointInImage, modifiers: event.layoutEventModifiers)
    }
}

extension ImageEditorHotspotView: ImageEditorHotspotLayoutEngineDelegate {
    func layoutDidChange(in layoutEngine: ImageEditorHotspotLayoutEngine) {
        self.setNeedsDisplay(self.bounds)
    }

    func didCommitEdit(in layoutEngine: ImageEditorHotspotLayoutEngine) {
        //TODO
    }
}
