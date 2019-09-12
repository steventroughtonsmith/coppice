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

class ResizableCanvasElement: NSView  {
    let cornerSize: CGFloat = 8
    let edgeSize: CGFloat = 5

    @IBOutlet var titleBar: NSView!
    @IBOutlet var titleLabel: NSTextField!
    @IBOutlet var boxView: NSBox!

    var cachedResizeRects = [(LayoutEnginePageComponent, CGRect)]()

    override var isFlipped: Bool {
        return true
    }

    private func generateResizeRects() {
        var cache = [(LayoutEnginePageComponent, CGRect)]()
        for component in LayoutEnginePageComponent.allCases {
            guard component != .titleBar else {
                continue
            }
            cache.append((component, self.rect(for: component)))
        }
        self.cachedResizeRects = cache
    }

    override func resetCursorRects() {
        super.resetCursorRects()

        self.generateResizeRects()
        for (type, rect) in self.cachedResizeRects {
            if let cursor = type.cursor() {
                self.addCursorRect(rect, cursor: cursor)
            }
        }
    }

    func rect(for component: LayoutEnginePageComponent) -> CGRect {
        let cornerSize: CGFloat = self.cornerSize
        let edgeSize: CGFloat = self.edgeSize

        let bounds = self.bounds
        let size: CGSize
        switch component {
        case .resizeTopLeft, .resizeTopRight, .resizeBottomLeft, .resizeBottomRight:
            size = CGSize(width: cornerSize, height: cornerSize)
        case .resizeLeft, .resizeRight:
            size = CGSize(width: edgeSize, height: (bounds.height - (2 * cornerSize)))
        case .resizeTop, .resizeBottom:
            size = CGSize(width: (bounds.width - (2 * cornerSize)), height: edgeSize)
        case .titleBar:
            size = self.titleBar.frame.size
        }

        let x: CGFloat
        switch component {
        case .resizeTopLeft, .resizeLeft, .resizeBottomLeft:
            x = 0
        case .resizeTopRight, .resizeRight, .resizeBottomRight:
            x = (bounds.maxX - size.width)
        case .resizeTop, .resizeBottom:
            x = cornerSize
        case .titleBar:
            x = self.titleBar.frame.minX
        }

        let y: CGFloat
        switch component {
        case .resizeTopLeft, .resizeTop, .resizeTopRight:
            y = 0
        case .resizeBottomLeft, .resizeBottom, .resizeBottomRight:
            y = (bounds.maxY - size.height)
        case .resizeLeft, .resizeRight:
            y = cornerSize
        case .titleBar:
            y = self.boxView.frame.minY
        }

        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    func component(at point: CGPoint) -> LayoutEnginePageComponent? {
        for (type, rect) in self.cachedResizeRects {
            if (rect.contains(point)) {
                return type
            }
        }

        if (self.rect(for: .titleBar).contains(point)) {
            return .titleBar
        }
        return nil
    }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let pointInBounds = self.convert(point, from: self.superview)
        if let component = self.component(at: pointInBounds), component != .titleBar {
            return self
        }
        let hitView = super.hitTest(point)
        if (hitView == self.titleBar || hitView == self.titleLabel || hitView == self.boxView) {
            return self
        }
        return hitView
    }
}
