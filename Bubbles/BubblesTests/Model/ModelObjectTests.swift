//
//  ModelObjectTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class TestModelObject: ModelObject {
    static var modelType: ModelType = ModelType("Test")!

    var id = ModelID(modelType: TestModelObject.modelType)

    var modelController: ModelController?
}

class ModelObjectTests: XCTestCase {

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
}
