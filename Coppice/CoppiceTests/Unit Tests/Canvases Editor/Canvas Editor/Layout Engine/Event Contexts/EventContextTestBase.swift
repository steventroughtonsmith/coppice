//
//  EventContextTestBase.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 03/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class EventContextTestBase: XCTestCase {

    var page1: LayoutEnginePage!
    var page2: LayoutEnginePage!
    var page3: LayoutEnginePage!

    var mockLayoutEngine: MockLayoutEngine!

    override func setUpWithError() throws {
        try super.setUpWithError()

        self.page1 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 40, y: 40, width: 10, height: 10),
                                      minimumContentSize: CGSize(width: 0, height: 0))
        self.page2 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: -30, y: -20, width: 20, height: 40),
                                      minimumContentSize: CGSize(width: 0, height: 0))
        self.page3 = LayoutEnginePage(id: UUID(),
                                      contentFrame: CGRect(x: 30, y: -30, width: 30, height: 20),
                                      minimumContentSize: CGSize(width: 0, height: 0))

        self.mockLayoutEngine = MockLayoutEngine()
    }

}
