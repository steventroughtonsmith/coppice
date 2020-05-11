//
//  CanvasLayoutEngine+Configuration.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/02/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

extension CanvasLayoutEngine {
    struct Configuration {
        struct Page {
            let titleHeight: CGFloat
            let borderSize: CGFloat
            let shadowOffset: CanvasLayoutMargins
            let edgeResizeHandleSize: CGFloat
            let cornerResizeHandleSize: CGFloat

            static let mac = Page(titleHeight: 24, borderSize: 3, shadowOffset: .init(left: 10, top: 5, right: 10, bottom: 10), edgeResizeHandleSize: 5, cornerResizeHandleSize: 8)
        }

        struct Arrow {
            let endLength: CGFloat
            let cornerSize: CGFloat
            let arrowHeadSize: CGFloat
            let lineWidth: CGFloat

            static let standard = Arrow(endLength: 20, cornerSize: 40, arrowHeadSize: 20, lineWidth: 3)
        }

        let page: Page
        let contentBorder: CGFloat
        let arrow: Arrow
    }
}

struct CanvasLayoutMargins: Equatable {
    let left: CGFloat
    let top: CGFloat
    let right: CGFloat
    let bottom: CGFloat

    static let zero = CanvasLayoutMargins(left: 0, top: 0, right: 0, bottom: 0)

    init(left: CGFloat, top: CGFloat, right: CGFloat, bottom: CGFloat) {
        self.left = left
        self.top = top
        self.right = right
        self.bottom = bottom
    }

    init(default: CGFloat, left: CGFloat? = nil, top: CGFloat? = nil, right: CGFloat? = nil, bottom: CGFloat? = nil) {
        self.init(left: left ?? `default`,
                  top: top ?? `default`,
                  right: right ?? `default`,
                  bottom: bottom ?? `default`)
    }

    func adding(_ margins: CanvasLayoutMargins) -> CanvasLayoutMargins {
        return CanvasLayoutMargins(left: self.left + margins.left,
                                   top: self.top + margins.top,
                                   right: self.right + margins.right,
                                   bottom: self.bottom + margins.bottom)
    }
}

extension CGRect {
    func grow(by layoutMargins: CanvasLayoutMargins) -> CGRect {
        return CGRect(x: (self.origin.x - layoutMargins.left),
                      y: (self.origin.y - layoutMargins.top),
                      width: (self.size.width + layoutMargins.left + layoutMargins.right),
                      height: (self.size.height + layoutMargins.top + layoutMargins.bottom))
    }

    func shrink(by layoutMargins: CanvasLayoutMargins) -> CGRect {
        return CGRect(x: (self.origin.x + layoutMargins.left),
                      y: (self.origin.y + layoutMargins.top),
                      width: (self.size.width - layoutMargins.left - layoutMargins.right),
                      height: (self.size.height - layoutMargins.top - layoutMargins.bottom))
    }
}
