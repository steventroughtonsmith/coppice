//
//  EdgeResizable.swift
//  CanvasTest
//
//  Created by Martin Pilkington on 29/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

enum ResizeEdge: CaseIterable, Equatable {
    case left
    case topLeft
    case top
    case topRight
    case right
    case bottomRight
    case bottom
    case bottomLeft

    func cursor(isAtLimit: Bool = false) -> NSCursor {
        var cursorImage: NSImage? = nil
        switch (self) {
        case .left:
            cursorImage = NSImage(named: "left-rightcursor")
        case .right:
            cursorImage = NSImage(named: "left-rightcursor")
        case .top:
            cursorImage = NSImage(named: "up-downcursor")
        case .bottom:
            cursorImage = NSImage(named: "up-downcursor")
        case .topLeft:
            cursorImage = NSImage(named: "topleft-bottomrightcursor")
        case .topRight:
            cursorImage = NSImage(named: "bottomleft-toprightcursor")
        case .bottomLeft:
            cursorImage = NSImage(named: "bottomleft-toprightcursor")
        case .bottomRight:
            cursorImage = NSImage(named: "topleft-bottomrightcursor")
        }


        guard let image = cursorImage else {
            fatalError()
        }
        return NSCursor(image: image, hotSpot: NSPoint(x: 11, y: 11))
    }

    var canResizeWidth: Bool {
        return self.isLeft || self.isRight
    }

    var canResizeHeight: Bool {
        self.isTop || self.isBottom
    }

    var isLeft: Bool {
        switch (self) {
        case .topLeft, .left, .bottomLeft:
            return true
        default:
            return false
        }
    }

    var isRight: Bool {
        switch (self) {
        case .topRight, .right, .bottomRight:
            return true
        default:
            return false
        }
    }

    var isTop: Bool {
        switch (self) {
        case .top, .topLeft, .topRight:
            return true
        default:
            return false
        }
    }

    var isBottom: Bool {
        switch (self) {
        case .bottom, .bottomLeft, .bottomRight:
            return true
        default:
            return false
        }
    }
}

protocol EdgeResizable: class {
    var cachedResizeRects: [(ResizeEdge, CGRect)] { get set }
    var cornerSize: CGFloat { get }
    var edgeSize: CGFloat { get }

    func generateResizeRects()
    func resizeRect(for resizeType: ResizeEdge) -> CGRect
    func resizeType(at point: CGPoint) -> ResizeEdge?
}


extension EdgeResizable where Self: NSView {
    func generateResizeRects() {
        var cache = [(ResizeEdge, CGRect)]()
        for type in ResizeEdge.allCases {
            cache.append((type, self.resizeRect(for: type)))
        }
        self.cachedResizeRects = cache
    }

    func resizeRect(for resizeType: ResizeEdge) -> CGRect {
        let cornerSize: CGFloat = self.cornerSize
        let edgeSize: CGFloat = self.edgeSize

        let bounds = self.bounds
        let size: CGSize
        switch resizeType {
        case .topLeft, .topRight, .bottomLeft, .bottomRight:
            size = CGSize(width: cornerSize, height: cornerSize)
        case .left, .right:
            size = CGSize(width: edgeSize, height: (bounds.height - (2 * cornerSize)))
        case .top, .bottom:
            size = CGSize(width: (bounds.width - (2 * cornerSize)), height: edgeSize)
        }

        let x: CGFloat
        switch resizeType {
        case .topLeft, .left, .bottomLeft:
            x = 0
        case .topRight, .right, .bottomRight:
            x = (bounds.maxX - size.width)
        case .top, .bottom:
            x = cornerSize
        }

        let y: CGFloat
        switch resizeType {
        case .topLeft, .top, .topRight:
            y = (bounds.maxY - size.height)
        case .bottomLeft, .bottom, .bottomRight:
            y = 0
        case .left, .right:
            y = cornerSize
        }

        return CGRect(origin: CGPoint(x: x, y: y), size: size)
    }

    func resizeType(at point: CGPoint) -> ResizeEdge? {
        for (type, rect) in self.cachedResizeRects {
            if (rect.contains(point)) {
                return type
            }
        }
        return nil
    }
}
