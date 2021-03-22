//
//  TextColourPicker.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore

@IBDesignable
class TextColourPicker: NSControl {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setup()
    }


    private func setup() {
        self.registerForDraggedTypes([.color])
        self.focusRingType = .exterior
        self.setupAccessibility()
    }


    //MARK: - Responder
    override var acceptsFirstResponder: Bool {
        return true
    }

    override var focusRingMaskBounds: NSRect {
        return self.bounds
    }


    //MARK: - Colour
    @objc dynamic var colour: NSColor = NSColor(hexString: "#00a000")! {
        didSet {
            self.setNeedsDisplay(self.bounds)
            self.colourGridView.selectedColour = self.colour
        }
    }


    //MARK: - View State
    private var isMouseInside = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    private var isDragInside = false {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        self.drawBorder()
        self.drawBackground()

        if (self.isMouseInside) {
            self.drawChevron()
        }

        if (self.isDragInside) {
            self.drawDragHighlight()
        }
    }

    private func drawBackground() {
        NSGraphicsContext.saveGraphicsState()

        let rect = self.controlRect.insetBy(dx: 1, dy: 1)
        let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        path.setClip()

        NSColor.white.set()
        rect.fill()

        let blackAlphaPath = NSBezierPath()
        blackAlphaPath.move(to: CGPoint(x: rect.minX, y: rect.minY))
        blackAlphaPath.line(to: CGPoint(x: rect.minX, y: rect.maxY))
        blackAlphaPath.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
        blackAlphaPath.line(to: CGPoint(x: rect.minX, y: rect.minY))

        NSColor.black.set()
        blackAlphaPath.fill()

        let clipPath = NSBezierPath(roundedRect: rect, xRadius: 4.5, yRadius: 4.5)
        clipPath.setClip()
        self.colour.set()
        rect.fill()

        NSGraphicsContext.restoreGraphicsState()
    }

    private func drawBorder() {
        NSGraphicsContext.saveGraphicsState()
        self.setupShadow()


        NSColor(named: "ControlBorder")?.set()
        let rect = self.controlRect.insetBy(dx: 0.5, dy: 0.5)
        let path = NSBezierPath(roundedRect: rect, xRadius: 5, yRadius: 5)
        path.fill()
        NSGraphicsContext.restoreGraphicsState()
    }

    private func setupShadow() {
        let shadow = NSShadow()
        shadow.shadowColor = NSColor.black.withAlphaComponent(0.4)
        shadow.shadowBlurRadius = 1
        shadow.shadowOffset = CGSize(width: 0, height: -1)
        shadow.set()
    }

    private func drawChevron() {
        let rect = self.controlRect.insetBy(dx: 1, dy: 1)
        var circleRect = CGRect(x: 0, y: 0, width: 13, height: 13)
        circleRect.origin.x = rect.maxX - 3 - circleRect.width
        circleRect.origin.y = rect.minY + 4

        NSColor.black.withAlphaComponent(self.isHighlighted ? 0.5 : 0.3).set()
        NSBezierPath(ovalIn: circleRect).fill()

        guard let chevron = NSImage(named: "DownChevron") else {
            return
        }
        let chevronOrigin = CGPoint(x: circleRect.midX - (chevron.size.width / 2),
                                    y: circleRect.midY - (chevron.size.height / 2) - 0.5)

        let chevronRect = CGRect(origin: chevronOrigin, size: chevron.size)
        chevron.draw(in: chevronRect)
    }

    private func drawDragHighlight() {
        NSColor.controlAccentColor.set()
        let path = NSBezierPath(roundedRect: self.controlRect.insetBy(dx: 1.5, dy: 1.5), xRadius: 4, yRadius: 4)
        path.lineWidth = 3
        path.stroke()
    }


    //MARK: - Helpers
    private var controlRect: CGRect {
        return self.alignmentRect(forFrame: self.bounds)
    }

    override var alignmentRectInsets: NSEdgeInsets {
        return NSEdgeInsets(top: 1, left: 2, bottom: 3, right: 2)
    }

    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: 23)
    }


    //MARK: - Tracking Area
    private var mouseOverTrackingArea: NSTrackingArea?
    override func updateTrackingAreas() {
        if let trackingArea = self.mouseOverTrackingArea {
            self.removeTrackingArea(trackingArea)
        }

        let trackingArea = NSTrackingArea(rect: self.bounds,
                                          options: [.activeInKeyWindow, .mouseEnteredAndExited],
                                          owner: self,
                                          userInfo: nil)
        self.addTrackingArea(trackingArea)
        self.mouseOverTrackingArea = trackingArea
    }


    //MARK: - Mouse Events
    override func mouseEntered(with event: NSEvent) {
        self.isMouseInside = true
    }

    override func mouseExited(with event: NSEvent) {
        self.isMouseInside = false
    }

    private var mouseDownLocation: CGPoint?

    override func mouseDown(with event: NSEvent) {
        self.mouseDownLocation = event.locationInWindow
    }

    override func mouseUp(with event: NSEvent) {
        self.showPopoverPanel()
    }

    private var draggingSession: NSDraggingSession?

    override func mouseDragged(with event: NSEvent) {
        guard let location = self.mouseDownLocation, self.draggingSession == nil else {
            return
        }
        let delta = event.locationInWindow.minus(location)
        guard abs(delta.x) >= 5 || abs(delta.y) >= 5 else {
            return
        }

        let dragItem = NSDraggingItem(pasteboardWriter: self.colour)
        let dragImage = self.colour.dragImage
        let dragPoint = self.convert(event.locationInWindow, from: nil).minus(dragImage.size.toRect().midPoint)
        let dragFrame = CGRect(origin: dragPoint, size: dragImage.size)
        dragItem.setDraggingFrame(dragFrame, contents: self.colour.dragImage)
        self.draggingSession = self.beginDraggingSession(with: [dragItem], event: event, source: self)
    }



    //MARK: - Dropping Colours
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        self.isDragInside = true
        return self.draggingUpdated(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let types = sender.draggingPasteboard.types else {
            return []
        }
        return types.contains(.color) ? .generic : []
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        self.isDragInside = false
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        self.isDragInside = false
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let colourData = sender.draggingPasteboard.pasteboardItems?.first?.data(forType: .color),
            let colour = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSColor.self, from: colourData)
        else {
                return false
        }

        self.colour = colour
        return true
    }


    //MARK: - Key Events

    override func keyUp(with event: NSEvent) {
        guard event.specialKey == .enter || event.keyCode == 49 /* space bar */ else {
            super.keyUp(with: event)
            return
        }
        self.showPopoverPanel()
    }


    //MARK: - Popover
    private lazy var colourGridView: ColourGridView = {
        let view = ColourGridView()
        view.delegate = self
        return view
    }()

    func showPopoverPanel() {
        let vc = NSViewController()
        vc.view = self.colourGridView
        self.colourGridView.selectedColour = self.colour

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = vc
        popover.show(relativeTo: self.bounds, of: self, preferredEdge: .minY)
    }


    //MARK: - Accessibility
    func setupAccessibility() {
        self.setAccessibilityElement(true)
        self.setAccessibilityRole(.colorWell)
        self.setAccessibilityTitle(NSLocalizedString("Text Colour", comment: "Text Colour picker accessibility title"))
    }
}

extension TextColourPicker: NSDraggingSource {
    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        return [.copy, .move, .generic]
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        self.draggingSession = nil
    }
}

extension TextColourPicker: ColourGridViewDelegate {
    func didSelect(_ colour: NSColor, in gridView: ColourGridView) {
        self.colour = colour
        self.sendAction(self.action, to: self.target)
    }
}
