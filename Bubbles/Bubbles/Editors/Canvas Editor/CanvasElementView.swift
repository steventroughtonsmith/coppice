//
//  ResizableCanvasElement.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension LayoutEnginePageComponent {
    func cursor(isAtLimit: Bool = false) -> NSCursor {
        var cursorImage: NSImage? = nil
        switch (self) {
        case .resizeLeft:
            cursorImage = NSImage(named: "left-rightcursor")
        case .resizeRight:
            cursorImage = NSImage(named: "left-rightcursor")
        case .resizeTop:
            cursorImage = NSImage(named: "up-downcursor")
        case .resizeBottom:
            cursorImage = NSImage(named: "up-downcursor")
        case .resizeTopLeft:
            cursorImage = NSImage(named: "topleft-bottomrightcursor")
        case .resizeTopRight:
            cursorImage = NSImage(named: "bottomleft-toprightcursor")
        case .resizeBottomLeft:
            cursorImage = NSImage(named: "bottomleft-toprightcursor")
        case .resizeBottomRight:
            cursorImage = NSImage(named: "topleft-bottomrightcursor")
        default:
            break
        }


        guard let image = cursorImage else {
            return NSCursor.arrow
        }
        return NSCursor(image: image, hotSpot: NSPoint(x: 11, y: 11))
    }
}

class CanvasElementView: NSView  {
    let cornerSize: CGFloat = 8
    let edgeSize: CGFloat = 5

    @IBOutlet var titleBar: NSView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var boxView: NSBox!
    @IBOutlet weak var contentContainer: NSView!

    override var isFlipped: Bool {
        return true
    }

    func apply(_ layoutPage: LayoutEnginePage) {
        self.updateResizeRects(with: layoutPage)
        self.updateSubviews(with: layoutPage)
    }

    //MARK: - Subviews
    private func updateSubviews(with layoutPage: LayoutEnginePage) {
        self.boxView.frame = layoutPage.visualPageFrame
        self.titleBar.frame = layoutPage.titleFrameInsideVisualPage
        self.contentContainer.frame = layoutPage.contentFrameInsideVisualPage
    }


    //MARK: - Resize Rects
    private var resizeRects = [LayoutEnginePageComponent: CGRect]()
    private func updateResizeRects(with layoutPage: LayoutEnginePage) {
        self.resizeRects.removeAll()
        for resizeComponent in LayoutEnginePageComponent.allCases {
            guard resizeComponent != .titleBar else {
                continue
            }
            self.resizeRects[resizeComponent] = layoutPage.rectInLayoutFrame(for: resizeComponent)
        }
    }

    private func isPointInResizeRect(_ point: CGPoint) -> Bool {
        for (_, rect) in self.resizeRects {
            if (rect.contains(point)) {
                return true
            }
        }
        return false
    }


    override func hitTest(_ point: NSPoint) -> NSView? {
        let pointInBounds = self.convert(point, from: self.superview)
        if self.isPointInResizeRect(pointInBounds) {
            return self
        }
        let hitView = super.hitTest(point)
        if (hitView == self.titleBar || hitView == self.titleLabel || hitView == self.boxView) {
            return self
        }
        return hitView
    }

    override func mouseDown(with event: NSEvent) {
        self.canvasView?.mouseDown(with: event)
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

    //Cursor rects and NSTextView don't play nice, so we'll just go for the nuclear option
    override func mouseMoved(with event: NSEvent) {
        guard let canvasView = self.canvasView else {
            super.mouseMoved(with: event)
            return
        }

        //Ensure we're the top most view at this point
        let hitView = canvasView.hitTest(canvasView.convert(event.locationInWindow, from: nil))
        guard (hitView == self) && (canvasView.draggingCursor == nil) else {
            return
        }

        let location = self.convert(event.locationInWindow, from: nil)

        let cursorRects = self.resizeRects + [(.titleBar, self.titleBar.frame)]
        for (type, rect) in cursorRects {
            if (rect.contains(location)) {
                type.cursor().set()
                return
            }
        }
    }
}
