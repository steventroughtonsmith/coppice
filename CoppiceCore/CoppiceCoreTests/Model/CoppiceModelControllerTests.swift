//
//  CoppiceModelControllerTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 10/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import XCTest

class CoppiceModelControllerTests: XCTestCase {
    //MARK: - init(undoManager:)
    func test_init_setsUndoManagerToSuppliedManager() {
        let undoManager = UndoManager()
        let modelController = CoppiceModelController(undoManager: undoManager)
        XCTAssertTrue(modelController.undoManager === undoManager)
    }

    func test_init_setsUpCollectionsForCanvas_CanvasPage_PageAndFolder() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        XCTAssertEqual(modelController.allCollections.count, 6)
        XCTAssertNotNil(modelController.allCollections[Canvas.modelType])
        XCTAssertNotNil(modelController.allCollections[CanvasPage.modelType])
        XCTAssertNotNil(modelController.allCollections[Folder.modelType])
        XCTAssertNotNil(modelController.allCollections[Page.modelType])
        XCTAssertNotNil(modelController.allCollections[CanvasLink.modelType])
        XCTAssertNotNil(modelController.allCollections[PageHierarchy.modelType])
    }


    //MARK: - object(with:)
    func tests_objectWithID_returnsMatchingCanvasIfCanvasType() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvas = modelController.collection(for: Canvas.self).newObject()

        XCTAssertEqual(modelController.object(with: canvas.id)?.id, canvas.id)
    }

    func test_objectWithID_returnsNilIfNoMatchingCanvas() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        modelController.collection(for: Canvas.self).newObject()

        XCTAssertNil(modelController.object(with: Canvas.modelID(with: UUID())))
    }

    func test_objectWithID_returnsMatchingCanvasPageIfCanvasPageType() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let canvasPage = modelController.collection(for: CanvasPage.self).newObject()

        XCTAssertEqual(modelController.object(with: canvasPage.id)?.id, canvasPage.id)
    }

    func test_objectWithID_returnsNilIfNoMatchingCanvasPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        modelController.collection(for: CanvasPage.self).newObject()

        XCTAssertNil(modelController.object(with: CanvasPage.modelID(with: UUID())))
    }

    func test_objectWithID_returnsMatchingFolderIfFolderType() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let folder = modelController.collection(for: Folder.self).newObject()

        XCTAssertEqual(modelController.object(with: folder.id)?.id, folder.id)
    }

    func test_objectWithID_returnsNilIfNoMatchingFolder() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        modelController.collection(for: Folder.self).newObject()

        XCTAssertNil(modelController.object(with: Folder.modelID(with: UUID())))
    }

    func test_objectWithID_returnsMatchingPageIfPageType() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        let page = modelController.collection(for: Page.self).newObject()

        XCTAssertEqual(modelController.object(with: page.id)?.id, page.id)
    }

    func test_objectWithID_returnsNilIfNoMatchingPage() {
        let modelController = CoppiceModelController(undoManager: UndoManager())
        modelController.collection(for: Page.self).newObject()

        XCTAssertNil(modelController.object(with: Page.modelID(with: UUID())))
    }


    //MARK: - .identifier
    func test_identifier_returnsIdentifierFromSettingsIfOneExists() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let expectedIdentifier = UUID()
        modelController.settings.set(expectedIdentifier.uuidString, for: .documentIdentifier)

        XCTAssertEqual(modelController.identifier, expectedIdentifier)
    }

    func test_identifier_addsNewIdentifierToSettingsIfNoneExistedBefore() {
        let modelController = CoppiceModelController(undoManager: UndoManager())

        let expectedIdentifier = modelController.identifier.uuidString
        XCTAssertEqual(modelController.settings.string(for: .documentIdentifier), expectedIdentifier)
    }
}
