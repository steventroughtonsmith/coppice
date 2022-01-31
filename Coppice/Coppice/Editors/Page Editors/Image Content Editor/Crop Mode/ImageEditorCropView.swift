//
//  ImageEditorCropView.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/01/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Cocoa

class ImageEditorCropView: NSView {
    override var isFlipped: Bool {
        return true
    }

    var cropRect: CGRect = .zero {
        didSet {
            self.setNeedsDisplay(self.bounds)
        }
    }

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

        self.cropRect = dragState.draggedHandle.adjustedCropRect(withInitialRect: dragState.initialCropRect, delta: delta)
    }

    override func mouseUp(with event: NSEvent) {
        self.dragState = nil
    }

    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        NSColor(white: 0, alpha: 0.5).set()
        let path = NSBezierPath(rect: self.bounds)
        let clipPath = NSBezierPath(rect: self.cropRect).reversed
        path.append(clipPath)

        path.fill()

        NSColor(white: 1, alpha: 0.2).set()
        NSBezierPath(rect: self.cropRect.insetBy(dx: 0.5, dy: 0.5)).stroke()

        for dragHandle in DragHandle.allCases {
            let path = dragHandle.path(for: self.cropRect)
            NSColor(white: 0, alpha: 0.8).set()
            path.lineWidth = DragHandle.handleDepth
            path.stroke()
            NSColor.white.set()
            path.lineWidth = DragHandle.handleDepth - 2
            path.stroke()
        }
    }

    private func dragHandle(at point: CGPoint) -> DragHandle? {
        for dragHandle in DragHandle.allCases {
            if dragHandle.interactionBound(for: self.cropRect).contains(point) {
                return dragHandle
            }
        }
        return nil
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

        private static let sideHandleLength: CGFloat = 32.0
        private static let cornerHandleLength: CGFloat = 20.0
        private static let interactionMargin: CGFloat = 2
        static let handleDepth: CGFloat = 8

        func path(for rect: CGRect) -> NSBezierPath {
            let bezierPath = NSBezierPath()
            switch self {
            case .top:
                bezierPath.move(to: CGPoint(x: rect.midX - (Self.sideHandleLength / 2), y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.midX + (Self.sideHandleLength / 2), y: rect.minY))
            case .bottom:
                bezierPath.move(to: CGPoint(x: rect.midX - (Self.sideHandleLength / 2), y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.midX + (Self.sideHandleLength / 2), y: rect.maxY))
            case .left:
                bezierPath.move(to: CGPoint(x: rect.minX, y: rect.midY - (Self.sideHandleLength / 2)))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.midY + (Self.sideHandleLength / 2)))
            case .right:
                bezierPath.move(to: CGPoint(x: rect.maxX, y: rect.midY - (Self.sideHandleLength / 2)))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.midY + (Self.sideHandleLength / 2)))
            case .topLeft:
                bezierPath.move(to: CGPoint(x: rect.minX, y: rect.minY + Self.cornerHandleLength))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.minX + Self.cornerHandleLength, y: rect.minY))
            case .topRight:
                bezierPath.move(to: CGPoint(x: rect.maxX - Self.cornerHandleLength, y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.minY))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.minY + Self.cornerHandleLength))
            case .bottomRight:
                bezierPath.move(to: CGPoint(x: rect.maxX, y: rect.maxY - Self.cornerHandleLength))
                bezierPath.line(to: CGPoint(x: rect.maxX, y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.maxX - Self.cornerHandleLength, y: rect.maxY))
            case .bottomLeft:
                bezierPath.move(to: CGPoint(x: rect.minX + Self.cornerHandleLength, y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.maxY))
                bezierPath.line(to: CGPoint(x: rect.minX, y: rect.maxY - Self.cornerHandleLength))
            }
            bezierPath.lineCapStyle = .round
            bezierPath.lineJoinStyle = .round
            return bezierPath
        }

        func interactionBound(for rect: CGRect) -> CGRect {
            let sideInteractionLength = Self.sideHandleLength + Self.handleDepth + (2 * Self.interactionMargin)
            let sideInteractionDepth = Self.handleDepth + (2 * Self.interactionMargin)
            let cornerSize = Self.cornerHandleLength + Self.handleDepth + (2 * Self.interactionMargin)
            let cornerOffset = Self.interactionMargin + (Self.handleDepth / 2)
            switch self {
            case .top:
                return CGRect(x: rect.midX - (sideInteractionLength / 2), y: rect.minY - (sideInteractionDepth / 2), width: sideInteractionLength, height: sideInteractionDepth)
            case .right:
                return CGRect(x: rect.maxX - (sideInteractionDepth / 2), y: rect.midY - (sideInteractionLength / 2), width: sideInteractionDepth, height: sideInteractionLength)
            case .bottom:
                return CGRect(x: rect.midX - (sideInteractionLength / 2), y: rect.maxY - (sideInteractionDepth / 2), width: sideInteractionLength, height: sideInteractionDepth)
            case .left:
                return CGRect(x: rect.minX - (sideInteractionDepth / 2), y: rect.midY - (sideInteractionLength / 2), width: sideInteractionDepth, height: sideInteractionLength)
            case .topLeft:
                return CGRect(x: rect.minX - cornerOffset, y: rect.minY - cornerOffset, width: cornerSize, height: cornerSize)
            case .topRight:
                return CGRect(x: rect.maxX - cornerOffset - Self.cornerHandleLength, y: rect.minY - cornerOffset, width: cornerSize, height: cornerSize)
            case .bottomRight:
                return CGRect(x: rect.maxX - cornerOffset - Self.cornerHandleLength, y: rect.maxY - cornerOffset - Self.cornerHandleLength, width: cornerSize, height: cornerSize)
            case .bottomLeft:
                return CGRect(x: rect.minX - cornerOffset, y: rect.maxY - cornerOffset - Self.cornerHandleLength, width: cornerSize, height: cornerSize)
            }
        }

        func adjustedCropRect(withInitialRect cropRect: CGRect, delta: CGPoint) -> CGRect {
            var adjustedRect = cropRect
            switch self {
            case .top:
                adjustedRect.origin.y += delta.y
                adjustedRect.size.height -= delta.y
            case .right:
                adjustedRect.size.width += delta.x
            case .bottom:
                adjustedRect.size.height += delta.y
            case .left:
                adjustedRect.origin.x += delta.x
                adjustedRect.size.width -= delta.x
            case .topLeft:
                adjustedRect.origin.x += delta.x
                adjustedRect.origin.y += delta.y
                adjustedRect.size.width -= delta.x
                adjustedRect.size.height -= delta.y
            case .topRight:
                adjustedRect.origin.y += delta.y
                adjustedRect.size.width += delta.x
                adjustedRect.size.height -= delta.y
            case .bottomRight:
                adjustedRect.size.width += delta.x
                adjustedRect.size.height += delta.y
            case .bottomLeft:
                adjustedRect.origin.x += delta.x
                adjustedRect.size.width -= delta.x
                adjustedRect.size.height += delta.y
            }
            return adjustedRect
        }
    }
}
