//
//  TestObjects.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 02/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
@testable import Bubbles

class TestModelObject: ModelObject {
    static var modelType: ModelType = ModelType("Test")!

    var id = ModelID(modelType: TestModelObject.modelType)

    var modelController: ModelController?
}

final class TestCollectableModelObject: NSObject, CollectableModelObject {
    var collection: ModelCollection<TestCollectableModelObject>?

    var id = ModelID(modelType: TestCollectableModelObject.modelType)

    static var modelType: ModelType = ModelType("CollectableTest")!

    required override init() {
        super.init()
    }

    var objectWasInsertedCalled = false
    func objectWasInserted() {
        self.objectWasInsertedCalled = true
    }

    var stringProperty = "Test"

    var inverseRelationship: TestCollectableModelObject?
}

class TestModelController: NSObject, ModelController {
    var undoManager = UndoManager()
    var collections = [ModelType : Any]()

    override init() {
        super.init()
        self.add(ModelCollection<TestCollectableModelObject>(), for: TestCollectableModelObject.modelType)
    }

    func object(with id: ModelID) -> ModelObject? {
        return (self.collection(for: id.modelType) as? ModelCollection<TestCollectableModelObject>)?.objectWithID(id)
    }


}
