//
//  BubblesModelControllerCanvasPageTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 23/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class BubblesModelControllerCanvasPageTests: XCTestCase {
    var undoManager: UndoManager!
    var modelController: BubblesModelController!

    override func setUp() {
        super.setUp()

        self.undoManager = UndoManager()
        self.modelController = BubblesModelController(undoManager: self.undoManager)
    }

    
    //MARK: - .canvasPageCollection


    //MARK: - addPages(_:to:centredOn:)


    //MARK: - openPage(at:on:)


    //MARK: - close(_:)

}
