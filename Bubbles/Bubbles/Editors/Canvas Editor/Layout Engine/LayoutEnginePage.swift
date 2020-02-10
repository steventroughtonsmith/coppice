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
///         - Title Bar (`titleFrameInsideVisualPage`): The title bar for moving
///         - Content (`contentFrameInsideVisualPage`): The actual page content
class LayoutEnginePage: Equatable {
    let id: UUID
    let parentID: UUID?
    var selected: Bool = false

    var titleBarAppearsOverContent: Bool

    var enabled: Bool {
        return (self.layoutEngine?.enabledPage == self)
    }


    //MARK: - Initialisation
    weak var layoutEngine: CanvasLayoutEngine?
    init(id: UUID,
         contentFrame: CGRect,
         minimumContentSize: CGSize = CGSize(width: 150, height: 100),
         titleBarAppearsOverContent: Bool = false,
         parentID: UUID? = nil,
         layoutEngine: CanvasLayoutEngine) {
        self.id = id
        self.contentFrame = contentFrame
        self.minimumContentSize = minimumContentSize
        self.titleBarAppearsOverContent = titleBarAppearsOverContent
        self.parentID = parentID
        self.layoutEngine = layoutEngine
        self.validateSize()
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


    //MARK: - Content

    var minimumContentSize: CGSize

    /// The frame of the page's content in pageSpace
    var contentFrame: CGRect {
        didSet {
            self.validateSize()
        }
    }


    //MARK: - Layout Frames
    private var layoutOffsets: CanvasLayoutEngine.LayoutMargins? {
        if self.titleBarAppearsOverContent {
            return self.layoutEngine?.configuration.layoutFrameOffsetFromContent(options: [])
        }
        return self.layoutEngine?.configuration.layoutFrameOffsetFromContent(options: .includeTitleBar)
    }

    var minimumLayoutSize: CGSize {
        guard let margins = self.layoutOffsets else {
            return self.minimumContentSize
        }
        return CGRect(origin: .zero, size: self.minimumContentSize).grow(by: margins).size
    }

    var layoutFrame: CGRect {
        get {
            let canvasOrigin = self.layoutEngine?.convertPointToCanvasSpace(self.contentFrame.origin) ?? self.contentFrame.origin
            let canvasFrame = CGRect(origin: canvasOrigin, size: self.contentFrame.size)
            guard let margins = self.layoutOffsets else {
                return canvasFrame
            }
            return canvasFrame.grow(by: margins)
        }
        set {
            let pageOrigin = self.layoutEngine?.convertPointToPageSpace(newValue.origin) ?? newValue.origin
            let contentFrame = CGRect(origin: pageOrigin, size: newValue.size)
            guard let margins = self.layoutOffsets else {
                self.contentFrame = contentFrame
                return
            }
            self.contentFrame = contentFrame.shrink(by: margins)
        }
    }

    var layoutFrameInPageSpace: CGRect {
        let pageOrigin = self.layoutEngine?.convertPointToPageSpace(self.layoutFrame.origin) ?? self.layoutFrame.origin
        return CGRect(origin: pageOrigin, size: self.layoutFrame.size)
    }


    //MARK: - Calculated Frames For Layout
    var visualPageFrame: CGRect {
        let visualFrame = CGRect(origin: .zero, size: self.layoutFrame.size)
        guard let margins = self.layoutEngine?.configuration.visibleFrameInset else {
            return visualFrame
        }
        return visualFrame.shrink(by: margins)
    }

    var titleFrameInsideVisualPage: CGRect {
        let visualPageFrame = self.visualPageFrame
        let titleHeight = self.layoutEngine?.configuration.pageTitleHeight ?? 0

        return CGRect(x: 0, y: 0, width: visualPageFrame.size.width, height: titleHeight)
    }

    var contentFrameInsideVisualPage: CGRect {
        let visualPageFrame = self.visualPageFrame

        let titleHeight = self.layoutEngine?.configuration.pageTitleHeight ?? 0
        var y: CGFloat = 0
        var height = visualPageFrame.size.height
        if !self.titleBarAppearsOverContent {
            y = titleHeight
            height -= titleHeight
        }

        return CGRect(x: 0, y: y, width: visualPageFrame.size.width, height: height)
    }


    //MARK: - Components
    func rectInLayoutFrame(for component: LayoutEnginePageComponent) -> CGRect {
        guard let configuration = self.layoutEngine?.configuration else {
            return .zero
        }
        if (component == .titleBar) {
            var titleBarRect = self.visualPageFrame
            titleBarRect.size.height = configuration.pageTitleHeight
            return titleBarRect
        }
        if (component == .content) {
            return self.contentFrameInsideVisualPage
        }

        var x: CGFloat = 0
        var y: CGFloat = 0
        var width: CGFloat = 0
        var height: CGFloat = 0

        let layoutSize = self.layoutFrame.size

        if (component.isCorner) {
            width = configuration.pageResizeCornerHandleSize
            height = configuration.pageResizeCornerHandleSize
        }
        else if (component == .resizeRight || component == .resizeLeft) {
            y = configuration.pageResizeCornerHandleSize
            width = configuration.pageResizeEdgeHandleSize
            height = layoutSize.height - (2 * configuration.pageResizeCornerHandleSize)
        }
        else if (component == .resizeTop || component == .resizeBottom) {
            x = configuration.pageResizeCornerHandleSize
            width = layoutSize.width - (2 * configuration.pageResizeCornerHandleSize)
            height = configuration.pageResizeEdgeHandleSize
        }

        if (component.isRight) {
            x = layoutSize.width - width
        }
        if (component.isBottom) {
            y = layoutSize.height - height
        }

        return CGRect(x: x, y: y, width: width, height: height)
    }


    func component(at point: CGPoint) -> LayoutEnginePageComponent? {
        for component in LayoutEnginePageComponent.orderedCases {
            if self.rectInLayoutFrame(for: component).contains(point) {
                return component
            }
        }

        return nil
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
