//
//  EventContextTestBase.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

let testEventContextLayoutASCII = """
          |
          |
          |
    ____  |   ___   __
   |  1 | |  | 2|  | 3|
---|----|-|--|--|--|--|
   |____| |  |__|  |__|
          |
          |
          |
          |
          |
"""

class EventContextTestBase: XCTestCase {
    var page1: TestLayoutEnginePage!
    var page2: TestLayoutEnginePage!
    var page3: TestLayoutEnginePage!
    var page3Wide: TestLayoutEnginePage!

    var mockLayoutEngine: MockLayoutEngine!

    var contentBorder: CGFloat = 20
    var contentOffset: CGPoint = .zero

    var testConfiguration: CanvasLayoutEngine.Configuration?

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.testConfiguration = .init(page: .init(titleHeight: 0, borderSize: 0, shadowOffset: .zero, edgeResizeHandleSize: 2, cornerResizeHandleSize: 4),
                                       contentBorder: 0,
                                       arrow: .init(endLength: 5, cornerSize: 5, arrowHeadSize: 5, lineWidth: 2))

        self.page1 = TestLayoutEnginePage(id: UUID(),
                                          contentFrame: CGRect(x: -25, y: -10, width: 20, height: 30),
                                          minimumContentSize: CGSize(width: 0, height: 0))
        self.page1.testConfiguration = self.testConfiguration

        self.page2 = TestLayoutEnginePage(id: UUID(),
                                          contentFrame: CGRect(x: 10, y: -10, width: 10, height: 30),
                                          minimumContentSize: CGSize(width: 0, height: 0))
        self.page2.testConfiguration = self.testConfiguration

        self.page3 = TestLayoutEnginePage(id: UUID(),
                                          contentFrame: CGRect(x: 30, y: -10, width: 20, height: 40),
                                          maintainAspectRatio: true,
                                          minimumContentSize: CGSize(width: 0, height: 0))
        self.page3.testConfiguration = self.testConfiguration

        self.page3Wide = TestLayoutEnginePage(id: UUID(),
                                              contentFrame: CGRect(x: 10, y: -10, width: 40, height: 20),
                                              maintainAspectRatio: true,
                                              minimumContentSize: CGSize(width: 0, height: 0))
        self.page3Wide.testConfiguration = self.testConfiguration

        self.mockLayoutEngine = MockLayoutEngine()
    }

    func setupLayoutFrames() {
        let pages = [self.page1, self.page2, self.page3, self.page3Wide] as [TestLayoutEnginePage]
        let frame = pages.reduce(.zero) { (frame, page) in
            return page.contentFrame.union(frame)
        }

        let expandedFrame = frame.insetBy(dx: -self.contentBorder, dy: -self.contentBorder)

        self.mockLayoutEngine.canvasSize = expandedFrame.size
        self.contentOffset = expandedFrame.origin

        for page in pages {
            var pageFrame = page.contentFrame
            pageFrame.origin = pageFrame.origin.minus(expandedFrame.origin)
            page.testLayoutFrame = pageFrame
        }
    }
}


class TestLayoutEnginePage: LayoutEnginePage {
    var testLayoutFrame: CGRect?

    override var layoutFrame: CGRect {
        get { return self.testLayoutFrame ?? super.layoutFrame }
        set {
            self.testLayoutFrame = newValue
            super.layoutFrame = newValue
        }
    }

    var testConfiguration: CanvasLayoutEngine.Configuration?

    override var configuration: CanvasLayoutEngine.Configuration? {
        return self.testConfiguration ?? super.configuration
    }

    var titlePoint: CGPoint {
        return self.contentFrame.origin.plus(.identity)
    }

    var contentPoint: CGPoint {
        return self.contentFrame.midPoint
    }

    var testComponent: LayoutEnginePageComponent?
    override func component(at point: CGPoint) -> LayoutEnginePageComponent? {
        return self.testComponent ?? super.component(at: point)
    }
}
