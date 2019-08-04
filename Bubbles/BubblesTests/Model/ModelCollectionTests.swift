//
//  ModelCollectionTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 02/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class ModelCollectionTests: XCTestCase {
    var collection: ModelCollection<TestCollectableModelObject>!
    var modelController: TestModelController!

    override func setUp() {
        super.setUp()

        self.collection = ModelCollection<TestCollectableModelObject>()
        self.modelController = TestModelController()
        self.modelController.add(collection, for: TestCollectableModelObject.modelType)
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

    func test_newObject_notifiesObserversOfChange() {
        var changedObject: TestCollectableModelObject? = nil

        let expectation = self.expectation(description: "ObserverCalled")
        _ = self.collection.addObserver { (object) in
            changedObject = object
            expectation.fulfill()
        }

        let newObject = self.collection.newObject()
        self.wait(for: [expectation], timeout: 0)

        XCTAssertEqual(newObject, changedObject)
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

        let expectation = self.expectation(description: "ObserverCalled")
        _ = self.collection.addObserver { (object) in
            changedObject = object
            expectation.fulfill()
        }

        self.collection.delete(objectToDelete)
        self.wait(for: [expectation], timeout: 0)

        XCTAssertEqual(objectToDelete, changedObject)
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

        self.collection.notifyOfChange(to: TestCollectableModelObject())
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

        self.collection.notifyOfChange(to: object)
        self.wait(for: [observer1Expectation, observer2Expectation], timeout: 1)
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
        self.collection.notifyOfChange(to: TestCollectableModelObject())
        self.wait(for: [observer1Expectation, observer2Expectation], timeout: 1)
    }


    //MARK: - Undo
    func test_disableUndo_doesntAddAnyUndoRegistrationInBlock() {
        XCTFail()
    }

    func test_registerUndoAction_registersUndoActionWithControllersUndoManager() {
        XCTFail()
    }

    func test_registerUndoAction_setsUndoActionNameToPassedValue() {
        XCTFail()
    }


    //MARK: - setValue(_:for:ofObjectWithID:)
    func test_setValue_updatesKeyPathOfItemMatchingID() {
        XCTFail()
    }

    func test_setValue_doesntUpdateKeyPathOfObjectIfNotInCollection() {
        XCTFail()
    }


    //MARK: - CollectableModelObject integration
    func test_collectableModelObjectDidChange_notifiesCollectionOfChange() {
        XCTFail()
    }

    func test_collectableModelObjectDidChange_registersUndoActionToRevertValueChange() {
        XCTFail()
    }

    func test_collectableModelObjectRelationshipForKeyPath_fetchesObjectsForRelationshipOnSelfFromCollection() {
        XCTFail()
    }

}
