//
//  ImageEditorPolygonHotspot.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class ImageEditorPolygonHotspot: ImageEditorHotspot {
    private(set) var points: [CGPoint]
    var url: URL? = nil
    private(set) var mode: ImageEditorHotspotMode
    let imageSize: CGSize
    var originOffset: CGPoint = .zero
    init(points: [CGPoint], url: URL? = nil, mode: ImageEditorHotspotMode = .complete, imageSize: CGSize) {
        self.points = points
        self.url = url
        self.mode = mode
        self.imageSize = imageSize
    }

    var isEditable: Bool {
        return self.layoutEngine?.isEditable ?? false
    }

    private var effectivePoints: [CGPoint] {
        return self.points.map { $0.minus(self.originOffset) }
    }

    //MARK: - Paths
    func hotspotPath(forScale scale: CGFloat = 1) -> NSBezierPath {
        guard self.effectivePoints.count >= 1 else {
            return NSBezierPath()
        }
        let path = NSBezierPath()
        path.move(to: self.effectivePoints[0].multiplied(by: scale))

        (1..<self.effectivePoints.count).forEach {
            path.line(to: self.effectivePoints[$0].multiplied(by: scale))
        }
        if self.mode == .complete {
            path.close()
        }
        return path
    }

    func editingBoundsPaths(forScale scale: CGFloat = 1) -> [(path: NSBezierPath, phase: CGFloat)] {
        guard self.isEditable else {
            return []
        }

        var paths: [(path: NSBezierPath, phase: CGFloat)] = (1..<self.effectivePoints.count).map {
            return (NSBezierPath(lineFrom: self.effectivePoints[$0 - 1], to: self.effectivePoints[$0]), 0)
        }
        paths.append((NSBezierPath(lineFrom: self.effectivePoints[self.effectivePoints.count - 1], to: self.effectivePoints[0]), 0))
        return paths
    }

    //MARK: - Handle Rects
    func editingHandleRects(forScale scale: CGFloat = 1) -> [CGRect] {
        guard self.isEditable else {
            return []
        }
        var handleRects = [CGRect]()
        for point in self.effectivePoints {
            let scaledPoint = point.multiplied(by: scale)
            let size = CGSize(width: self.resizeHandleSize, height: self.resizeHandleSize)
            let offsetPoint = scaledPoint.minus(x: self.resizeHandleSize / 2, y: self.resizeHandleSize / 2)
            handleRects.append(CGRect(origin: offsetPoint, size: size))
        }
        return handleRects
    }


    //MARK: - State
    var isSelected: Bool = false
    var isHovered: Bool = false
    var isHighlighted: Bool = false
    private(set) var isClicked: Bool = false

    var imageHotspot: ImageHotspot? {
        switch self.mode {
        case .creating:
            return nil
        case .complete:
            return ImageHotspot(kind: .polygon, points: self.points, link: self.url)
        }
    }

    weak var layoutEngine: ImageEditorHotspotLayoutEngine?


	//MARK: - Hit Testing
    func hitTest(at point: CGPoint) -> Bool {
        if self.isEditable {
            for handle in self.editingHandleRects() {
                if handle.contains(point) {
                    return true
                }
            }
        }
        return self.hotspotPath().contains(point)
    }


    //MARK: - Events
    private struct DragState {
        var downPoint: CGPoint
        var initialPoints: [CGPoint]
        var dragHandle: ImageEditorPolygonHotspot.DragHandle
    }

    private var currentDragState: DragState?

    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.isClicked = (self.isEditable == false)
        guard
            self.currentDragState == nil,
            let dragHandle = self.dragHandle(at: point)
        else {
            return
        }

        let dragState = DragState(downPoint: point, initialPoints: self.points, dragHandle: dragHandle)
        self.currentDragState = dragState
        if case .new = dragHandle {
            self.addNewHandle(dragState: dragState, point: point, modifiers: modifiers, canComplete: true, eventCount: eventCount)
        }
    }

    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.isClicked = self.hotspotPath().contains(point) && (self.isEditable == false)
        guard let dragState = self.currentDragState else {
            return
        }

        let delta = point.minus(dragState.downPoint)
        switch dragState.dragHandle {
        case .new:
            self.addNewHandle(dragState: dragState, point: point, modifiers: modifiers, eventCount: eventCount)
        case .move:
            self.moveHotspot(dragState: dragState, delta: delta, modifiers: modifiers)
        case .resizeHandle(let index):
            self.moveHandle(at: index, dragState: dragState, delta: delta, modifiers: modifiers)
        }
    }

    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) -> Bool {
        self.isClicked = false
        guard let dragState = self.currentDragState else {
            return false
        }

        let delta = point.minus(dragState.downPoint)

        if case .move = dragState.dragHandle {
            self.selectHotspot(dragState: dragState, delta: delta, modifiers: modifiers)
        }

        self.currentDragState = nil
        return self.mode == .complete
    }

    func movedEvent(at point: CGPoint) {
        //Implement
    }

    func accessibilityMoveHandle(atIndex index: Int, byDelta delta: CGPoint) -> CGPoint {
        let handleRects = self.editingHandleRects()
        guard let handleRect = handleRects[safe: index] else {
            return .zero
        }
        let dragState = DragState(downPoint: handleRect.midPoint, initialPoints: self.points, dragHandle: .resizeHandle(index))
        return self.moveHandle(at: index, dragState: dragState, delta: delta, modifiers: [])
    }

    //MARK: - Handle Helpers
    private func dragHandle(at point: CGPoint) -> DragHandle? {
        switch self.mode {
        case .creating:
            return .new
        case .complete:
            if self.isEditable {
                for (index, rect) in self.editingHandleRects(forScale: 1).enumerated() {
                    if rect.contains(point) {
                        return .resizeHandle(index)
                    }
                }
            }
            if self.hotspotPath().contains(point) {
                return .move
            }
            return nil
        }
    }

    private func addNewHandle(dragState: DragState, point: CGPoint, modifiers: LayoutEventModifiers, canComplete: Bool = false, eventCount: Int) {
        guard self.mode == .creating else {
            return
        }

        var newPoints = dragState.initialPoints
        let boundedPoint = point.bounded(within: CGRect(origin: .zero, size: self.imageSize))
        if canComplete, self.points.count > 2, let firstHandle = self.editingHandleRects().first, firstHandle.contains(point) {
            self.completeCreation()
        } else if eventCount == 2 {
            self.completeCreation()
        } else if newPoints.contains(boundedPoint) == false {
            newPoints.append(boundedPoint)
            self.points = newPoints
        }
    }

    private func completeCreation() {
        self.mode = .complete
    }

    private func selectHotspot(dragState: DragState, delta: CGPoint, modifiers: LayoutEventModifiers) {
        guard abs(delta.x) < 0.5, abs(delta.y) < 0.5, self.mode != .creating else {
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

    @discardableResult private func moveHandle(at index: Int, dragState: DragState, delta: CGPoint, modifiers: LayoutEventModifiers) -> CGPoint {
        guard self.isEditable, let pointToMove = dragState.initialPoints[safe: index] else {
            return .zero
        }

        let newPoint = pointToMove.plus(delta).bounded(within: CGRect(origin: .zero, size: self.imageSize))

        var newPoints = dragState.initialPoints
        newPoints[index] = newPoint
        self.points = newPoints
        return newPoint.minus(pointToMove)
    }

    private func moveHotspot(dragState: DragState, delta: CGPoint, modifiers: LayoutEventModifiers) {
        guard self.isEditable, self.mode == .complete else {
            return
        }

        var newPoints = dragState.initialPoints.map { $0.plus(delta) }

        let minX = newPoints.minX
        if minX < 0 {
            newPoints = newPoints.map { $0.minus(x: minX, y: 0) }
        }

        let minY = newPoints.minY
        if minY < 0 {
            newPoints = newPoints.map { $0.minus(x: 0, y: minY) }
        }

        let maxX = newPoints.maxX
        if maxX > self.imageSize.width {
            newPoints = newPoints.map { $0.minus(x: maxX - self.imageSize.width, y: 0) }
        }

        let maxY = newPoints.maxY
        if maxY > self.imageSize.height {
            newPoints = newPoints.map { $0.minus(x: 0, y: maxY - self.imageSize.height) }
        }

        self.points = newPoints
    }
}

extension ImageEditorPolygonHotspot {
    enum DragHandle {
        case new
        case resizeHandle(Int)
        case move
    }
}

extension Array where Element == CGPoint {
    var minX: CGFloat {
        return self.map(\.x).min() ?? 0
    }

    var maxX: CGFloat {
        return self.map(\.x).max() ?? 0
    }

    var minY: CGFloat {
        return self.map(\.y).min() ?? 0
    }

    var maxY: CGFloat {
        return self.map(\.y).max() ?? 0
    }
}
