//
//  CanvasView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol CanvasViewDelegate: class {
    func didDropPage(with id: ModelID, at point: CGPoint, on canvasView: CanvasView)
}

class CanvasView: NSView {
    override var isFlipped: Bool {
        return true
    }

    weak var delegate: CanvasViewDelegate?
    var layoutEngine: CanvasLayoutEngine?

    let pageLayer = FlippedView()
    let selectionLayer = FlippedView()
    let arrowLayer = FlippedView()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.setupLayers()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupLayers()
    }

    private func setupLayers() {
        let layers = [self.arrowLayer, self.pageLayer, self.selectionLayer]
        for layer in layers {
            layer.frame = self.bounds
            layer.autoresizingMask = [.height,  .width]
        }
        self.subviews = layers
    }

    override var wantsDefaultClipping: Bool {
        return false
    }

    func addPageView(_ view: CanvasElementView) {
        self.pageLayer.addSubview(view)
    }

    private func pageView(at point: CGPoint) -> CanvasElementView? {
        for subview in self.pageLayer.subviews.reversed() {
            if let pageView = subview as? CanvasElementView,
                pageView.frame.contains(point)
            {
                return pageView
            }
        }
        return nil
    }

    
    //MARK: - First Responder
    override var acceptsFirstResponder: Bool {
        return true
    }

    override func becomeFirstResponder() -> Bool {
        return true
    }

    override func resignFirstResponder() -> Bool {
        return true
    }


    //MARK: - Events
    var draggingCursor: NSCursor?
    override func mouseDown(with event: NSEvent) {
        //We need to save the cursor so we can force it remain the same during a drag
        self.draggingCursor = NSCursor.current
        self.window?.disableCursorRects()

        let point = self.convert(event.locationInWindow, from: nil)
        self.layoutEngine?.downEvent(at: point, modifiers: event.layoutEventModifiers, eventCount: event.clickCount)
        self.window?.makeFirstResponder(self)
    }

    override func mouseDragged(with event: NSEvent) {
        self.draggingCursor?.set()
        let point = self.convert(event.locationInWindow, from: nil)
        self.layoutEngine?.draggedEvent(at: point, modifiers: event.layoutEventModifiers, eventCount: event.clickCount)
        self.startAutoscrolling(with: event)
    }

    override func mouseUp(with event: NSEvent) {
        self.draggingCursor = nil
        self.window?.enableCursorRects()
        let point = self.convert(event.locationInWindow, from: nil)
        self.layoutEngine?.upEvent(at: point, modifiers: event.layoutEventModifiers, eventCount: event.clickCount)
        self.stopAutoscrolling()
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        guard let view = self.pageLayer.hitTest(point) else {
            return self
        }
        return view
    }


    //MARK: - Auto scrolling
    @objc func startAutoscrolling(with event: NSEvent) {
        self.stopAutoscrolling()

        guard let contentView = self.enclosingScrollView?.contentView else {
            return
        }
        let previousPosition = contentView.bounds.origin
        if (self.autoscroll(with: event)) {
            let delta = contentView.bounds.origin.minus(previousPosition)
            let point = self.convert(event.locationInWindow, from: nil).plus(delta)
            self.layoutEngine?.draggedEvent(at: point, modifiers: event.layoutEventModifiers)
            self.perform(#selector(startAutoscrolling(with:)), with: event, afterDelay: 0.01)
        }
    }

    private func stopAutoscrolling() {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
    }


    //MARK: - Selection Rect
    var selectionRect: CGRect? {
        didSet {
            self.updateSelectionRect()
        }
    }

    private var selectionView: NSView?

    private func updateSelectionRect() {
        guard let selectionRect = self.selectionRect else {
            self.selectionView?.removeFromSuperview()
            self.selectionView = nil
            return
        }

        if self.selectionView == nil {
            let selectionView = self.createSelectionView()
            self.selectionLayer.addSubview(selectionView)
            self.selectionView = selectionView
        }

        self.selectionView?.frame = selectionRect.rounded()
    }

    private func createSelectionView() -> NSView {
        let selectionView = NSView()
        selectionView.wantsLayer = true
        selectionView.layer?.backgroundColor = NSColor(white: 0, alpha: 0.3).cgColor
        selectionView.layer?.borderColor = NSColor(white: 0, alpha: 0.5).cgColor
        selectionView.layer?.borderWidth = 1
        selectionView.identifier = NSUserInterfaceItemIdentifier("SelectionView")
        return selectionView
    }


    override func draw(_ dirtyRect: NSRect) {
        NSColor(named: "CanvasBackground")?.set()
        self.bounds.fill()

        if let pageSpaceOrigin = self.pageSpaceOrigin {
            NSColor(named: "DebugCanvasAxes")?.set()
            CGRect(x: pageSpaceOrigin.x, y: 0, width: 1, height: self.bounds.height).fill()
            CGRect(x: 0, y: pageSpaceOrigin.y, width: self.bounds.width, height: 1).fill()
        }
    }


    //MARK: - Drag & Drop
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return self.draggingUpdated(sender)
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let item = sender.draggingPasteboard.pasteboardItems?.first,
            let id = ModelID(pasteboardItem: item) else {
                return []
        }
        if id.modelType == Page.modelType {
            return .copy
        }
        return []
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let item = sender.draggingPasteboard.pasteboardItems?.first,
            let id = ModelID(pasteboardItem: item),
            id.modelType == Page.modelType else {
            return false
        }

        let dropPoint = self.convert(sender.draggingLocation, from: nil)
        self.delegate?.didDropPage(with: id, at: dropPoint, on: self)
        return true
    }


    //MARK: - Cursor Handling
    override func updateTrackingAreas() {
        for area in self.trackingAreas {
            self.removeTrackingArea(area)
        }

        //NSTrackingArea isn't clipped by superviews so we need to do that manually
        var trackingRect = self.bounds
        if let scrollView = self.enclosingScrollView {
            let frame = self.convert(scrollView.frame, from: scrollView)
            trackingRect = trackingRect.intersection(frame)
        }

        guard (trackingRect.width > 0) && (trackingRect.height > 0) else {
            return
        }

        let area = NSTrackingArea(rect: trackingRect,
                                  options: [.activeInActiveApp, .mouseMoved],
                                  owner: self,
                                  userInfo: nil)
        self.addTrackingArea(area)
    }

    override func mouseMoved(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        guard let pageView = self.pageView(at: point) else {
            NSCursor.arrow.set()
            return
        }
        let pagePoint = self.convert(point, to: pageView)
        pageView.cursor(for: pagePoint)?.set()
    }


    //MARK: - Debug
    var pageSpaceOrigin: CGPoint? {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }
}


extension NSEvent {
    var layoutEventModifiers: LayoutEventModifiers {
        var modifiers = [LayoutEventModifiers]()
        if self.modifierFlags.contains(.shift) {
            modifiers.append(.shift)
        }
        if self.modifierFlags.contains(.command) {
            modifiers.append(.command)
        }
        if self.modifierFlags.contains(.option) {
            modifiers.append(.option)
        }
        if self.modifierFlags.contains(.control) {
            modifiers.append(.control)
        }
        return LayoutEventModifiers(modifiers)
    }
}
