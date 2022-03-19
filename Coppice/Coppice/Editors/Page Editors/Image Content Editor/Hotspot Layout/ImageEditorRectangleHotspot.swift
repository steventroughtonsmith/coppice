//
//  ImageEditorRectangleHotspot.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/02/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class ImageEditorRectangleHotspot: ImageEditorHotspot {
    enum Shape {
        case rectangle
        case oval
    }

    let shape: Shape
    private(set) var rect: CGRect
    var url: URL? = nil
    private(set) var mode: ImageEditorHotspotMode
    let imageSize: CGSize
    init(shape: Shape, rect: CGRect, url: URL? = nil, mode: ImageEditorHotspotMode = .complete, imageSize: CGSize) {
        self.shape = shape
        self.rect = rect
        self.url = url
        self.mode = mode
        self.imageSize = imageSize
    }

    func hotspotPath(forScale scale: CGFloat = 1) -> NSBezierPath {
        switch self.shape {
        case .oval:
            return NSBezierPath(ovalIn: self.rect.multiplied(by: scale))
        case .rectangle:
            return NSBezierPath(rect: self.rect.multiplied(by: scale))
        }
    }

    var isEditable: Bool {
        return self.layoutEngine?.isEditable ?? false
    }

    func editingBoundsPaths(forScale scale: CGFloat) -> [(path: NSBezierPath, phase: CGFloat)] {
        guard self.isEditable else {
            return []
        }

        var paths = [(path: NSBezierPath, phase: CGFloat)]()
        let editingHandles = self.editingHandleRectsByDragKind(forScale: scale).indexed(by: \.handle)

        func addPath(from handle1: DragHandle, to handle2: DragHandle, phase: CGFloat = 0) {
            let path = NSBezierPath(lineFrom: editingHandles[handle1]!.frame.midPoint, to: editingHandles[handle2]!.frame.midPoint)
            paths.append((path, phase))
        }

        if self.currentDragState?.handle.isBottom == true {
            //We calculate the phase to stop the lines shifting as we move
            let phase = 8 - self.rect.height.truncatingRemainder(dividingBy: 8)
            addPath(from: .resizeTopLeft, to: .resizeBottomLeft, phase: phase)
            addPath(from: .resizeTopRight, to: .resizeBottomRight, phase: phase)
        } else { //If top or move or not dragging then fall back to this
            //The phase is locked to 4 rather than 0 so we don't invert the colours
            addPath(from: .resizeBottomLeft, to: .resizeTopLeft, phase: 4)
            addPath(from: .resizeBottomRight, to: .resizeTopRight, phase: 4)
        }

        if self.currentDragState?.handle.isRight == true {
            let phase = 8 - self.rect.width.truncatingRemainder(dividingBy: 8)
            addPath(from: .resizeTopLeft, to: .resizeTopRight, phase: phase)
            addPath(from: .resizeBottomLeft, to: .resizeBottomRight, phase: phase)
        } else { //If left or move or not dragging then fall back to this
            addPath(from: .resizeTopRight, to: .resizeTopLeft, phase: 4)
            addPath(from: .resizeBottomRight, to: .resizeBottomLeft, phase: 4)
        }

        return paths
    }

    //MARK: - Handle Rects
    func editingHandleRects(forScale scale: CGFloat = 1) -> [CGRect] {
        switch self.mode {
        case .creating:
            return []
        case .complete:
            guard self.isEditable else {
                return []
            }
            return self.editingHandleRectsByDragKind(forScale: scale).sorted { $0.handle.drawingOrder < $1.handle.drawingOrder }.map(\.frame)
        }
    }

    private func editingHandleRectsByDragKind(forScale scale: CGFloat) -> [(handle: DragHandle, frame: CGRect)] {
        let size = self.resizeHandleSize
        let scaledRect = self.rect.multiplied(by: scale)
        return [
            (.resizeBottomRight,  CGRect(x: scaledRect.maxX - (size / 2), y: scaledRect.maxY - (size / 2), width: size, height: size)),
            (.resizeTopRight, CGRect(x: scaledRect.maxX - (size / 2), y: scaledRect.minY - (size / 2), width: size, height: size)),
            (.resizeBottomLeft, CGRect(x: scaledRect.minX - (size / 2), y: scaledRect.maxY - (size / 2), width: size, height: size)),
            (.resizeTopLeft, CGRect(x: scaledRect.minX - (size / 2), y: scaledRect.minY - (size / 2), width: size, height: size)),
        ]
    }

    var isSelected: Bool = false
    var isHighlighted: Bool = false
    private(set) var isClicked: Bool = false

    var imageHotspot: ImageHotspot? {
        switch self.mode {
        case .creating:
            return nil
        case .complete:
            let points = [
                self.rect.point(atX: .min, y: .min),
                self.rect.point(atX: .max, y: .min),
                self.rect.point(atX: .max, y: .max),
                self.rect.point(atX: .min, y: .max),
            ]
            switch self.shape {
            case .rectangle:
                return ImageHotspot(kind: .rectangle, points: points, link: self.url)
            case .oval:
                return ImageHotspot(kind: .oval, points: points, link: self.url)
            }
        }
    }

    weak var layoutEngine: ImageEditorHotspotLayoutEngine?

    func hitTest(at point: CGPoint) -> Bool {
        guard self.isEditable else {
            return self.hotspotPath().contains(point)
        }
        let editingBoundsPath = NSBezierPath(rect: self.rect)
        self.editingHandleRects().forEach { editingBoundsPath.appendRect($0) }
        return editingBoundsPath.contains(point)
    }


    //MARK: - Events
    private struct DragState {
        var initialPoint: CGPoint
        var initialRect: CGRect
        var handle: DragHandle
    }

    private var currentDragState: DragState?
    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.isClicked = (self.isEditable == false)
        guard
            self.currentDragState == nil,
            let handle = self.dragHandle(at: point)
        else {
            return
        }

        self.currentDragState = DragState(initialPoint: point, initialRect: self.rect, handle: handle)
    }

    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.isClicked = self.rect.contains(point) && (self.isEditable == false)
        guard let dragState = self.currentDragState else {
            return
        }

        let delta = point.minus(dragState.initialPoint)

        switch dragState.handle {
        case .move:
            self.moveHotspot(dragState: dragState, delta: delta)
        case .resizeTopLeft, .resizeBottomRight, .resizeBottomLeft, .resizeTopRight:
            self.resizeHotspot(dragState: dragState, delta: delta, modifier: modifiers)
        }
    }

    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) -> Bool {
        self.isClicked = false
        guard let dragState = self.currentDragState else {
            return false
        }

        let delta = point.minus(dragState.initialPoint)

        switch dragState.handle {
        case .move:
            self.selectHotspot(dragState: dragState, delta: delta, modifiers: modifiers)
        case .resizeTopLeft, .resizeBottomRight, .resizeBottomLeft, .resizeTopRight:
            if self.mode == .creating {
                self.finishCreation(dragState: dragState, delta: delta, modifiers: modifiers)
            }
        }
        let rectHasChanged = (dragState.initialRect != self.rect)

        self.currentDragState = nil

        return rectHasChanged
    }

    func movedEvent(at point: CGPoint) {
        //TODO: implement
    }


    //MARK: - Handle Helpers
    private func dragHandle(at point: CGPoint) -> DragHandle? {
        switch self.mode {
        case .creating:
            return .resizeBottomRight
        case .complete:
            if self.isEditable {
                for (kind, rect) in self.editingHandleRectsByDragKind(forScale: 1) {
                    if rect.contains(point) {
                        return kind
                    }
                }
            }
            if self.rect.contains(point) {
                return .move
            }
            return nil
        }
    }

    private func moveHotspot(dragState: DragState, delta: CGPoint) {
        guard self.mode == .complete, self.isEditable else {
            return
        }

        var dx = delta.x
        if (dragState.initialRect.minX + dx) < 0 {
            dx = -dragState.initialRect.minX
        } else if (dragState.initialRect.maxX + dx) > self.imageSize.width {
            dx = self.imageSize.width - dragState.initialRect.maxX
        }

        var dy = delta.y
        if (dragState.initialRect.minY + dy) < 0 {
            dy = -dragState.initialRect.minY
        } else if (dragState.initialRect.maxY + dy) > self.imageSize.height {
            dy = self.imageSize.height - dragState.initialRect.maxY
        }
        self.rect = dragState.initialRect.offsetBy(dx: dx, dy: dy)
    }

    private func resizeHotspot(dragState: DragState, delta: CGPoint, modifier: LayoutEventModifiers) {
        var adjustedRect = dragState.initialRect

        enum Direction {
            case horizontal
            case vertical

            var sizeKeyPath: WritableKeyPath<CGSize, CGFloat> {
                switch self {
                case .horizontal:
                    return \CGSize.width
                case .vertical:
                    return \CGSize.height
                }
            }

            var originKeyPath: WritableKeyPath<CGPoint, CGFloat> {
                switch self {
                case .horizontal:
                    return \CGPoint.x
                case .vertical:
                    return \CGPoint.y
                }
            }
        }

        func adjust(rect: CGRect, offsetFromOrigin: CGFloat, direction: Direction) -> CGRect {
            guard delta[keyPath: direction.originKeyPath] != 0 else {
                return rect
            }

            var adjustedRect = rect
            //Work out the origin to use for the drag (will be either opposite the handle or half way down the rect)
            let dragOrigin = modifier.contains(.option) ? (rect.size[keyPath: direction.sizeKeyPath] / 2) : offsetFromOrigin
            //Work out how far from the origin the current point is
            let initialOffsetFromDragOrigin = (rect.size[keyPath: direction.sizeKeyPath] - offsetFromOrigin) - dragOrigin
            //Add our delta
            let newOffsetFromDragOrigin = initialOffsetFromDragOrigin + delta[keyPath: direction.originKeyPath]

            let newOrigin: CGFloat
            var newSize: CGFloat
            if modifier.contains(.option) {
                newOrigin = -abs(newOffsetFromDragOrigin)
                newSize = 2 * abs(newOffsetFromDragOrigin)
            } else {
                newOrigin = (newOffsetFromDragOrigin < 0) ? newOffsetFromDragOrigin : 0
                newSize = abs(newOffsetFromDragOrigin)
            }

            var rectOriginAdjustment = newOrigin + dragOrigin

            if modifier.contains(.option) {
                let currentMidPoint = adjustedRect.midPoint[keyPath: direction.originKeyPath]
                let proposedMin = currentMidPoint - (newSize / 2)
                if proposedMin < 0 {
                    newSize += proposedMin * 2
                    rectOriginAdjustment -= proposedMin
                }
                //Checking bottom/right edge
                let proposedMax = currentMidPoint + (newSize / 2)
                if proposedMax > self.imageSize[keyPath: direction.sizeKeyPath] {
                    let adjustment = proposedMax - self.imageSize[keyPath: direction.sizeKeyPath]
                    newSize -= adjustment * 2
                    rectOriginAdjustment += adjustment
                }
            } else {
                let currentOrigin = adjustedRect.origin[keyPath: direction.originKeyPath]
                let proposedMin = currentOrigin + rectOriginAdjustment
                if proposedMin < 0 {
                    rectOriginAdjustment = -currentOrigin
                    newSize = currentOrigin + offsetFromOrigin
                }

                let proposedMax = currentOrigin + rectOriginAdjustment + newSize
                if proposedMax > self.imageSize[keyPath: direction.sizeKeyPath] {
                    newSize = self.imageSize[keyPath: direction.sizeKeyPath] - currentOrigin - rectOriginAdjustment
                }
            }

            adjustedRect.origin[keyPath: direction.originKeyPath] += rectOriginAdjustment
            adjustedRect.size[keyPath: direction.sizeKeyPath] = abs(newSize)
            return adjustedRect
        }

        if dragState.handle.isTop {
            adjustedRect = adjust(rect: adjustedRect, offsetFromOrigin: dragState.initialRect.height, direction: .vertical)
        } else if dragState.handle.isBottom {
            adjustedRect = adjust(rect: adjustedRect, offsetFromOrigin: 0, direction: .vertical)
        }

        if dragState.handle.isLeft {
            adjustedRect = adjust(rect: adjustedRect, offsetFromOrigin: dragState.initialRect.width, direction: .horizontal)
        } else if dragState.handle.isRight {
            adjustedRect = adjust(rect: adjustedRect, offsetFromOrigin: 0, direction: .horizontal)
        }

        self.rect = adjustedRect
    }

    private func selectHotspot(dragState: DragState, delta: CGPoint, modifiers: LayoutEventModifiers) {
        guard delta == .zero else {
            return
        }

        //Only allow selection in edit mode or with option held
        guard self.isEditable || modifiers.contains(.option) else {
            return
        }

        if modifiers.contains(.shift) {
            self.isSelected.toggle()
        } else {
            self.layoutEngine?.deselectAll()
            self.isSelected = true
        }
    }

    private func finishCreation(dragState: DragState, delta: CGPoint, modifiers: LayoutEventModifiers) {
        self.mode = .complete
    }
}

extension ImageEditorRectangleHotspot {
    enum DragHandle {
        case resizeTopLeft
        case resizeTopRight
        case resizeBottomLeft
        case resizeBottomRight
        case move

        var isTop: Bool {
            switch self {
            case .resizeTopLeft, .resizeTopRight:
                return true
            case .resizeBottomLeft, .resizeBottomRight, .move:
                return false
            }
        }

        var isBottom: Bool {
            switch self {
            case .resizeBottomLeft, .resizeBottomRight:
                return true
            case .resizeTopLeft, .resizeTopRight, .move:
                return false
            }
        }

        var isLeft: Bool {
            switch self {
            case .resizeTopLeft, .resizeBottomLeft:
                return true
            case .resizeTopRight, .resizeBottomRight, .move:
                return false
            }
        }

        var isRight: Bool {
            switch self {
            case .resizeTopRight, .resizeBottomRight:
                return true
            case .resizeTopLeft, .resizeBottomLeft, .move:
                return false
            }
        }

        var drawingOrder: Int {
            switch self {
            case .resizeTopLeft:
                return 1
            case .resizeTopRight:
                return 2
            case .resizeBottomRight:
                return 3
            case .resizeBottomLeft:
                return 4
            case .move:
                return 0
            }
        }
    }
}
