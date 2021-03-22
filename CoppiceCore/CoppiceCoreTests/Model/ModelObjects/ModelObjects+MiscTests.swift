//
//  ModelObjects+MiscTests.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 23/11/2020.
//

@testable import CoppiceCore
import XCTest

class ModelObjects_MiscTests: XCTestCase {
    func test_modelCollectionCanvas_sortedCanvases_returnsCanvasesInAscendingSortOrder() throws {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let canvas1 = Canvas.create(in: modelController) { $0.title = "Some Possum content" }
        let canvas2 = Canvas.create(in: modelController) { $0.title = "Page match 1" }
        let canvas3 = Canvas.create(in: modelController) { $0.title = "No matches" }
        let canvas4 = Canvas.create(in: modelController) { $0.title = "Page match 2" }

        canvas4.sortIndex = 0
        canvas1.sortIndex = 1
        canvas3.sortIndex = 2
        canvas2.sortIndex = 3

        XCTAssertEqual(modelController.collection(for: Canvas.self).sortedCanvases, [canvas4, canvas1, canvas3, canvas2])
    }
}
