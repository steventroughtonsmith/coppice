//
//  ArrowLayoutEngine.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

class ArrowLayoutEngine {
    let pages: [LayoutEnginePage]
    weak var layoutEngine: CanvasLayoutEngine?
    init(pages: [LayoutEnginePage], layoutEngine: CanvasLayoutEngine? = nil) {
        self.pages = pages
        self.layoutEngine = layoutEngine
    }

    func calculateArrows() -> [LayoutEngineArrow] {
        var arrows = [LayoutEngineArrow]()
        for page in pages {
            guard page.parent == nil else {
                continue
            }
            let (_, pageArrows) = self.calculateArrows(for: page)
            arrows.append(contentsOf: pageArrows)
        }
        return arrows
    }

    private func calculateArrows(for page: LayoutEnginePage, edgeFromParent: LayoutEnginePage.Edge? = nil) -> (ArrowPoint?, [LayoutEngineArrow]) {
        var pagePoint: ArrowPoint? = nil
        //If the edge from the parent is set then we want to create an arrow for ourselves that will point back to the parent
        if let parentEdge = edgeFromParent {
            let point = self.location(for: parentEdge.opposite, of: page)
            pagePoint = ArrowPoint(point: point, edge: parentEdge.opposite, pageID: page.id)
        }
        //We can exit early if we're a leaf of the tree
        guard page.children.count > 0 else {
            return (pagePoint, [])
        }

        var arrows = [LayoutEngineArrow]()
        //For each edge we want to get all arrows so we can calculate their start points
        for edge in LayoutEnginePage.Edge.allCases {
            var pointsToProcess = [ArrowPoint]()
            for child in page.children(for: edge) {
                let (point, pageArrows) = self.calculateArrows(for: child, edgeFromParent: edge)
                if let point = point {
                    pointsToProcess.append(point)
                }
                arrows.append(contentsOf: pageArrows)
            }

            //If the parent is on this edge then we need to include it in the calculation, in case there are children on the same edge
            let includeParent = (pagePoint?.edge == edge)
            guard (pointsToProcess.count > 0) || includeParent else {
                continue
            }

            let (parentPoint, processedArrows) = self.process(pointsToProcess, for: edge, of: page, parent: (includeParent ? pagePoint : nil))
            if let point = parentPoint {
                pagePoint = point
            }
            arrows.append(contentsOf: processedArrows)
        }
        return (pagePoint, arrows)
    }

    private func process(_ points: [ArrowPoint], for edge: LayoutEnginePage.Edge, of page: LayoutEnginePage, parent: ArrowPoint? = nil) -> (ArrowPoint?, [LayoutEngineArrow]) {
        switch edge {
        case .top, .bottom:
            return self.processHorizontalPoints(points, forEdge: edge, of: page, parent: parent)
        case .left, .right:
            return self.processVerticalPoints(points, forEdge: edge, of: page, parent: parent)
        }
    }

    private func processHorizontalPoints(_ points: [ArrowPoint], forEdge edge: LayoutEnginePage.Edge, of page: LayoutEnginePage, parent: ArrowPoint?) -> (ArrowPoint?, [LayoutEngineArrow]) {
        var pointsToProcess = points
        if let parent = parent {
            pointsToProcess.append(parent)
        }
        //We want to sort points left to right and place them equally
        let sortedPoints = pointsToProcess.sorted { $0.point.x < $1.point.x }
        let sectionSize = page.frameForArrows.width / CGFloat(sortedPoints.count)
        let y = (edge == .top) ? page.frameForArrows.minY : page.frameForArrows.maxY

        var arrows = [LayoutEngineArrow]()
        var parentPoint = parent
        (0..<sortedPoints.count).forEach {
            let point = sortedPoints[$0]
            let x = sectionSize * (CGFloat($0) + 0.5) + page.frameForArrows.minX
            if point == parentPoint {
                //The parent point is just going to be the *end* point of the arrow from the parent that will be passed back up to the parent
                //We need to change this to account for any children on the same side
                parentPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge, pageID: point.pageID)
            } else {
                //For children we want to create the start point based on the end point we were given
                let startPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge.opposite, pageID: page.id)
                arrows.append(LayoutEngineArrow(startPoint: startPoint, endPoint: point, layoutEngine: self.layoutEngine))
            }
        }

        return (parentPoint, arrows)
    }

    private func processVerticalPoints(_ points: [ArrowPoint], forEdge edge: LayoutEnginePage.Edge, of page: LayoutEnginePage, parent: ArrowPoint?) -> (ArrowPoint?, [LayoutEngineArrow]) {
        var pointsToProcess = points
        if let parent = parent {
            pointsToProcess.append(parent)
        }
        //We want to sort points left to right and place them equally
        let sortedPoints = pointsToProcess.sorted { $0.point.y < $1.point.y }
        let sectionSize = page.frameForArrows.height / CGFloat(sortedPoints.count)
        let x = (edge == .left) ? page.frameForArrows.minX : page.frameForArrows.maxX

        var arrows = [LayoutEngineArrow]()
        var parentPoint = parent
        (0..<sortedPoints.count).forEach {
            let point = sortedPoints[$0]
            let y = (sectionSize * (CGFloat($0) + 0.5)) + page.frameForArrows.minY
            if point == parentPoint {
                //The parent point is just going to be the *end* point of the arrow from the parent that will be passed back up to the parent
                //We need to change this to account for any children on the same side
                parentPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge, pageID: point.pageID)
            } else {
                //For children we want to create the start point based on the end point we were given
                let startPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge.opposite, pageID: page.id)
                arrows.append(LayoutEngineArrow(startPoint: startPoint, endPoint: point, layoutEngine: self.layoutEngine))
            }
        }

        return (parentPoint, arrows)
    }

    private func location(for edge: LayoutEnginePage.Edge, of page: LayoutEnginePage) -> CGPoint {
        switch edge {
        case .left:
            return page.frameForArrows.point(atX: .min, y: .mid).rounded()
        case .right:
            return page.frameForArrows.point(atX: .max, y: .mid).rounded()
        case .top:
            return page.frameForArrows.point(atX: .mid, y: .min).rounded()
        case .bottom:
            return page.frameForArrows.point(atX: .mid, y: .max).rounded()
        }
    }
}

