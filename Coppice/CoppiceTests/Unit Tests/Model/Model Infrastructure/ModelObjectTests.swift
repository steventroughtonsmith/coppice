//
//  ModelObjectTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class ModelObjectTests: XCTestCase {
    var modelController: TestModelController!
    var modelCollection: ModelCollection<TestCollectableModelObject>!

    override func setUp() {
        super.setUp()
        self.modelController = TestModelController()
        self.modelCollection = ModelCollection<TestCollectableModelObject>()
        self.modelCollection.modelController = self.modelController
    }

    override func tearDown() {
        super.tearDown()
        self.modelController = nil
        self.modelCollection = nil
    }

    //MARK: - ModelObject
    func test_modelIDWithUUID_returnsModelIDWithObjectsTypeAndSuppliedUUID() {
        let expectedUUID = UUID()
        let modelID = TestModelObject.modelID(with: expectedUUID)
        XCTAssertEqual(modelID.uuid, expectedUUID)
        XCTAssertEqual(modelID.modelType, TestModelObject.modelType)
    }

    func test_modelIDWithUUIDString_returnsModelIDWithObjectsTypeAndUUIDFromSuppliedString() throws{
        let expectedUUID = UUID()
        let modelID = try XCTUnwrap(TestModelObject.modelID(withUUIDString: expectedUUID.uuidString))
        XCTAssertEqual(modelID.uuid, expectedUUID)
        XCTAssertEqual(modelID.modelType, TestModelObject.modelType)
    }

    func test_modelIDWithUUIDString_returnsNilIfSuppliedStringIsNotUUID() {
        XCTAssertNil(TestModelObject.modelID(withUUIDString: ""))
    }


    //MARK: - CollectableModelObject.modelController
    func test_modelController_returnsCollectionsModelController() {
        let model = TestCollectableModelObject()
        model.collection = self.modelCollection

        XCTAssertEqual((model.modelController as! TestModelController), self.modelController)
    }


    //MARK: - Model File
    func test_modelFile_plistRepresentation() throws {
        let modelFile = ModelFile(type: "FileType", filename: "myfile.txt", data: nil, metadata: ["key": "value", "number": 42])

        let plistRepresentation = modelFile.plistRepresentation
        XCTAssertEqual(plistRepresentation["type"] as? String, "FileType")
        XCTAssertEqual(plistRepresentation["filename"] as? String, "myfile.txt")

        let metadataPlist = try XCTUnwrap(plistRepresentation["metadata"] as? [String: Any])
        XCTAssertEqual(metadataPlist["key"] as? String, "value")
        XCTAssertEqual(metadataPlist["number"] as? Int, 42)
    }
}
