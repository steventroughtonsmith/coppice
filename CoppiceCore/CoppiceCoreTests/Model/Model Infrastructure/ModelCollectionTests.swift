//
//  ModelCollectionTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
import CoppiceCore

class ModelCollectionTests: XCTestCase {
    var collection: ModelCollection<TestCollectableModelObject>!
    var relationshipCollection: ModelCollection<RelationshipModelObject>!
    var modelController: TestModelController!

    override func setUp() {
        super.setUp()

        self.modelController = TestModelController()
        self.collection = self.modelController.addModelCollection(for: TestCollectableModelObject.self)
        self.relationshipCollection = self.modelController.addModelCollection(for: RelationshipModelObject.self)
    }

    override func tearDown() {
        super.tearDown()

        self.collection = nil
        self.modelController = nil
    }

    //MARK: - .all
    func test_all_returnsAllObjects() {
        let o1 = self.collection.newObject()
        let o2 = self.collection.newObject()
        let o3 = self.collection.newObject()

        XCTAssertTrue(self.collection.all.contains(o1))
        XCTAssertTrue(self.collection.all.contains(o2))
        XCTAssertTrue(self.collection.all.contains(o3))
    }


    //MARK: - objectWithID(_:)
    func test_objectWithID_returnsObjectWithMatchingID() {
        let o1 = self.collection.newObject()
        let o2 = self.collection.newObject()
        let o3 = self.collection.newObject()

        XCTAssertEqual(self.collection.objectWithID(o1.id), o1)
        XCTAssertEqual(self.collection.objectWithID(o2.id), o2)
        XCTAssertEqual(self.collection.objectWithID(o3.id), o3)
    }

    func test_objectWithID_returnsNilIfNoObjectMatchesID() {
        self.collection.newObject()
        self.collection.newObject()
        self.collection.newObject()

        XCTAssertNil(self.collection.objectWithID(ModelID(modelType: TestCollectableModelObject.modelType)))
    }


    //MARK: - newObject()
    func test_newObject_returnsNewObjectWithCollectionSet() {
        let newObject = self.collection.newObject()
        XCTAssertTrue(newObject.collection === self.collection)
    }

    func test_newObject_tellsNewObjectOfInsertionAfterCollectionIsSet() {
        let newObject = self.collection.newObject()
        XCTAssertTrue(newObject.objectWasInsertedCalled)
    }

    func test_newObject_callsSetupBlockWithNewlyCreatedObject() {
        var blockObject: TestCollectableModelObject?
        let newObject = self.collection.newObject() { setupObject in
            blockObject = setupObject
        }

        XCTAssertEqual(newObject, blockObject)
    }

    func test_newObject_notifiesObserversOfInsert() {
        var changedObject: TestCollectableModelObject? = nil
        var changeType: ModelChangeType? = nil

        let expectation = self.expectation(description: "ObserverCalled")
        _ = self.collection.addObserver { (change) in
            changedObject = change.object
            changeType = change.changeType
            expectation.fulfill()
        }

        let newObject = self.collection.newObject()
        self.wait(for: [expectation], timeout: 0)

        XCTAssertEqual(newObject, changedObject)
        XCTAssertEqual(changeType, .insert)
    }

    func test_newObject_doesntNotifyObserversAnyUpdatesInsideSetupBlock() {
        let expectation = self.expectation(description: "ObserverCalled")
        _ = self.collection.addObserver { _ in
            expectation.fulfill()
        }

        self.collection.newObject() { object in
            object.stringProperty = "Foo"
        }

        self.wait(for: [expectation], timeout: 0)
    }


    //MARK: - delete(_:)
    func test_deleteObject_removesObjectFromCollection() {
        let o1 = self.collection.newObject()
        let o2 = self.collection.newObject()
        let o3 = self.collection.newObject()

        self.collection.delete(o2)

        XCTAssertTrue(self.collection.all.contains(o1))
        XCTAssertFalse(self.collection.all.contains(o2))
        XCTAssertTrue(self.collection.all.contains(o3))
        XCTAssertEqual(self.collection.all.count, 2)
    }

    func test_deleteObject_doesntChangeCollectionIfObjectIsNotInCollection() {
        let o1 = self.collection.newObject()
        let o2 = self.collection.newObject()
        let o3 = self.collection.newObject()

        let o4 = TestCollectableModelObject()

        self.collection.delete(o4)

        XCTAssertTrue(self.collection.all.contains(o1))
        XCTAssertTrue(self.collection.all.contains(o2))
        XCTAssertTrue(self.collection.all.contains(o3))
        XCTAssertEqual(self.collection.all.count, 3)
    }

    func test_deleteObject_notifiesObserversOfChange() {
        self.collection.newObject()
        self.collection.newObject()
        let objectToDelete = self.collection.newObject()

        var changedObject: TestCollectableModelObject? = nil
        var changeType: ModelChangeType? = nil

        let expectation = self.expectation(description: "ObserverCalled")
        _ = self.collection.addObserver { change in
            changedObject = change.object
            changeType = change.changeType
            expectation.fulfill()
        }

        self.collection.delete(objectToDelete)
        self.wait(for: [expectation], timeout: 0)

        XCTAssertEqual(objectToDelete, changedObject)
        XCTAssertEqual(changeType, .delete)
    }


    //MARK: - objectsForRelationship(on:inverseKeyPath:)
    func test_objectsForRelationship_returnsObjectsMatchingInverseRelationship() {
        let parent = self.relationshipCollection.newObject()
        let o1 = self.collection.newObject()
        o1.inverseRelationship = parent
        _ = self.collection.newObject()
        let o3 = self.collection.newObject()
        o3.inverseRelationship = parent

        let relationship = self.collection.objectsForRelationship(on: parent, inverseKeyPath: \.inverseRelationship)

        XCTAssertEqual(relationship.count, 2)
        XCTAssertTrue(relationship.contains(o1))
        XCTAssertTrue(relationship.contains(o3))
    }


    //MARK: - Observation
    func test_observation_notifiesAddedObserversOfChange() {
        let observer1Expectation = self.expectation(description: "Observer 1 Notified")
        _ = self.collection.addObserver { _ in
            observer1Expectation.fulfill()
        }

        let observer2Expectation = self.expectation(description: "Observer 2 Notified")
        _ = self.collection.addObserver { _ in
            observer2Expectation.fulfill()
        }

        self.collection.notifyOfChange(to: TestCollectableModelObject(), changeType: .update, keyPath: \TestCollectableModelObject.intProperty)
        self.wait(for: [observer1Expectation, observer2Expectation], timeout: 0)
    }

    func test_observation_doesntNotifyObserverIfChangedObjectIDNotInFilter() {
        let object = TestCollectableModelObject()

        let observer1Expectation = self.expectation(description: "Observer 1 Notified")
        _ = self.collection.addObserver(filterBy: [object.id]) { _ in
            observer1Expectation.fulfill()
        }

        let observer2Expectation = self.expectation(description: "Observer 2 Notified")
        observer2Expectation.isInverted = true
        _ = self.collection.addObserver(filterBy: [TestCollectableModelObject.modelID(with: UUID())]) { _ in
            observer2Expectation.fulfill()
        }

        self.collection.notifyOfChange(to: object, changeType: .update, keyPath: \TestCollectableModelObject.intProperty)
        self.wait(for: [observer1Expectation, observer2Expectation], timeout: 0.2)
    }

    func test_observation_doesntNotifyObserverIfRemovedBeforeChange() {
        let observer1Expectation = self.expectation(description: "Observer 1 Notified")
        observer1Expectation.isInverted = true
        let observer1 = self.collection.addObserver { _ in
            observer1Expectation.fulfill()
        }

        let observer2Expectation = self.expectation(description: "Observer 2 Notified")
        _ = self.collection.addObserver { _ in
            observer2Expectation.fulfill()
        }

        self.collection.removeObserver(observer1)
        self.collection.notifyOfChange(to: TestCollectableModelObject(), changeType: .update, keyPath: \TestCollectableModelObject.intProperty)
        self.wait(for: [observer1Expectation, observer2Expectation], timeout: 0.2)
    }


    //MARK: - changeGroups
    func test_changeGroups_notifiesObserverImmediatelyAfterEachUpdateIfNoChangeGroupPushed() {
        let newObject = self.collection.newObject()

        let stringExpectation = self.expectation(description: "String Property Changed")
        let stringObserver = self.collection.addObserver { change in
            stringExpectation.fulfill()
        }

        newObject.stringProperty = "Foo"
        self.wait(for: [stringExpectation], timeout: 0)
        self.collection.removeObserver(stringObserver)


        let intExpectation = self.expectation(description: "Int Property Changed")
        let intObserver = self.collection.addObserver { change in
            intExpectation.fulfill()
        }

        newObject.intProperty = 5
        self.wait(for: [intExpectation], timeout: 0)
        self.collection.removeObserver(intObserver)

    }

    func test_changeGroups_doesntNotifyObserverUntilAfterChangeGroupPopped() {
        let newObject = self.collection.newObject()

        self.collection.pushChangeGroup()
        let notCalledExpectation = self.expectation(description: "Not Called")
        notCalledExpectation.isInverted = true
        let notCalledObserver = self.collection.addObserver { change in
            notCalledExpectation.fulfill()
        }

        newObject.stringProperty = "Foo"
        self.wait(for: [notCalledExpectation], timeout: 0)

        self.collection.removeObserver(notCalledObserver)

        let calledExpectation = self.expectation(description: "Observer called")
        _ = self.collection.addObserver { change in
            XCTAssertEqual(change.object, newObject)
            XCTAssertEqual(change.changeType, .update)
            XCTAssertTrue(change.updatedKeyPaths.contains(\TestCollectableModelObject.stringProperty))
            calledExpectation.fulfill()
        }

        self.collection.popChangeGroup()
        self.wait(for: [calledExpectation], timeout: 0)
    }

    func test_changeGroups_onlyNotifiesObserverOnceForMultipleUpdatesIfInChangeGroup() {
        let newObject = self.collection.newObject()


        let expectationExpectation = self.expectation(description: "Observer called")
        _ = self.collection.addObserver { change in
            XCTAssertEqual(change.object, newObject)
            XCTAssertEqual(change.changeType, .update)
            XCTAssertTrue(change.updatedKeyPaths.contains(\TestCollectableModelObject.stringProperty))
            XCTAssertTrue(change.updatedKeyPaths.contains(\TestCollectableModelObject.intProperty))
            expectationExpectation.fulfill()
        }

        self.collection.pushChangeGroup()
        newObject.stringProperty = "Foo"
        newObject.intProperty = 5
        self.collection.popChangeGroup()

        self.wait(for: [expectationExpectation], timeout: 0)
    }


    //MARK: - Undo
    func test_disableUndo_doesntAddAnyUndoRegistrationInBlock() {
        XCTAssertFalse(self.modelController.undoManager.canUndo)
        self.collection.disableUndo {
            self.collection.registerUndoAction { _ in
            }
        }
        XCTAssertFalse(self.modelController.undoManager.canUndo)
    }

    func test_registerUndoAction_registersUndoActionWithControllersUndoManager() {
        XCTAssertFalse(self.modelController.undoManager.canUndo)
        let undoExpectation = self.expectation(description: "Undo Called")
        var undoTarget: ModelCollection<TestCollectableModelObject>?
        self.collection.registerUndoAction { collection in
            undoTarget = collection
            undoExpectation.fulfill()
        }
        XCTAssertTrue(self.modelController.undoManager.canUndo)

        self.modelController.undoManager.undo()
        self.wait(for: [undoExpectation], timeout: 0)

        XCTAssertTrue(undoTarget === self.collection)
    }

    func test_registerUndoAction_setsUndoActionNameToPassedValue() {
        self.collection.registerUndoAction(withName: "Test Name") { collection in
        }

        XCTAssertEqual(self.modelController.undoManager.undoActionName, "Test Name")
    }


    //MARK: - setValue(_:for:ofObjectWithID:)
    func test_setValue_updatesKeyPathOfItemMatchingID() {
        self.collection.newObject()
        let object = self.collection.newObject()
        self.collection.newObject()

        self.collection.setValue("Hello World", for: \.stringProperty, ofObjectWithID: object.id)

        XCTAssertEqual(object.stringProperty, "Hello World")
    }

    func test_setValue_doesntUpdateKeyPathOfObjectIfNotInCollection() {
        let o1 = self.collection.newObject()
        let o2 = self.collection.newObject()
        let o3 = self.collection.newObject()

        let separateObject = TestCollectableModelObject()

        self.collection.setValue("Hello World", for: \.stringProperty, ofObjectWithID: separateObject.id)

        XCTAssertNotEqual(separateObject.stringProperty, "Hello World")
        XCTAssertNotEqual(o1.stringProperty, "Hello World")
        XCTAssertNotEqual(o2.stringProperty, "Hello World")
        XCTAssertNotEqual(o3.stringProperty, "Hello World")
    }


    //MARK: - CollectableModelObject integration
    func test_collectableModelObjectDidChange_notifiesCollectionOfChange() {
        let object = self.collection.newObject()
        object.stringProperty = "Foo"
        let observerExpectation = self.expectation(description: "Observer 1 Notified")
        _ = self.collection.addObserver { _ in
            observerExpectation.fulfill()
        }

        object.didChange(\.stringProperty, oldValue: "Bar")
        wait(for: [observerExpectation], timeout: 0)
    }

    func test_collectableModelObjectDidChange_registersUndoActionToRevertValueChange() {
        let object = self.collection.newObject() {
            $0.stringProperty = "Foo"
        }

        self.modelController.undoManager.removeAllActions() // Clean up
        object.didChange(\.stringProperty, oldValue: "Bar")

        XCTAssertTrue(self.modelController.undoManager.canUndo)

        self.modelController.undoManager.undo()

        XCTAssertEqual(object.stringProperty, "Bar")
    }

    func test_collectableModelObjectDidChangeRelationship_notifiesCollectionOfChange() {
        let parent = self.relationshipCollection.newObject()
        let child1 = self.collection.newObject()
        child1.inverseRelationship = parent
        let observerExpectation = self.expectation(description: "Observer 1 Notified")
        _ = self.collection.addObserver { change in
            XCTAssertEqual(change.object, child1)
            XCTAssertEqual(change.changeType, .update)
            XCTAssertTrue(change.updatedKeyPaths.contains(\TestCollectableModelObject.inverseRelationship))
            observerExpectation.fulfill()
        }

        child1.didChangeRelationship(\.inverseRelationship, inverseKeyPath: \.relationship, oldValue: nil)
        wait(for: [observerExpectation], timeout: 0)
    }

    func test_collectableModelObjectDidChangeRelationship_registersUndoActionToRevertValueChange() {
        let parent = self.relationshipCollection.newObject()
        let child1 = self.collection.newObject()
        child1.inverseRelationship = parent

        self.modelController.undoManager.removeAllActions() // Clean up
        child1.didChangeRelationship(\.inverseRelationship, inverseKeyPath: \.relationship, oldValue: nil)

        XCTAssertTrue(self.modelController.undoManager.canUndo)

        self.modelController.undoManager.undo()

        XCTAssertNil(child1.inverseRelationship)
    }

    func test_collectableModelObjectDidChangeRelationship_notifiesInverseObjectsCollectionOfChangeIfRemovingFromRelationship() {
        let parent = self.relationshipCollection.newObject()
        let child1 = self.collection.newObject()
        let observerExpectation = self.expectation(description: "Observer 1 Notified")
        _ = self.relationshipCollection.addObserver { change in
            XCTAssertEqual(change.object, parent)
            XCTAssertEqual(change.changeType, .update)
            let keyPath = \RelationshipModelObject.relationship
            XCTAssertTrue(change.updatedKeyPaths.contains(keyPath))
            observerExpectation.fulfill()
        }

        child1.didChangeRelationship(\.inverseRelationship, inverseKeyPath: \.relationship, oldValue: parent)
        wait(for: [observerExpectation], timeout: 0)
    }

    func test_collectableModelObjectDidChangeRelationship_notifiesInverseObjectsCollectionOfChangeIfAddingToRelationship() {
        let parent = self.relationshipCollection.newObject()
        let child1 = self.collection.newObject()
        child1.inverseRelationship = parent
        let observerExpectation = self.expectation(description: "Observer 1 Notified")
        _ = self.relationshipCollection.addObserver { change in
            XCTAssertEqual(change.object, parent)
            XCTAssertEqual(change.changeType, .update)
            let keyPath = \RelationshipModelObject.relationship
            XCTAssertTrue(change.updatedKeyPaths.contains(keyPath))
            observerExpectation.fulfill()
        }

        child1.didChangeRelationship(\.inverseRelationship, inverseKeyPath: \.relationship, oldValue: nil)
        wait(for: [observerExpectation], timeout: 0)
    }

    func test_collectableModelObjectRelationshipForKeyPath_fetchesObjectsForRelationshipOnSelfFromCollection() {
        let parent = self.relationshipCollection.newObject()
        let o1 = self.collection.newObject()
        o1.inverseRelationship = parent
        _ = self.collection.newObject()
        let o3 = self.collection.newObject()
        o3.inverseRelationship = parent

        let relationship: Set<TestCollectableModelObject> = parent.relationship(for: \.inverseRelationship)

        XCTAssertEqual(relationship.count, 2)
        XCTAssertTrue(relationship.contains(o1))
        XCTAssertTrue(relationship.contains(o3))
    }


    //MARK: - ModelCollection.Change

    //MARK: - Change.registerChange(ofType:, keyPath:)
    func test_change_registerChange_updatesChangeType() {
        let modelObject = TestCollectableModelObject()
        let change = ModelCollection<TestCollectableModelObject>.Change(object: modelObject)

        change.registerChange(ofType: .insert, keyPath: nil)
        XCTAssertEqual(change.changeType, .insert)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.intProperty)
        XCTAssertEqual(change.changeType, .update)
        change.registerChange(ofType: .delete, keyPath: nil)
        XCTAssertEqual(change.changeType, .delete)
    }

    func test_change_registerChange_insertsKeyPathIfChangeTypeIsUpdate() {
        let modelObject = TestCollectableModelObject()
        let change = ModelCollection<TestCollectableModelObject>.Change(object: modelObject)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.intProperty)

        XCTAssertTrue(change.updatedKeyPaths.contains(\TestCollectableModelObject.intProperty))
    }

    func test_change_registerChange_doesntInsertKeyPathIfChangeTypeIsNotUpdate() {
        let modelObject = TestCollectableModelObject()
        let change = ModelCollection<TestCollectableModelObject>.Change(object: modelObject)
        change.registerChange(ofType: .insert, keyPath: \TestCollectableModelObject.intProperty)

        XCTAssertFalse(change.updatedKeyPaths.contains(\TestCollectableModelObject.intProperty))
    }

    //MARK: - Change.updatedKeyPaths
    func test_change_updatedKeyPaths_returnsKeyPathsIfModelTypeIsUpdate() {
        let modelObject = TestCollectableModelObject()
        let change = ModelCollection<TestCollectableModelObject>.Change(object: modelObject)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.intProperty)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.stringProperty)

        XCTAssertTrue(change.updatedKeyPaths.contains(\TestCollectableModelObject.intProperty))
        XCTAssertTrue(change.updatedKeyPaths.contains(\TestCollectableModelObject.stringProperty))
    }

    func test_change_updatedKeyPaths_returnsEmptySetIfModelTypeIsNotUpdatedEvenIfKeyPathsAreSet() {
        let modelObject = TestCollectableModelObject()
        let change = ModelCollection<TestCollectableModelObject>.Change(object: modelObject)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.intProperty)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.stringProperty)
        change.registerChange(ofType: .insert)

        XCTAssertEqual(change.updatedKeyPaths.count, 0)
    }

    //MARK: - Change.didUpdate(_:)
    func test_change_didUpdateKeyPath_returnsTrueIfKeyPathsContainSuppliedKeyPath() {
        let modelObject = TestCollectableModelObject()
        let change = ModelCollection<TestCollectableModelObject>.Change(object: modelObject)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.intProperty)

        XCTAssertTrue(change.didUpdate(\.intProperty))
    }

    func test_change_didUpdateKeyPath_returnsFalseIfKeyPathsDoesntContainSuppliedKeyPath() {
        let modelObject = TestCollectableModelObject()
        let change = ModelCollection<TestCollectableModelObject>.Change(object: modelObject)
        change.registerChange(ofType: .update, keyPath: \TestCollectableModelObject.intProperty)

        XCTAssertFalse(change.didUpdate(\.stringProperty))
    }
}
