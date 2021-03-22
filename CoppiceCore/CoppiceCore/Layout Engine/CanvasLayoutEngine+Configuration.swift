//
//  CanvasLayoutEngine+Configuration.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension CanvasLayoutEngine {
    public struct Configuration {
        public struct Page {
            public let titleHeight: CGFloat
            public let borderSize: CGFloat
            public let shadowOffset: CanvasLayoutMargins
            public let edgeResizeHandleSize: CGFloat
            public let cornerResizeHandleSize: CGFloat

            public static let mac = Page(titleHeight: 24, borderSize: 3, shadowOffset: .init(left: 10, top: 5, right: 10, bottom: 10), edgeResizeHandleSize: 5, cornerResizeHandleSize: 8)

            public init(titleHeight: CGFloat, borderSize: CGFloat, shadowOffset: CanvasLayoutMargins, edgeResizeHandleSize: CGFloat, cornerResizeHandleSize: CGFloat) {
                self.titleHeight = titleHeight
                self.borderSize = borderSize
                self.shadowOffset = shadowOffset
                self.edgeResizeHandleSize = edgeResizeHandleSize
                self.cornerResizeHandleSize = cornerResizeHandleSize
            }
        }

        public struct Arrow {
            public let endLength: CGFloat
            public let cornerSize: CGFloat
            public let arrowHeadSize: CGFloat
            public let lineWidth: CGFloat

            public static let standard = Arrow(endLength: 20, cornerSize: 40, arrowHeadSize: 20, lineWidth: 3)

            public init(endLength: CGFloat, cornerSize: CGFloat, arrowHeadSize: CGFloat, lineWidth: CGFloat) {
                self.endLength = endLength
                self.cornerSize = cornerSize
                self.arrowHeadSize = arrowHeadSize
                self.lineWidth = lineWidth
            }
        }

        public let page: Page
        public let contentBorder: CGFloat
        public let arrow: Arrow

        public init(page: CanvasLayoutEngine.Configuration.Page, contentBorder: CGFloat, arrow: CanvasLayoutEngine.Configuration.Arrow) {
            self.page = page
            self.contentBorder = contentBorder
            self.arrow = arrow
        }
    }
}

public struct CanvasLayoutMargins: Equatable {
    public let left: CGFloat
    public let top: CGFloat
    public let right: CGFloat
    public let bottom: CGFloat

    public static let zero = CanvasLayoutMargins(left: 0, top: 0, right: 0, bottom: 0)

    public init(left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }

    public init(default: CGFloat, left: CGFloat? = nil, top: CGFloat? = nil, right: CGFloat? = nil, bottom: CGFloat? = nil) {
        self.init(left: left ?? `default`,
                  top: top ?? `default`,
                  right: right ?? `default`,
                  bottom: bottom ?? `default`)
    }

    public func adding(_ margins: CanvasLayoutMargins) -> CanvasLayoutMargins {
        return CanvasLayoutMargins(left: self.left + margins.left,
                                   top: self.top + margins.top,
                                   right: self.right + margins.right,
                                   bottom: self.bottom + margins.bottom)
    }
}

extension CGRect {
    public func grow(by layoutMargins: CanvasLayoutMargins) -> CGRect {
        return CGRect(x: (self.origin.x - layoutMargins.left),
                      y: (self.origin.y - layoutMargins.top),
                      width: (self.size.width + layoutMargins.left + layoutMargins.right),
                      height: (self.size.height + layoutMargins.top + layoutMargins.bottom))
    }

    public func shrink(by layoutMargins: CanvasLayoutMargins) -> CGRect {
        return CGRect(x: (self.origin.x + layoutMargins.left),
                      y: (self.origin.y + layoutMargins.top),
                      width: (self.size.width - layoutMargins.left - layoutMargins.right),
                      height: (self.size.height - layoutMargins.top - layoutMargins.bottom))
    }
}
