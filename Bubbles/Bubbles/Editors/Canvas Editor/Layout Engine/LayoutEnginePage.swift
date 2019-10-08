//
//  LayoutEnginePage.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol LayoutPageComponentProvider {
    func component(at point: CGPoint, in page: LayoutEnginePage) -> LayoutEnginePageComponent?
}



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
    var componentProvider: LayoutPageComponentProvider?

    var selected: Bool = false

    //MARK: - Content

    var minimumContentSize: CGSize

    /// The frame of the page's content in pageSpace
    var contentFrame: CGRect {
        didSet {
            self.validateSize()
        }
    }


    //MARK: - Layout Frames

    var minimumLayoutSize: CGSize {
        guard let margins = self.layoutEngine?.configuration.layoutFrameOffsetFromContent else {
            return self.minimumContentSize
        }
        return CGRect(origin: .zero, size: self.minimumContentSize).grow(by: margins).size
    }

    var layoutFrame: CGRect {
        get {
            let canvasOrigin = self.layoutEngine?.convertPointToCanvasSpace(self.contentFrame.origin) ?? self.contentFrame.origin
            let canvasFrame = CGRect(origin: canvasOrigin, size: self.contentFrame.size)
            guard let margins = self.layoutEngine?.configuration.layoutFrameOffsetFromContent else {
                return canvasFrame
            }
            return canvasFrame.grow(by: margins)
        }
        set {

            let pageOrigin = self.layoutEngine?.convertPointToPageSpace(newValue.origin) ?? newValue.origin
            let contentFrame = CGRect(origin: pageOrigin, size: newValue.size)
            guard let margins = self.layoutEngine?.configuration.layoutFrameOffsetFromContent else {
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

        return CGRect(x: 0, y: titleHeight, width: visualPageFrame.size.width, height: visualPageFrame.size.height - titleHeight)
    }

    weak var layoutEngine: CanvasLayoutEngine?
    init(id: UUID,
         contentFrame: CGRect,
         minimumContentSize: CGSize = CGSize(width: 100, height: 200),
         layoutEngine: CanvasLayoutEngine) {
        self.id = id
        self.contentFrame = contentFrame
        self.minimumContentSize = minimumContentSize
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


    //MARK: - Components
    func component(at point: CGPoint) -> LayoutEnginePageComponent? {
        guard let configuration = self.layoutEngine?.configuration else {
            return nil
        }

        let biggestMargin = max(configuration.pageResizeEdgeHandleSize, configuration.pageResizeCornerHandleSize)
        let layoutSize = self.layoutFrame.size


        if (point.x < 0 || point.y < 0) {
            return nil
        }
        if (point.x >= layoutSize.width || point.y >= layoutSize.height) {
            return nil
        }
        
        //Left
        if (point.x < biggestMargin) {
            if (point.y < configuration.pageResizeCornerHandleSize) {
                return .resizeTopLeft
            }
            if (point.y >= (layoutSize.height - configuration.pageResizeCornerHandleSize)) {
                return .resizeBottomLeft
            }
            if (point.x < configuration.pageResizeEdgeHandleSize) {
                return .resizeLeft
            }
        }

        //Right
        if (point.x >= (layoutSize.width - biggestMargin)) {
            if (point.y < configuration.pageResizeCornerHandleSize) {
                return .resizeTopRight
            }
            if (point.y >= (layoutSize.height - configuration.pageResizeCornerHandleSize)) {
                return .resizeBottomRight
            }
            if (point.x >= (layoutSize.width - configuration.pageResizeEdgeHandleSize)) {
                return .resizeRight
            }
        }
        //Top & Bottom
        if (point.y < configuration.pageResizeEdgeHandleSize) {
            return .resizeTop
        }
        if (point.y >= (layoutSize.height - configuration.pageResizeEdgeHandleSize)) {
            return .resizeBottom
        }

        //Title
        if (self.titleFrameInsideVisualPage.contains(point)) {
            return .titleBar
        }

        return nil
    }
}

enum LayoutEnginePageComponent: CaseIterable, Equatable {
    case titleBar
    case resizeLeft
    case resizeTopLeft
    case resizeTop
    case resizeTopRight
    case resizeRight
    case resizeBottomRight
    case resizeBottom
    case resizeBottomLeft

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
}
