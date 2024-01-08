//
//  TestObjects.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

import M3Data

class TestModelObject: ModelObject {
    lazy var plistRepresentation = ModelObjectPlistRepresentation(id: self.id, plist: [:])

    var otherProperties = [ModelPlistKey: PlistValue]()

    func update(fromPlistRepresentation plist: ModelObjectPlistRepresentation) {}

    static var modelType: ModelType = ModelType("Test")

    var id = ModelID(modelType: TestModelObject.modelType)

    var modelController: ModelController?

    required init(id: ModelID) {
        self.id = id
    }
}

final class TestCollectableModelObject: NSObject, CollectableModelObject {
    init(id: ModelID) {
        self.id = id
    }

    lazy var plistRepresentation = ModelObjectPlistRepresentation(id: self.id, plist: [:])

    var otherProperties = [ModelPlistKey: PlistValue]()

    func update(fromPlistRepresentation plist: ModelObjectPlistRepresentation) {}

    var collection: ModelCollection<TestCollectableModelObject>?

    var id = ModelID(modelType: TestCollectableModelObject.modelType)

    static var modelType: ModelType = ModelType("CollectableTest")

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

    @ModelObjectReference var inverseRelationship: RelationshipModelObject? {
        didSet { self.didChangeRelationship(\.inverseRelationship, inverseKeyPath: \.relationship, oldValue: oldValue) }
    }

    var isMatch: Bool = false
    func isMatchForSearch(_ searchString: String?) -> Bool {
        return self.isMatch
    }
}

final class RelationshipModelObject: NSObject, CollectableModelObject {
    lazy var plistRepresentation = ModelObjectPlistRepresentation(id: self.id, plist: [:])
    var otherProperties = [ModelPlistKey: PlistValue]()

    func update(fromPlistRepresentation plist: ModelObjectPlistRepresentation) {}

    var collection: ModelCollection<RelationshipModelObject>?

    var id = ModelID(modelType: RelationshipModelObject.modelType)

    static var modelType: ModelType = ModelType("Relationship")

    var relationship: Set<TestCollectableModelObject> {
        self.relationship(for: \.inverseRelationship)
    }

    init(id: ModelID) {
        self.id = id
    }
}

class TestModelController: NSObject, ModelController {
    var settings = ModelSettings()

    var undoManager = UndoManager()
    var allCollections = [ModelType: AnyModelCollection]()

    func object(with id: ModelID) -> ModelObject? {
        return self.collection(for: TestCollectableModelObject.self).objectWithID(id)
    }
}
