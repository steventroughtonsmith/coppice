//
//  LayoutEnginePage.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

//Return URL from isLink
//Hightlight instances of link
//Stop highlighting

public protocol LayoutEnginePageView: AnyObject {
    func startEditing(atContentPoint point: CGPoint)
    func stopEditing()
    func link(atContentPoint point: CGPoint) -> URL?
    func openLink(atContentPoint point: CGPoint)
    func highlightLinks(matching pageLink: PageLink)
    func unhighlightLinks()
}

/// A class representing the layout information for a page inside the LayoutEngine
///
/// The main frame that is manipulated is the contentFrame, which is what is persisted.
/// Each Page view is expected to have the following hierarchy (and associated layout frames)
///
/// - Page View (`layoutFrame`): the view inside the canvas
///     - Visual Page (`visualPageFrame`): the page as drawn on screen
///     - Title Bar (`titleBarFrame`): The title bar for moving
///     - Content (`contentContainerFrame`): The actual page content
public class LayoutEnginePage: LayoutEngineItem, Hashable {
    public var showBackground: Bool {
        if let layoutEngine = self.canvasLayoutEngine {
            if layoutEngine.alwaysShowPageTitles == true {
                return true
            }
            if layoutEngine.pageUnderMouse == self {
                return true
            }
        }
        return self.selected
    }

    /// Enabled pages can be edited
    public var enabled: Bool {
        return (self.canvasLayoutEngine?.enabledPage == self)
    }

    public var isEditing: Bool = false

    public var zIndex = -1

    public weak var view: LayoutEnginePageView?

    public var configuration: CanvasLayoutEngine.Configuration? {
        return self.canvasLayoutEngine?.configuration
    }

    public init(id: UUID,
                contentFrame: CGRect,
                maintainAspectRatio: Bool = false,
                minimumContentSize: CGSize = Page.defaultMinimumContentSize,
                zIndex: Int = -1)
    {
        self.contentFrame = contentFrame
        self.maintainAspectRatio = maintainAspectRatio
        self.minimumContentSize = minimumContentSize
        self.zIndex = zIndex
        super.init(id: id)

        self.validateSize()
    }

    //MARK: - Content
    public var minimumContentSize: CGSize

    /// The frame of the page's content in pageSpace
    public var contentFrame: CGRect {
        didSet {
            self.validateSize()
        }
    }

    public let maintainAspectRatio: Bool
    public var aspectRatio: CGFloat {
        return self.contentFrame.width / self.contentFrame.height
    }


    //MARK: - Relationships
    public private(set) weak var parent: LayoutEnginePage?

    public private(set) var edgeFromParent: Edge?

    public private(set) var children = [LayoutEnginePage]()

    public var allDescendants: [LayoutEnginePage] {
        var pages = [LayoutEnginePage]()
        for child in self.children {
            pages.append(child)
            pages.append(contentsOf: child.allDescendants)
        }
        return pages
    }

    public func children(for edge: Edge) -> [LayoutEnginePage] {
        return self.children.filter { $0.edgeFromParent == edge }
    }

    public func addChild(_ child: LayoutEnginePage) {
        self.children.append(child)
        child.parent = self
    }

    func edge(toSourcePage sourcePage: LayoutEnginePage) -> Edge? {
        return self.edge(to: sourcePage.layoutFrame)
    }

    func edge(to sourcePageFrame: CGRect) -> Edge? {
        let midPoint = self.layoutFrame.midPoint
        //Check if inside
        guard sourcePageFrame.contains(midPoint) == false else {
            return (midPoint.x < sourcePageFrame.midX) ? .right : .left
        }

        //Check if directly to side
        if (midPoint.y >= sourcePageFrame.minY) && (midPoint.y <= sourcePageFrame.maxY) {
            return (midPoint.x > sourcePageFrame.maxX) ? .left : .right
        }

        //Check if directly above or below
        if (midPoint.x >= sourcePageFrame.minX) && (midPoint.x <= sourcePageFrame.maxX) {
            return (midPoint.y > sourcePageFrame.maxY) ? .top : .bottom
        }

        //Check Top Left
        if (midPoint.x < sourcePageFrame.minX) && (midPoint.y < sourcePageFrame.minY) {
            //y = x + (-p.x + p.y)
            let expectedY = midPoint.x + (-sourcePageFrame.minX + sourcePageFrame.minY)
            return (expectedY <= midPoint.y) ? .right : .bottom
        }

        //Check Top Right
        if (midPoint.x > sourcePageFrame.minX) && (midPoint.y < sourcePageFrame.minY) {
            //y = -x + (p.x + p.y)
            let expectedY = -midPoint.x + (sourcePageFrame.maxX + sourcePageFrame.minY)
            return (expectedY >= midPoint.y) ? .bottom : .left
        }

        //Check Bottom Right
        if (midPoint.x > sourcePageFrame.minX) && (midPoint.y > sourcePageFrame.maxY) {
            //y = x + (-p.x + p.y)
            let expectedY = midPoint.x + (-sourcePageFrame.maxX + sourcePageFrame.maxY)
            return (expectedY >= midPoint.y) ? .left : .top
        }

        //Check Bottom Left
        if (midPoint.x < sourcePageFrame.minX) && (midPoint.y > sourcePageFrame.minY) {
            //y = x + (-p.x + p.y)
            let expectedY = -midPoint.x + (sourcePageFrame.minX + sourcePageFrame.maxY)
            return (expectedY <= midPoint.y) ? .top : .right
        }

        return nil
    }

    public func removeChild(_ child: LayoutEnginePage) {
        if let index = self.children.firstIndex(of: child) {
            child.parent = nil
            self.children.remove(at: index)
        }
    }


    //MARK: - Layout Frames
    public func convertPointToContentSpace(_ point: CGPoint) -> CGPoint {
        guard let layoutEngine = self.canvasLayoutEngine else {
            return point
        }
        let contentOrigin = layoutEngine.convertPointToCanvasSpace(self.contentFrame.origin)
        return point.minus(contentOrigin)
    }

    private func layoutFrameMargins(for config: CanvasLayoutEngine.Configuration) -> CanvasLayoutMargins {
        return config.page.shadowOffset.adding(self.borderMargins(for: config))
    }

    public var minimumLayoutSize: CGSize {
        guard let config = self.configuration else {
            return self.minimumContentSize
        }

        let margins = self.layoutFrameMargins(for: config)
        return CGRect(origin: .zero, size: self.minimumContentSize).grow(by: margins).size
    }

    public override var layoutFrame: CGRect {
        get {
            let canvasOrigin = self.canvasLayoutEngine?.convertPointToCanvasSpace(self.contentFrame.origin) ?? self.contentFrame.origin
            let canvasFrame = CGRect(origin: canvasOrigin, size: self.contentFrame.size)
            guard let config = self.configuration else {
                return canvasFrame
            }
            let margins = self.layoutFrameMargins(for: config)
            return canvasFrame.grow(by: margins)
        }
        set {
            let pageOrigin = self.canvasLayoutEngine?.convertPointToPageSpace(newValue.origin) ?? newValue.origin
            let contentFrame = CGRect(origin: pageOrigin, size: newValue.size)
            guard let config = self.configuration else {
                self.contentFrame = contentFrame
                return
            }
            let margins = self.layoutFrameMargins(for: config)
            self.contentFrame = contentFrame.shrink(by: margins)
        }
    }

    public var layoutFrameInPageSpace: CGRect {
        let pageOrigin = self.canvasLayoutEngine?.convertPointToPageSpace(self.layoutFrame.origin) ?? self.layoutFrame.origin
        return CGRect(origin: pageOrigin, size: self.layoutFrame.size)
    }


    //MARK: - Calculated Frames For Layout
    private func borderMargins(for config: CanvasLayoutEngine.Configuration) -> CanvasLayoutMargins {
        return CanvasLayoutMargins(default: config.page.borderSize, top: config.page.titleHeight)
    }

    public var visualPageFrame: CGRect {
        let visualFrame = CGRect(origin: .zero, size: self.layoutFrame.size)
        guard let config = self.configuration else {
            return visualFrame
        }
        return visualFrame.shrink(by: config.page.shadowOffset)
    }

    public var titleBarFrame: CGRect {
        var visualPageFrame = self.visualPageFrame
        let titleHeight = self.configuration?.page.titleHeight ?? 0
        visualPageFrame.size.height = titleHeight

        return visualPageFrame
    }

    public var contentContainerFrame: CGRect {
        guard let config = self.configuration else {
            return .zero
        }

        let visualFrame = self.visualPageFrame
        let margins = self.borderMargins(for: config)
        return visualFrame.shrink(by: margins)
    }

    public var frameForArrows: CGRect {
        var frame = self.contentContainerFrame
        frame.origin = frame.origin.plus(self.layoutFrame.origin)
        return frame
    }

    public static func == (lhs: LayoutEnginePage, rhs: LayoutEnginePage) -> Bool {
        return lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.id)
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
    public func rectInLayoutFrame(for component: LayoutEnginePageComponent) -> CGRect {
        guard let configuration = self.configuration else {
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
        } else if (component == .resizeRight || component == .resizeLeft) {
            guard self.maintainAspectRatio == false else {
                return .zero
            }
            y = configuration.page.cornerResizeHandleSize
            width = configuration.page.edgeResizeHandleSize
            height = layoutSize.height - (2 * configuration.page.cornerResizeHandleSize)
        } else if (component == .resizeTop || component == .resizeBottom) {
            guard self.maintainAspectRatio == false else {
                return .zero
            }
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

    public func component(at point: CGPoint) -> LayoutEnginePageComponent? {
        for component in LayoutEnginePageComponent.orderedCases {
            if self.rectInLayoutFrame(for: component).contains(point) {
                return component
            }
        }
        return nil
    }


    public enum Edge: CaseIterable, Equatable {
        case left
        case top
        case right
        case bottom

        public var opposite: Edge {
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

public enum LayoutEnginePageComponent: CaseIterable, Equatable {
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

    public var isRight: Bool {
        return [.resizeRight, .resizeTopRight, .resizeBottomRight].contains(self)
    }

    public var isBottom: Bool {
        return [.resizeBottom, .resizeBottomLeft, .resizeBottomRight].contains(self)
    }

    public var isLeft: Bool {
        return [.resizeLeft, .resizeTopLeft, .resizeBottomLeft].contains(self)
    }

    public var isTop: Bool {
        return [.resizeTop, .resizeTopLeft, .resizeTopRight].contains(self)
    }

    public var isCorner: Bool {
        return [.resizeTopLeft, .resizeTopRight, .resizeBottomLeft, .resizeBottomRight].contains(self)
    }

    public var isEdge: Bool {
        return [.resizeLeft, .resizeTop, .resizeRight, .resizeBottom].contains(self)
    }

    public static var orderedCases: [LayoutEnginePageComponent] {
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
