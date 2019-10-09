//
//  ResizableCanvasElement.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension LayoutEnginePageComponent {
    func cursor(isAtLimit: Bool = false) -> NSCursor? {
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
            return nil
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


    override func resetCursorRects() {
        super.resetCursorRects()

        for (type, rect) in self.resizeRects {
            if let cursor = type.cursor() {
                self.addCursorRect(rect, cursor: cursor)
            }
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
}
