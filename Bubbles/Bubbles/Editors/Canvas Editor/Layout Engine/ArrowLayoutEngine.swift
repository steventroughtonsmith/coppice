//
//  ArrowLayoutEngine.swift
//  Bubbles
//
//  Created by Martin Pilkington on 14/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

class ArrowLayoutEngine {
    let pages: [LayoutEnginePage]
    init(pages: [LayoutEnginePage]) {
        self.pages = pages
    }

    func calculateArrows() -> [Arrow] {
        var arrows = [Arrow]()
        for page in pages {
            guard page.parent == nil else {
                continue
            }
            let (_, pageArrows) = self.calculateArrows(from: page)
            arrows.append(contentsOf: pageArrows)
        }
        return arrows
    }

    private func calculateArrows(from page: LayoutEnginePage, edgeFromParent: LayoutEnginePage.Edge? = nil) -> (ArrowPoint?, [Arrow]) {
        var pagePoint: ArrowPoint? = nil
        if let parentEdge = edgeFromParent {
            let point = self.location(for: parentEdge.opposite, of: page)
            pagePoint = ArrowPoint(point: point, edge: parentEdge.opposite)
        }
        guard page.children.count > 0 else {
            return (pagePoint, [])
        }

        var arrows = [Arrow]()
        for edge in LayoutEnginePage.Edge.allCases {
            var pointsToProcess = [ArrowPoint]()
            for child in page.children(for: edge) {
                let (point, pageArrows) = self.calculateArrows(from: child, edgeFromParent: edge)
                if let point = point {
                    pointsToProcess.append(point)
                }
                arrows.append(contentsOf: pageArrows)
            }

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
        //for direction in directions
            //for child in direction
                //(point, arrows) = calculateArrows(for: child, directionFromParent: direction)
                //points += point
                //arrows += arrows

            //(parent, arrows) = processPoints(points, (parentPoint.direction == direction) ? parentPoint : nil)
            //if parent then parentPoint = parent
            //arrows += arrows
        //return (parentPoint, arrows)

        return (pagePoint, arrows)
    }

    private func process(_ points: [ArrowPoint], for edge: LayoutEnginePage.Edge, of page: LayoutEnginePage, parent: ArrowPoint? = nil) -> (ArrowPoint?, [Arrow]) {
        switch edge {
        case .top, .bottom:
            return self.processHorizontalPoints(points, forEdge: edge, of: page, parent: parent)
        case .left, .right:
            return self.processVerticalPoints(points, forEdge: edge, of: page, parent: parent)
        }

        //count = points.count
        //if parent set then count += 1
        //sort points
        //sectionSize = page.size / count
        //for point
            //if point == parent
                //parent = sectionSize * (i + 0.5)
            //else
                //endPoint = sectionSize * (i + 0.5)
                //arrow += Arrow(startPoint: point, endPoint: endPoint)
    }

    private func processHorizontalPoints(_ points: [ArrowPoint], forEdge edge: LayoutEnginePage.Edge, of page: LayoutEnginePage, parent: ArrowPoint?) -> (ArrowPoint?, [Arrow]) {
        var pointsToProcess = points
        if let parent = parent {
            pointsToProcess.append(parent)
        }
        let sortedPoints = pointsToProcess.sorted { $0.point.x < $1.point.x }
        let sectionSize = page.layoutFrame.width / CGFloat(sortedPoints.count)
        let y = (edge == .top) ? page.layoutFrame.minY : page.layoutFrame.maxY

        var arrows = [Arrow]()
        var parentPoint = parent
        (0..<sortedPoints.count).forEach {
            let point = sortedPoints[$0]
            let x = sectionSize * (CGFloat($0) + 0.5) + page.layoutFrame.minX
            if point == parentPoint {
                parentPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge)
            } else {
                let startPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge.opposite)
                arrows.append(Arrow(startPoint: startPoint, endPoint: point))
            }
        }

        return (parentPoint, arrows)
    }

    private func processVerticalPoints(_ points: [ArrowPoint], forEdge edge: LayoutEnginePage.Edge, of page: LayoutEnginePage, parent: ArrowPoint?) -> (ArrowPoint?, [Arrow]) {
        var pointsToProcess = points
        if let parent = parent {
            pointsToProcess.append(parent)
        }
        let sortedPoints = pointsToProcess.sorted { $0.point.y < $1.point.y }
        let sectionSize = page.layoutFrame.height / CGFloat(sortedPoints.count)
        let x = (edge == .left) ? page.layoutFrame.minX : page.layoutFrame.maxX

        var arrows = [Arrow]()
        var parentPoint = parent
        (0..<sortedPoints.count).forEach {
            let point = sortedPoints[$0]
            let y = (sectionSize * (CGFloat($0) + 0.5)) + page.layoutFrame.minY
            if point == parentPoint {
                parentPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge)
            } else {
                let startPoint = ArrowPoint(point: CGPoint(x: x, y: y).rounded(), edge: point.edge.opposite)
                arrows.append(Arrow(startPoint: startPoint, endPoint: point))
            }
        }

        return (parentPoint, arrows)
    }

    private func location(for edge: LayoutEnginePage.Edge, of page: LayoutEnginePage) -> CGPoint {
        switch edge {
        case .left:
            return page.layoutFrame.point(atX: .min, y: .mid).rounded()
        case .right:
            return page.layoutFrame.point(atX: .max, y: .mid).rounded()
        case .top:
            return page.layoutFrame.point(atX: .mid, y: .min).rounded()
        case .bottom:
            return page.layoutFrame.point(atX: .mid, y: .max).rounded()
        }
    }
}

struct ArrowPoint: Equatable {
    let point: CGPoint
    let edge: LayoutEnginePage.Edge
}

struct Arrow: Equatable {
    let startPoint: ArrowPoint
    let endPoint: ArrowPoint
}
