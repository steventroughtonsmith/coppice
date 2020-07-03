//
//  EventContextTestBase.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

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

    var page1: LayoutEnginePage!
    var page2: LayoutEnginePage!
    var page3: LayoutEnginePage!

    var mockLayoutEngine: MockLayoutEngine!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.page1 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: -25, y: -10, width: 20, height: 30),
                                      minimumContentSize: CGSize(width: 0, height: 0))
        self.page2 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 10, y: -10, width: 10, height: 30),
                                      minimumContentSize: CGSize(width: 0, height: 0))
        self.page3 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 30, y: -10, width: 30, height: 30),
                                      minimumContentSize: CGSize(width: 0, height: 0))

        self.mockLayoutEngine = MockLayoutEngine()
    }

}


//Helpers
extension LayoutEnginePage {
    var titlePoint: CGPoint {
        return self.contentFrame.origin.plus(.identity)
    }

    var contentPoint: CGPoint {
        return self.contentFrame.midPoint
    }
}
