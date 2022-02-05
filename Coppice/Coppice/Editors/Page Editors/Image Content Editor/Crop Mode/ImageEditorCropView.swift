//
//  ImageEditorCropView.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa

//TODO: Shrink down handles when size gets too small
//TODO: Move crop area around
//TODO: Show dimensions when cropping (potentially also set dimensions)
//TODO: Scrolling
//TODO: Convert view crop rect to image crop rect
//TODO: Make accessibile

class ImageEditorCropView: NSView {
    override var isFlipped: Bool {
        return true
    }

    /// The crop rectangle of the image, based of the image's top-left corner
    var cropRect: CGRect = .zero {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

    /// The size of the image being cropped, used to set a maximum crop rect size
    var imageSize: CGSize = .zero

    /// How much the crop view is inset from the underlying image
    var insets: NSEdgeInsets = NSEdgeInsetsZero

    //MARK: - Events
    private struct DragState {
        var initialPoint: CGPoint
        var initialCropRect: CGRect
        var draggedHandle: DragHandle
    }

    private var dragState: DragState?

    override func mouseDown(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        guard let draggedHandle = self.dragHandle(at: point) else {
            return
        }
        self.dragState = DragState(initialPoint: point, initialCropRect: self.cropRect, draggedHandle: draggedHandle)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let dragState = self.dragState else {
            return
        }

        let pointInView = self.convert(event.locationInWindow, from: nil)

        let delta = pointInView.minus(dragState.initialPoint)

        self.cropRect = dragState.draggedHandle.adjustedCropRect(withInitialRect: dragState.initialCropRect, delta: delta, maxSize: self.imageSize)
    }

    override func mouseUp(with event: NSEvent) {
        self.dragState = nil
    }

    private func dragHandle(at point: CGPoint) -> DragHandle? {
        for dragHandle in DragHandle.allCases {
            if
                let interactionBound = dragHandle.interactionBound(for: self.drawingRect),
                interactionBound.contains(point)
            {
                return dragHandle
            }
        }
        return nil
    }


    //MARK: - Drawing
    /// The frame in the view in which to actually draw the crop rect (inset by insets)
    private var drawingRect: CGRect {
        return self.cropRect.moved(byX: insets.left, y: insets.top)
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        self.drawClipBox()
        self.drawDragHandles()
    }

    private func drawClipBox() {
        NSColor(named: "CropModeBackground")?.set()
        let path = NSBezierPath(rect: self.bounds)
        let clipPath = NSBezierPath(rect: self.drawingRect).reversed
        path.append(clipPath)

        path.fill()

        NSColor(white: 1, alpha: 0.2).set()
        NSBezierPath(rect: self.drawingRect.insetBy(dx: 0.5, dy: 0.5)).stroke()
    }

    private func drawDragHandles() {
        for dragHandle in DragHandle.allCases {
            guard let path = dragHandle.path(for: self.drawingRect) else {
                continue
            }
            NSColor(white: 0, alpha: 0.8).set()
            path.lineWidth = DragHandle.handleDepth
            path.stroke()
            NSColor.white.set()
            path.lineWidth = DragHandle.handleDepth - 2
            path.stroke()
        }
    }
}

extension ImageEditorCropView {
    enum DragHandle: CaseIterable {
        case topLeft
        case top
        case topRight
        case right
        case bottomRight
        case bottom
        case bottomLeft
        case left

        private static let sideHandleLength: CGFloat = 26.0
        private static let cornerHandleLength: CGFloat = 18.0
        private static let minimumCornerHandleLength: CGFloat = 10.0
        private static let interactionMargin: CGFloat = 2
        static let handleDepth: CGFloat = 8

        static var minimumSize: CGFloat {
            return ((Self.minimumCornerHandleLength + Self.interactionMargin) * 2) + Self.handleDepth
        }

        static var minimumSizeForSideHandles: CGFloat {
            return Self.sideHandleLength + (Self.cornerHandleLength * 2) + 8 + 8
        }

        var isTop: Bool {
            switch self {
            case .topLeft, .top, .topRight:
                return true
            case .right, .bottomRight, .bottom, .bottomLeft, .left:
                return false
            }
        }

        var isBottom: Bool {
            switch self {
            case .bottomLeft, .bottom, .bottomRight:
                return true
            case .right, .topRight, .top, .topLeft, .left:
                return false
            }
        }

        var isLeft: Bool {
            switch self {
            case .topLeft, .left, .bottomLeft:
                return true
            case .right, .bottomRight, .bottom, .topRight, .top:
                return false
            }
        }

        var isRight: Bool {
            switch self {
            case .bottomRight, .right, .topRight:
                return true
            case .top, .topLeft, .bottom, .bottomLeft, .left:
                return false
            }
        }

        private func cornerHandleLength(for rect: CGRect) -> CGFloat {
            max(min(Self.cornerHandleLength, min(rect.height, rect.width) * 0.25), Self.minimumCornerHandleLength)
        }

        /// The path for drawing a particular drag handle in the supplied rect
        func path(for rect: CGRect) -> NSBezierPath? {
            let horizontalSideHandleLength = Self.sideHandleLength
            let verticalSideHandleLength = Self.sideHandleLength

            let cornerHandleLength = self.cornerHandleLength(for: rect)


            let bezierPath = NSBezierPath()
            switch self {
            case .top:
                guard rect.width >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                bezierPath.move(to: CGPoint(x: rect.midX - (horizontalSideHandleLength / 2), y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.midX + (horizontalSideHandleLength / 2), y: rect.minY))
            case .bottom:
                guard rect.width >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                bezierPath.move(to: CGPoint(x: rect.midX - (horizontalSideHandleLength / 2), y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.midX + (horizontalSideHandleLength / 2), y: rect.maxY))
            case .left:
                guard rect.height >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                bezierPath.move(to: CGPoint(x: rect.minX, y: rect.midY - (verticalSideHandleLength / 2)))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.midY + (verticalSideHandleLength / 2)))
            case .right:
                guard rect.height >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                bezierPath.move(to: CGPoint(x: rect.maxX, y: rect.midY - (verticalSideHandleLength / 2)))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.midY + (verticalSideHandleLength / 2)))
            case .topLeft:
                bezierPath.move(to: CGPoint(x: rect.minX, y: rect.minY + cornerHandleLength))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.minX + cornerHandleLength, y: rect.minY))
            case .topRight:
                bezierPath.move(to: CGPoint(x: rect.maxX - cornerHandleLength, y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.minY + cornerHandleLength))
            case .bottomRight:
                bezierPath.move(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerHandleLength))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.maxX - cornerHandleLength, y: rect.maxY))
            case .bottomLeft:
                bezierPath.move(to: CGPoint(x: rect.minX + cornerHandleLength, y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.maxY - cornerHandleLength))
            }
            bezierPath.lineCapStyle = .round
            bezierPath.lineJoinStyle = .round
            return bezierPath
        }

        /// Returns the rectangle in which a can click in the supplied rect to interact with the current handle
        func interactionBound(for rect: CGRect) -> CGRect? {
            let sideInteractionLength = Self.sideHandleLength + Self.handleDepth + (2 * Self.interactionMargin)
            let sideInteractionDepth = Self.handleDepth + (2 * Self.interactionMargin)
            let cornerHandleLength = self.cornerHandleLength(for: rect)
            let cornerSize = cornerHandleLength + Self.handleDepth + (2 * Self.interactionMargin)
            let cornerOffset = Self.interactionMargin + (Self.handleDepth / 2)
            switch self {
            case .top:
                guard rect.width >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                return CGRect(x: rect.midX - (sideInteractionLength / 2), y: rect.minY - (sideInteractionDepth / 2), width: sideInteractionLength, height: sideInteractionDepth)
            case .right:
                guard rect.height >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                return CGRect(x: rect.maxX - (sideInteractionDepth / 2), y: rect.midY - (sideInteractionLength / 2), width: sideInteractionDepth, height: sideInteractionLength)
            case .bottom:
                guard rect.width >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                return CGRect(x: rect.midX - (sideInteractionLength / 2), y: rect.maxY - (sideInteractionDepth / 2), width: sideInteractionLength, height: sideInteractionDepth)
            case .left:
                guard rect.height >= Self.minimumSizeForSideHandles else {
                    return nil
                }
                return CGRect(x: rect.minX - (sideInteractionDepth / 2), y: rect.midY - (sideInteractionLength / 2), width: sideInteractionDepth, height: sideInteractionLength)
            case .topLeft:
                return CGRect(x: rect.minX - cornerOffset, y: rect.minY - cornerOffset, width: cornerSize, height: cornerSize)
            case .topRight:
                return CGRect(x: rect.maxX - cornerOffset - cornerHandleLength, y: rect.minY - cornerOffset, width: cornerSize, height: cornerSize)
            case .bottomRight:
                return CGRect(x: rect.maxX - cornerOffset - cornerHandleLength, y: rect.maxY - cornerOffset - cornerHandleLength, width: cornerSize, height: cornerSize)
            case .bottomLeft:
                return CGRect(x: rect.minX - cornerOffset, y: rect.maxY - cornerOffset - cornerHandleLength, width: cornerSize, height: cornerSize)
            }
        }


        /// Adjust the crop rect by a delta, constraining by a minimum and maximum size
        func adjustedCropRect(withInitialRect cropRect: CGRect, delta: CGPoint, maxSize: CGSize) -> CGRect {
            var adjustedRect = cropRect
            if self.isTop {
                var delta = delta.y
                //Ensure we don't go below the minimum
                if (adjustedRect.size.height - delta) < Self.minimumSize {
                    delta = adjustedRect.size.height - Self.minimumSize
                }
                //Ensure we don't go below 0 (remember this is the crop rect so should never have a negative origin)
                if (adjustedRect.origin.y + delta) < 0 {
                    delta = -adjustedRect.origin.y
                }
                adjustedRect.origin.y += delta
                adjustedRect.size.height -= delta
            } else if self.isBottom {
                //The max height has to take into account the top left corner may be shifted from (0,0)
                let maxHeight = maxSize.height - cropRect.origin.y
                adjustedRect.size.height = min(max(adjustedRect.size.height + delta.y, Self.minimumSize), maxHeight)
            }

            if self.isLeft {
                var delta = delta.x
                if (adjustedRect.size.width - delta) < Self.minimumSize {
                    delta = adjustedRect.size.width - Self.minimumSize
                }
                if (adjustedRect.origin.x + delta) < 0 {
                    delta = -adjustedRect.origin.x
                }
                adjustedRect.origin.x += delta
                adjustedRect.size.width -= delta
            } else if self.isRight {
                let maxWidth = maxSize.width - cropRect.origin.x
                adjustedRect.size.width = min(max(adjustedRect.size.width + delta.x, Self.minimumSize), maxWidth)
            }

            return adjustedRect
        }
    }
}
