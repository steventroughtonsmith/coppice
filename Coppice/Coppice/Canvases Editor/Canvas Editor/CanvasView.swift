//
//  CanvasView.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol CanvasViewDelegate: class {
    func willStartEditing(_ canvasView: CanvasView)
    func didDropPages(with ids: [ModelID], at point: CGPoint, on canvasView: CanvasView)
    func didDropFiles(withURLs urls: [URL], at point: CGPoint, on canvasView: CanvasView)

    func dragImageForPage(with id: ModelID, in canvasView: CanvasView) -> NSImage?
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

    func pageView(at point: CGPoint) -> CanvasElementView? {
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
        self.delegate?.willStartEditing(self)
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

    override func mouseMoved(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)

        self.updateCursor(forPageAt: point)
        self.layoutEngine?.moveEvent(at: point, modifiers: event.layoutEventModifiers)
    }

    override func keyDown(with event: NSEvent) {
        self.layoutEngine?.keyDownEvent(keyCode: event.keyCode, modifiers: event.layoutEventModifiers, isARepeat: event.isARepeat)
    }

    override func keyUp(with event: NSEvent) {
        self.layoutEngine?.keyUpEvent(keyCode: event.keyCode, modifiers: event.layoutEventModifiers)
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

    var drawsBackground: Bool = true {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        if self.drawsBackground {
            NSColor(named: "CanvasBackground")?.set()
            self.bounds.fill()
        }

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
        guard let types = sender.draggingPasteboard.types else {
            return []
        }

        if types.contains(ModelID.PasteboardType) {
            return self.pageDraggingUpdates(sender)
        }
        if types.contains(.fileURL) {
            return self.fileDraggingUpdates(sender)
        }
        return []
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        sender.animatesToDestination = true
        sender.draggingFormation = .none

        sender.enumerateDraggingItems(for: nil, classes: [NSPasteboardItem.self]) { (draggingItem, index, stop) in
            guard let pasteboardItem = draggingItem.item as? NSPasteboardItem,
                let modelID = ModelID(pasteboardItem: pasteboardItem),
                modelID.modelType == Page.modelType else {
                    return
            }

            guard let image = self.delegate?.dragImageForPage(with: modelID, in: self) else {
                return
            }

            draggingItem.setDraggingFrame(draggingItem.draggingFrame.rounded(), contents: image)
        }
        return true
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let types = sender.draggingPasteboard.types else {
            return false
        }

        if types.contains(ModelID.PasteboardType) {
            return self.performPageDragOperation(sender)
        }
        if types.contains(.fileURL) {
            return self.performFileDragOperation(sender)
        }
        return false
    }

    override func updateDraggingItemsForDrag(_ sender: NSDraggingInfo?) {
        guard let draggingInfo = sender else {
            return
        }
        draggingInfo.enumerateDraggingItems(for: nil, classes: [NSPasteboardItem.self], using: { (draggingItem, index, stop) in
            guard let pasteboardItem = draggingItem.item as? NSPasteboardItem,
                let modelID = ModelID(pasteboardItem: pasteboardItem),
                modelID.modelType == Page.modelType else {
                    return
            }
            guard let image = self.delegate?.dragImageForPage(with: modelID, in: self) else {
                return
            }


            let draggingFrame = draggingItem.draggingFrame.rounded()
            let midPoint = draggingFrame.midPoint
            let frameOrigin = midPoint.minus(x: image.size.width / 2, y: image.size.height / 2).rounded()

            draggingItem.setDraggingFrame(CGRect(origin: frameOrigin, size: image.size), contents: image)
        })
    }


    //MARK: - Page Drag & Drop
    func pageDraggingUpdates(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let item = sender.draggingPasteboard.pasteboardItems?.first,
            let id = ModelID(pasteboardItem: item) else {
                return []
        }
        if id.modelType == Page.modelType {
            return .copy
        }
        return []
    }

    func performPageDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let items = sender.draggingPasteboard.pasteboardItems else {
            return false
        }

        let ids = items.compactMap { ModelID(pasteboardItem: $0) }.filter { $0.modelType == Page.modelType }

        let dropPoint = self.convert(sender.draggingLocation, from: nil)
        var dragItemPoint: CGPoint? = nil
        sender.enumerateDraggingItems(for: nil, classes: [NSPasteboardItem.self]) { (draggingItem, index, stop) in
            let frame = draggingItem.draggingFrame.rounded()
            let windowFrame = self.window!.convertFromScreen(frame)
            if (dragItemPoint == nil) {
                dragItemPoint = self.convert(windowFrame, from: nil).midPoint
            }
            draggingItem.draggingFrame = frame
        }
        self.delegate?.didDropPages(with: ids, at: dragItemPoint ?? dropPoint, on: self)
        return true
    }


    //MARK: - File Drag & Drop
    func fileDraggingUpdates(_ sender: NSDraggingInfo) -> NSDragOperation {
        guard let items = sender.draggingPasteboard.pasteboardItems else {
            return []
        }
        return (items.count > 0) ? .copy : []
    }

    func performFileDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let items = sender.draggingPasteboard.pasteboardItems else {
            return false
        }

        let urls = items.compactMap{ $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
        let dropPoint = self.convert(sender.draggingLocation, from: nil)
        self.delegate?.didDropFiles(withURLs: urls, at: dropPoint, on: self)
        return true
    }


    //MARK: - Tracking Areas
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


    //MARK: - Cursor Handling
    var currentCursor: NSCursor?
    private func updateCursor(forPageAt point: CGPoint) {
        guard let pageView = self.pageView(at: point) else {
            NSCursor.arrow.set()
            return
        }
        //If for some reason you're wondering "Why is the cursor flickering away from what I set it to?" try quitting Photoshop
        //Don't ask me why, instead ask Adobe how they manage to fuck up the whole OS
        let pagePoint = self.convert(point, to: pageView)
        if let cursor = pageView.cursor(for: pagePoint) {
            cursor.set()
            self.currentCursor = cursor
        } else if (self.currentCursor != nil) {
            //Because the content view (especially text views) may have an inset its scroll view then they won't take over the cursor setting
            //So the first time we get a nil cursor we want to reset to an arrow, so our custom cursor doesn't stick around too long
            NSCursor.arrow.set()
            self.currentCursor = nil
        }
    }


    //MARK: - Debug
    var pageSpaceOrigin: CGPoint? {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }


    //MARK: - Thumbnail Helper
    private var thumbnailRect: CGRect {
        var thumbnailRect: CGRect? = nil
        for subview in self.pageLayer.subviews {
            guard let rect = thumbnailRect else {
                thumbnailRect = subview.frame
                continue
            }

            thumbnailRect = rect.union(subview.frame)
        }

        guard let finalRect = thumbnailRect else {
            return self.bounds
        }
        let inset: CGFloat = 40
        return finalRect.insetBy(dx: -inset, dy: -inset)
    }

    func generateThumbnail() -> NSImage? {
        let thumbnailRect = self.thumbnailRect
        guard let bitmapRep = self.bitmapImageRepForCachingDisplay(in: thumbnailRect) else {
            return nil
        }

        self.cacheDisplay(in: thumbnailRect, to: bitmapRep)

        let largeImage = NSImage(size: thumbnailRect.size)
        largeImage.addRepresentation(bitmapRep)

        let newSize = thumbnailRect.size.scaleDownToFit(width: GlobalConstants.maxCanvasThumbnailSize.width, height: GlobalConstants.maxCanvasThumbnailSize.height)
        let smallImage = NSImage(size: newSize, flipped: false) { (rect) -> Bool in
            largeImage.size = newSize
            NSGraphicsContext.current?.imageInterpolation = .high
            largeImage.draw(in: rect, from: CGRect(origin: .zero, size: newSize), operation: .copy, fraction: 1)
            return true
        }

        return smallImage
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
