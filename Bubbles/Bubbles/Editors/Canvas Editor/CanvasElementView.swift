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

    private lazy var disabledContentMouseStealer = NSView()

    override var isFlipped: Bool {
        return true
    }

    var enabled: Bool = true {
        didSet {
            self.updateMouseStealerVisibility()
        }
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
        self.disabledContentMouseStealer.frame = layoutPage.contentFrameInsideVisualPage
    }

    private func updateMouseStealerVisibility() {
        if (self.enabled) {
            self.disabledContentMouseStealer.removeFromSuperview()
        } else {
            self.addSubview(self.disabledContentMouseStealer)
        }
    }


    //MARK: - Resize Rects
    private var resizeRects = [LayoutEnginePageComponent: CGRect]()
    private func updateResizeRects(with layoutPage: LayoutEnginePage) {
        self.resizeRects.removeAll()
        for resizeComponent in LayoutEnginePageComponent.allCases {
            guard resizeComponent != .titleBar && resizeComponent != .content else {
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
        guard self.bounds.contains(pointInBounds) else {
            return nil
        }
        if self.isPointInResizeRect(pointInBounds) {
            return self
        }
        let hitView = super.hitTest(point)
        if (hitView == self.titleBar || hitView == self.titleLabel || hitView == self.boxView || hitView == self.disabledContentMouseStealer) {
            return self
        }
        return hitView
    }

    override func mouseDown(with event: NSEvent) {
        self.canvasView?.mouseDown(with: event)
    }


    //MARK: - Cursor Handling
    func cursor(for point: CGPoint) -> NSCursor? {
        let cursorRects = self.resizeRects + [(.titleBar, self.titleBar.frame)]
        for (type, rect) in cursorRects {
            if (rect.contains(point)) {
                return type.cursor()
            }
        }
        if !self.enabled {
            return NSCursor.arrow
        }
        return nil
    }
}
