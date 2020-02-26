//
//  LayoutEnginePage.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

/// A class representing the layout information for a page inside the LayoutEngine
///
/// The main frame that is manipulated is the contentFrame, which is what is persisted.
/// Each Page view is expected to have the following hierarchy (and associated layout frames)
///
/// - Page View (`layoutFrame`): the view inside the canvas
///     - Visual Page (`visualPageFrame`): the page as drawn on screen
///     - Title Bar (`titleBarFrame`): The title bar for moving
///     - Content (`contentContainerFrame`): The actual page content
class LayoutEnginePage: Equatable {
    let id: UUID
    var selected: Bool = false
    var showBackground: Bool {
        if self.layoutEngine?.currentlyHoveredPage == self {
            return true
        }
        return self.selected
    }

    /// Enabled pages can be edited
    var enabled: Bool {
        return (self.layoutEngine?.enabledPage == self)
    }

    weak var layoutEngine: CanvasLayoutEngine? {
        didSet {
            self.recalculateEdgeFromParent()
        }
    }
    init(id: UUID,
         contentFrame: CGRect,
         minimumContentSize: CGSize = GlobalConstants.minimumPageSize) {
        self.id = id
        self.contentFrame = contentFrame
        self.minimumContentSize = minimumContentSize
        self.validateSize()
    }

    //MARK: - Content
    var minimumContentSize: CGSize

    /// The frame of the page's content in pageSpace
    var contentFrame: CGRect {
        didSet {
            self.validateSize()
            self.recalculateEdgeFromParent()
            self.children.forEach { $0.recalculateEdgeFromParent() }
        }
    }


    //MARK: - Relationships
    private(set) weak var parent: LayoutEnginePage? {
        didSet {
            self.recalculateEdgeFromParent()
        }
    }
    private(set) var edgeFromParent: Edge?

    private(set) var children = [LayoutEnginePage]()

    var allDescendants: [LayoutEnginePage] {
        var pages = [LayoutEnginePage]()
        for child in self.children {
            pages.append(child)
            pages.append(contentsOf: child.allDescendants)
        }
        return pages
    }

    func children(for edge: Edge) -> [LayoutEnginePage] {
        return self.children.filter { $0.edgeFromParent == edge }
    }

    func addChild(_ child: LayoutEnginePage) {
        self.children.append(child)
        child.parent = self
    }

    private func recalculateEdgeFromParent() {
        guard let parentFrame = self.parent?.layoutFrame else {
            self.edgeFromParent = nil
            return
        }

        let midPoint = self.layoutFrame.midPoint
        //Check if inside
        guard parentFrame.contains(midPoint) == false else {
            self.edgeFromParent = (midPoint.x < parentFrame.midX) ? .left : .right
            return
        }

        //Check if directly to side
        if (midPoint.y >= parentFrame.minY) && (midPoint.y <= parentFrame.maxY) {
            self.edgeFromParent = (midPoint.x > parentFrame.maxX) ? .right : .left
            return
        }

        //Check if directly above or below
        if (midPoint.x >= parentFrame.minX) && (midPoint.x <= parentFrame.maxX) {
            self.edgeFromParent = (midPoint.y > parentFrame.maxY) ? .bottom : .top
            return
        }

        //Check Top Left
        if (midPoint.x < parentFrame.minX) && (midPoint.y < parentFrame.minY) {
            //y = x + (-p.x + p.y)
            let expectedY = midPoint.x + (-parentFrame.minX + parentFrame.minY)
            self.edgeFromParent = (expectedY <= midPoint.y) ? .left : .top
            return
        }

        //Check Top Right
        if (midPoint.x > parentFrame.minX) && (midPoint.y < parentFrame.minY) {
            //y = -x + (p.x + p.y)
            let expectedY = -midPoint.x + (parentFrame.maxX + parentFrame.minY)
            self.edgeFromParent = (expectedY >= midPoint.y) ? .top : .right
            return
        }

        //Check Bottom Right
        if (midPoint.x > parentFrame.minX) && (midPoint.y > parentFrame.maxY) {
            //y = x + (-p.x + p.y)
            let expectedY = midPoint.x + (-parentFrame.maxX + parentFrame.maxY)
            self.edgeFromParent = (expectedY >= midPoint.y) ? .right : .bottom
            return
        }

        //Check Bottom Left
        if (midPoint.x < parentFrame.minX) && (midPoint.y > parentFrame.minY) {
            //y = x + (-p.x + p.y)
            let expectedY = -midPoint.x + (parentFrame.minX + parentFrame.maxY)
            self.edgeFromParent = (expectedY <= midPoint.y) ? .bottom : .left
            return
        }
    }

    func removeChild(_ child: LayoutEnginePage) {
        child.parent = nil
        if let index = self.children.firstIndex(of: child) {
            self.children.remove(at: index)
        }
    }


    //MARK: - Layout Frames
    private func layoutFrameMargins(for config: CanvasLayoutEngine.Configuration) -> CanvasLayoutMargins {
        return config.page.shadowOffset.adding(self.borderMargins(for: config))
    }

    var minimumLayoutSize: CGSize {
        guard let config = self.layoutEngine?.configuration else {
            return self.minimumContentSize
        }

        let margins = self.layoutFrameMargins(for: config)
        return CGRect(origin: .zero, size: self.minimumContentSize).grow(by: margins).size
    }

    var layoutFrame: CGRect {
        get {
            let canvasOrigin = self.layoutEngine?.convertPointToCanvasSpace(self.contentFrame.origin) ?? self.contentFrame.origin
            let canvasFrame = CGRect(origin: canvasOrigin, size: self.contentFrame.size)
            guard let config = self.layoutEngine?.configuration else {
                return canvasFrame
            }
            let margins = self.layoutFrameMargins(for: config)
            return canvasFrame.grow(by: margins)
        }
        set {

            let pageOrigin = self.layoutEngine?.convertPointToPageSpace(newValue.origin) ?? newValue.origin
            let contentFrame = CGRect(origin: pageOrigin, size: newValue.size)
            guard let config = self.layoutEngine?.configuration else {
                self.contentFrame = contentFrame
                return
            }
            let margins = self.layoutFrameMargins(for: config)
            self.contentFrame = contentFrame.shrink(by: margins)
        }
    }

    var layoutFrameInPageSpace: CGRect {
        let pageOrigin = self.layoutEngine?.convertPointToPageSpace(self.layoutFrame.origin) ?? self.layoutFrame.origin
        return CGRect(origin: pageOrigin, size: self.layoutFrame.size)
    }


    //MARK: - Calculated Frames For Layout
    private func borderMargins(for config: CanvasLayoutEngine.Configuration) -> CanvasLayoutMargins {
        return CanvasLayoutMargins(default: config.page.borderSize, top: config.page.titleHeight)
    }

    var visualPageFrame: CGRect {
        let visualFrame = CGRect(origin: .zero, size: self.layoutFrame.size)
        guard let config = self.layoutEngine?.configuration else {
            return visualFrame
        }
        return visualFrame.shrink(by: config.page.shadowOffset)
    }

    var titleBarFrame: CGRect {
        var visualPageFrame = self.visualPageFrame
        let titleHeight = self.layoutEngine?.configuration.page.titleHeight ?? 0
        visualPageFrame.size.height = titleHeight

        return visualPageFrame
    }

    var contentContainerFrame: CGRect {
        guard let config = self.layoutEngine?.configuration else {
            return .zero
        }

        let visualFrame = self.visualPageFrame
        let margins = self.borderMargins(for: config)
        return visualFrame.shrink(by: margins)
    }

    var frameForArrows: CGRect {
        var frame = self.contentContainerFrame
        frame.origin = frame.origin.plus(self.layoutFrame.origin)
        return frame
    }

    static func == (lhs: LayoutEnginePage, rhs: LayoutEnginePage) -> Bool {
        return lhs.id == rhs.id
    }

    private func validateSize() {
        var boundedSize = self.contentFrame.size
        boundedSize.width = max(boundedSize.width, self.minimumContentSize.width)
        boundedSize.height = max(boundedSize.height, self.minimumContentSize.height)

        if boundedSize != self.contentFrame.size {
            self.contentFrame.size = boundedSize
        }
    }


    //MARK: - Components
    func rectInLayoutFrame(for component: LayoutEnginePageComponent) -> CGRect {
        guard let configuration = self.layoutEngine?.configuration else {
            return .zero
        }
        if (component == .titleBar) {
            var titleBarRect = self.visualPageFrame
            titleBarRect.size.height = configuration.page.titleHeight
            return titleBarRect
        }
        if (component == .content) {
            return self.contentContainerFrame
        }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0

        let layoutSize = self.visualPageFrame.size

        if (component.isCorner) {
            width = configuration.page.cornerResizeHandleSize
            height = configuration.page.cornerResizeHandleSize
        }
        else if (component == .resizeRight || component == .resizeLeft) {
            y = configuration.page.cornerResizeHandleSize
            width = configuration.page.edgeResizeHandleSize
            height = layoutSize.height - (2 * configuration.page.cornerResizeHandleSize)
        }
        else if (component == .resizeTop || component == .resizeBottom) {
            x = configuration.page.cornerResizeHandleSize
            width = layoutSize.width - (2 * configuration.page.cornerResizeHandleSize)
            height = configuration.page.edgeResizeHandleSize
        }

        if (component.isRight) {
            x = layoutSize.width - width
        }
        if (component.isBottom) {
            y = layoutSize.height - height
        }

        return CGRect(x: x + self.visualPageFrame.minX, y: y + self.visualPageFrame.minY, width: width, height: height)
    }

    func component(at point: CGPoint) -> LayoutEnginePageComponent? {
        for component in LayoutEnginePageComponent.orderedCases {
            if self.rectInLayoutFrame(for: component).contains(point) {
                return component
            }
        }
        return nil
    }


    enum Edge: CaseIterable, Equatable {
        case left
        case top
        case right
        case bottom

        var opposite: Edge {
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

enum LayoutEnginePageComponent: CaseIterable, Equatable {
    case resizeLeft
    case resizeTopLeft
    case resizeTop
    case resizeTopRight
    case resizeRight
    case resizeBottomRight
    case resizeBottom
    case resizeBottomLeft
    case titleBar
    case content

    var isRight: Bool {
        return [.resizeRight, .resizeTopRight, .resizeBottomRight].contains(self)
    }

    var isBottom: Bool {
        return [.resizeBottom, .resizeBottomLeft, .resizeBottomRight].contains(self)
    }

    var isLeft: Bool {
        return [.resizeLeft, .resizeTopLeft, .resizeBottomLeft].contains(self)
    }

    var isTop: Bool {
        return [.resizeTop, .resizeTopLeft, .resizeTopRight].contains(self)
    }

    var isCorner: Bool {
        return [.resizeTopLeft, .resizeTopRight, .resizeBottomLeft, .resizeBottomRight].contains(self)
    }

    var isEdge: Bool {
        return [.resizeLeft, .resizeTop, .resizeRight, .resizeBottom].contains(self)
    }

    static var orderedCases: [LayoutEnginePageComponent] {
        var cases = self.allCases
        if let index = cases.firstIndex(of: .titleBar) {
            cases.remove(at: index)
        }
        if let index = cases.firstIndex(of: .content) {
            cases.remove(at: index)
        }
        cases.append(.titleBar)
        cases.append(.content)
        return cases
    }
}
