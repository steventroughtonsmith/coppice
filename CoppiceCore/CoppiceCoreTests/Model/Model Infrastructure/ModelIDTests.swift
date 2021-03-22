//
//  ModelIDTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 01/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import CoppiceCore
import XCTest

class ModelIDTests: XCTestCase {
    //MARK: - init?(modelType:uuidString:)
    func test_init_successfullyInitialisesWithValidUUIDString() throws {
        let expectedUUID = UUID()
        let modelID = try XCTUnwrap(ModelID(modelType: ModelType("")!, uuidString: expectedUUID.uuidString))
        XCTAssertEqual(modelID.uuid, expectedUUID)
    }

    func test_init_returnsNilIfUUIDStringInvalid() {
        XCTAssertNil(ModelID(modelType: ModelType("")!, uuidString: "12345"))
    }


    //MARK: - .pasteboardItem
    func test_pasteboardItem_returnsPasteboardItemWithPropertyListForCorrectType() {
        let modelID = ModelID(modelType: ModelType("")!)
        let pasteboardItem = modelID.pasteboardItem

        XCTAssertTrue(pasteboardItem.types.contains(ModelID.PasteboardType))
        XCTAssertNotNil(pasteboardItem.propertyList(forType: ModelID.PasteboardType))
    }


    //MARK: - init?(pasteboardItem:)
    func test_initPasteboardItem_returnsNilIfPasteboardItemDoesntContainModelID() {
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_returnsNilIfPasteboardItemModelIDIsntDictionary() {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList("Test", forType: ModelID.PasteboardType)
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_returnsNilIfUUIDNotInDictionary() {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList(["modelType": ""], forType: ModelID.PasteboardType)
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_returnsNilIfModelTypeNotInDictionary() {
        let pasteboardItem = NSPasteboardItem()
        pasteboardItem.setPropertyList(["uuid": UUID().uuidString], forType: ModelID.PasteboardType)
        XCTAssertNil(ModelID(pasteboardItem: NSPasteboardItem()))
    }

    func test_initPasteboardItem_correctlyInitialisesModelIDFromPasteboardItem() throws {
        let modelID = ModelID(modelType: ModelType("")!)
        let pasteboardItem = modelID.pasteboardItem
        let newModelID = ModelID(pasteboardItem: pasteboardItem)
        XCTAssertEqual(modelID, newModelID)
    }
}
