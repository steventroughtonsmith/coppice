//
//  ModelControllerTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 09/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class ModelControllerTests: XCTestCase {

    //MARK: - addModelCollection(for:)
    func test_addModelCollectionForType_addsNewCollectionToAllCollections() {
        let modelController = ModelControllerForTests()
        modelController.addModelCollection(for: TestCollectableModelObject.self)
        XCTAssertNotNil(modelController.allCollections[TestCollectableModelObject.modelType])
    }

    func test_addModelCollectionForType_returnsModelCollectionThatWasAddedToAllCollections() {
        let modelController = ModelControllerForTests()
        let collection = modelController.addModelCollection(for: TestCollectableModelObject.self)
        XCTAssertTrue(modelController.allCollections[TestCollectableModelObject.modelType] as? ModelCollection<TestCollectableModelObject> === collection)
    }

    func test_addModelCollectionForType_setsModelControllerOfNewCollectionToSelf() {
        let modelController = ModelControllerForTests()
        let collection = modelController.addModelCollection(for: TestCollectableModelObject.self)
        XCTAssertTrue(collection.modelController === modelController)
    }


    //MARK: - removeModelController(for:)
    func test_removeModelControllerForType_removesControllerMatchingType() {
        let modelController = ModelControllerForTests()
        modelController.addModelCollection(for: TestCollectableModelObject.self)

        modelController.removeModelCollection(for: TestCollectableModelObject.self)

        XCTAssertNil(modelController.allCollections[TestCollectableModelObject.modelType])

    }


    //MARK: - collection(for:)
    func test_collectionForType_returnsCollectionMatchingSuppliedType() {
        let modelController = ModelControllerForTests()
        let expectedCollection = modelController.addModelCollection(for: TestCollectableModelObject.self)

        let collection = modelController.collection(for: TestCollectableModelObject.self)
        XCTAssertTrue(collection === expectedCollection)
    }
}



class ModelControllerForTests: ModelController {
    let undoManager: UndoManager = UndoManager()

    var allCollections: [ModelType : Any] = [:]

    var settings = ModelSettings()

    func object(with id: ModelID) -> ModelObject? {
        return nil
    }
}
