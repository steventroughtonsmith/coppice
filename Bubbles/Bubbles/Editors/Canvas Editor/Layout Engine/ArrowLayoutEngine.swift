//
//  ArrowLayoutEngine.swift
//  Bubbles
//
//  Created by Martin Pilkington on 14/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

class ArrowLayoutEngine {
    static func trees(from pages: [LayoutEnginePage]) -> [LayoutTree] {
        //create node for each page
        //create relationships
        //eliminate orphans
        //Return roots
        return []
    }

    let trees: [LayoutTree]
    init(trees: [LayoutTree]) {
        self.trees = trees
    }

    func calculateArrows() -> [Arrow] {

        return []
    }

    private func calculateArrows(for tree: LayoutTree, directionFromParent: Direction? = nil) -> (ArrowPoint?, [Arrow]) {
        //if direction != nil
            //Create Parent Point
        //for direction in directions
            //for child in direction
                //(point, arrows) = calculateArrows(for: child, directionFromParent: direction)
                //points += point
                //arrows += arrows

            //(parent, arrows) = processPoints(points, (parentPoint.direction == direction) ? parentPoint : nil)
            //if parent then parentPoint = parent
            //arrows += arrows
        //return (parentPoint, arrows)

        return (nil, [])
    }

    private func process(_ points: [ArrowPoint], for direction: Direction, of page: LayoutEnginePage, parent: ArrowPoint? = nil) -> (ArrowPoint?, [Arrow]) {
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
        
        return (nil, [])
    }


    enum Direction: CaseIterable {
        case left
        case top
        case right
        case bottom

        var opposite: Direction {
            switch self {
            case .left:
                return .right
            case .top:
                return .bottom
            case .right:
                return .left
            case .bottom:
                return .top
            }
        }
    }
}

struct ArrowPoint {
    let point: CGPoint
    let direction: ArrowLayoutEngine.Direction
}

class Arrow {
}

class LayoutTree: Equatable {
    static func == (lhs: LayoutTree, rhs: LayoutTree) -> Bool {
        return (lhs.parent == rhs.parent) &&
            (lhs.children == rhs.children) &&
            (lhs.frame == rhs.frame)
    }

    private(set) var parent: LayoutTree?

    let frame: CGRect
    init(frame: CGRect) {
        self.frame = frame
    }

    private var children: [ArrowLayoutEngine.Direction: [LayoutTree]] = [
        .left: [],
        .right: [],
        .top: [],
        .bottom: []
    ]

    func children(for direction: ArrowLayoutEngine.Direction) -> [LayoutTree] {
        return self.children[direction] ?? []
    }

    func addChild(_ child: LayoutTree) {
        child.parent = self

        let midPoint = child.frame.midPoint
        //Check if inside
        guard self.frame.contains(midPoint) == false else {
            self.children[(midPoint.x < self.frame.midX) ? .left : .right]?.append(child)
            return
        }

        //Check if directly to side
        if (midPoint.y >= self.frame.minY) && (midPoint.y <= self.frame.maxY) {
            if (midPoint.x > self.frame.maxX) {
                self.children[.right]?.append(child)
                return
            }
            self.children[.left]?.append(child)
            return
        }

        //Check if directly above or below
        if (midPoint.x >= self.frame.minX) && (midPoint.x <= self.frame.maxX) {
            if (midPoint.y > self.frame.maxY) {
                self.children[.bottom]?.append(child)
                return
            }
            self.children[.top]?.append(child)
            return
        }

        //Check Top Left
        if (midPoint.x < self.frame.minX) && (midPoint.y < self.frame.minY) {
            //y = x + (-p.x + p.y)
            let expectedY = midPoint.x + (-self.frame.minX + self.frame.minY)
            self.children[(expectedY <= midPoint.y) ? .left : .top]?.append(child)
            return
        }

        //Check Top Right
        if (midPoint.x > self.frame.minX) && (midPoint.y < self.frame.minY) {
            //y = -x + (p.x + p.y)
            let expectedY = -midPoint.x + (self.frame.maxX + self.frame.minY)
            self.children[(expectedY >= midPoint.y) ? .top : .right]?.append(child)
            return
        }

        //Check Bottom Right
        if (midPoint.x > self.frame.minX) && (midPoint.y > self.frame.maxY) {
            //y = x + (-p.x + p.y)
            let expectedY = midPoint.x + (-self.frame.maxX + self.frame.maxY)
            self.children[(expectedY >= midPoint.y) ? .right : .bottom]?.append(child)
            return
        }

        //Check Bottom Left
        if (midPoint.x < self.frame.minX) && (midPoint.y > self.frame.minY) {
            //y = x + (-p.x + p.y)
            let expectedY = -midPoint.x + (self.frame.minX + self.frame.maxY)
            self.children[(expectedY <= midPoint.y) ? .bottom : .left]?.append(child)
            return
        }

        //Direction
        //1. Check if inside
        //2. Check if directly to side
        //3. Check if at angle
    }


}
