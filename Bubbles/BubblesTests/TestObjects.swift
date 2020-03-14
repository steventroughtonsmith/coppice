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
    var plistRepresentation = [String : Any]()

    func update(fromPlistRepresentation plist: [String : Any]) {
    }

    static var modelType: ModelType = ModelType("Test")!

    var id = ModelID(modelType: TestModelObject.modelType)

    var modelController: ModelController?

    required init() {
        
    }
}

final class TestCollectableModelObject: NSObject, CollectableModelObject {
    var plistRepresentation = [String : Any]()

    func update(fromPlistRepresentation plist: [String : Any]) {
    }

    var collection: ModelCollection<TestCollectableModelObject>?

    var id = ModelID(modelType: TestCollectableModelObject.modelType)

    static var modelType: ModelType = ModelType("CollectableTest")!

    required override init() {
        super.init()
    }

    var objectWasInsertedCalled = false
    func objectWasInserted() {
        self.objectWasInsertedCalled = true
        self.$inverseRelationship.modelController = self.modelController
    }

    func objectWasDeleted() {
        self.$inverseRelationship.performCleanUp()
    }

    var stringProperty = "Test" {
        didSet { self.didChange(\.stringProperty, oldValue: oldValue) }
    }

    var intProperty = 0 {
        didSet { self.didChange(\.intProperty, oldValue: oldValue) }
    }

    @ModelObjectReference var inverseRelationship: RelationshipModelObject?

    var isMatch: Bool = false
    func isMatchForSearch(_ searchTerm: String?) -> Bool {
        return self.isMatch
    }
}

final class RelationshipModelObject: NSObject, CollectableModelObject {
    var plistRepresentation = [String : Any]()

    func update(fromPlistRepresentation plist: [String : Any]) {
    }

    var collection: ModelCollection<RelationshipModelObject>?

    var id = ModelID(modelType: RelationshipModelObject.modelType)

    static var modelType: ModelType = ModelType("Relationship")!

    var relationship: Set<TestCollectableModelObject> {
        self.relationship(for: \.inverseRelationship)
    }
}

class TestModelController: NSObject, ModelController {
    var settings = ModelSettings()

    var undoManager = UndoManager()
    var allCollections = [ModelType : Any]()

    func object(with id: ModelID) -> ModelObject? {
        return self.collection(for: TestCollectableModelObject.self).objectWithID(id)
    }


}
