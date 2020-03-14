//
//  FolderTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 09/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class FolderTests: XCTestCase {

    var modelController: ModelController!
    var foldersCollection: ModelCollection<Folder> {
        return self.modelController.collection(for: Folder.self)
    }
    var pagesCollection: ModelCollection<Page> {
        return self.modelController.collection(for: Page.self)
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        self.modelController = BubblesModelController(undoManager: UndoManager())
    }


    //MARK: - insert(_:above:)
    func test_insertObjectsBelow_addsObjectsToEmptyFolder() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject()

        folder.insert([object1, object2, object3])

        XCTAssertEqual(folder.contents[0].id, object1.id)
        XCTAssertEqual(folder.contents[1].id, object2.id)
        XCTAssertEqual(folder.contents[2].id, object3.id)
    }

    func test_insertObjectsBelow_addsObjectsToTopOfFolderIfItemIsNil() {
        let folder = self.foldersCollection.newObject()

        let existingItem1 = self.pagesCollection.newObject()
        let existingItem2 = self.foldersCollection.newObject()
        folder.insert([existingItem1, existingItem2])

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject()

        folder.insert([object1, object2, object3], below: nil)

        XCTAssertEqual(folder.contents[0].id, object1.id)
        XCTAssertEqual(folder.contents[1].id, object2.id)
        XCTAssertEqual(folder.contents[2].id, object3.id)
    }

    func test_insertObjectsBelow_addsObjectsToEndOfFolderIfItemIsLastItem() {
        let folder = self.foldersCollection.newObject()

        let existingItem1 = self.pagesCollection.newObject()
        let existingItem2 = self.foldersCollection.newObject()
        folder.insert([existingItem1, existingItem2])

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject()

        folder.insert([object1, object2, object3], below: existingItem2)

        XCTAssertEqual(folder.contents[2].id, object1.id)
        XCTAssertEqual(folder.contents[3].id, object2.id)
        XCTAssertEqual(folder.contents[4].id, object3.id)
    }

    func test_insertObjectsBelow_insertsObjectsBelowSuppliedItem() {
        let folder = self.foldersCollection.newObject()

        let existingItem1 = self.pagesCollection.newObject()
        let existingItem2 = self.foldersCollection.newObject()
        folder.insert([existingItem1, existingItem2])

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject()

        folder.insert([object1, object2, object3], below: existingItem1)

        XCTAssertEqual(folder.contents[1].id, object1.id)
        XCTAssertEqual(folder.contents[2].id, object2.id)
        XCTAssertEqual(folder.contents[3].id, object3.id)
    }

    func test_insertObjectsBelow_setsContainingFolderOfInsertedItemsToReceiver() {
        let folder = self.foldersCollection.newObject()

        let existingItem1 = self.pagesCollection.newObject()
        let existingItem2 = self.foldersCollection.newObject()
        folder.insert([existingItem1, existingItem2])

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject()

        folder.insert([object1, object2, object3], below: nil)

        XCTAssertEqual(folder.contents[0].containingFolder, folder)
        XCTAssertEqual(folder.contents[1].containingFolder, folder)
        XCTAssertEqual(folder.contents[2].containingFolder, folder)
        XCTAssertEqual(folder.contents[3].containingFolder, folder)
        XCTAssertEqual(folder.contents[4].containingFolder, folder)
    }

    func test_insertObjectsBelow_ifObjectsAlreadyInADifferentFolderRemovesFromThatFolder() {
        let oldFolder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.pagesCollection.newObject()
        let object3 = self.foldersCollection.newObject()
        oldFolder.insert([object1, object2, object3])

        let newFolder = self.foldersCollection.newObject()
        let existingObject1 = self.pagesCollection.newObject()
        let existingObject2 = self.foldersCollection.newObject()
        newFolder.insert([existingObject1, existingObject2])

        newFolder.insert([object1, object3], below: existingObject1)

        XCTAssertEqual(oldFolder.contents.count, 1)
        XCTAssertFalse(oldFolder.contents.contains(where: {$0.id == object1.id}))
        XCTAssertTrue(oldFolder.contents.contains(where: {$0.id == object2.id}))
        XCTAssertFalse(oldFolder.contents.contains(where: {$0.id == object3.id}))


        XCTAssertEqual(newFolder.contents[1].id, object1.id)
        XCTAssertEqual(newFolder.contents[2].id, object3.id)

        XCTAssertEqual(object1.containingFolder, newFolder)
        XCTAssertEqual(object3.containingFolder, newFolder)
    }

    func test_insertObjectsBelow_ifObjectsInSeveralDifferentFoldersRemovesFromAllThoseFolders() {
        let oldFolder1 = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.pagesCollection.newObject()
        oldFolder1.insert([object1, object2])

        let oldFolder2 = self.foldersCollection.newObject()
        let object3 = self.foldersCollection.newObject()
        let object4 = self.pagesCollection.newObject()
        oldFolder2.insert([object3, object4])

        let newFolder = self.foldersCollection.newObject()
        let existingObject1 = self.pagesCollection.newObject()
        let existingObject2 = self.foldersCollection.newObject()
        newFolder.insert([existingObject1, existingObject2])

        newFolder.insert([object1, object3], below: existingObject1)

        XCTAssertEqual(oldFolder1.contents.count, 1)
        XCTAssertFalse(oldFolder1.contents.contains(where: {$0.id == object1.id}))
        XCTAssertTrue(oldFolder1.contents.contains(where: {$0.id == object2.id}))

        XCTAssertEqual(oldFolder2.contents.count, 1)
        XCTAssertFalse(oldFolder2.contents.contains(where: {$0.id == object3.id}))
        XCTAssertTrue(oldFolder2.contents.contains(where: {$0.id == object4.id}))


        XCTAssertEqual(newFolder.contents[1].id, object1.id)
        XCTAssertEqual(newFolder.contents[2].id, object3.id)

        XCTAssertEqual(object1.containingFolder, newFolder)
        XCTAssertEqual(object3.containingFolder, newFolder)
    }

    func test_insertObjectsBelow_ifObjectsInReceiverInsertsBelowSuppliedItem() {
        let folder = self.foldersCollection.newObject()

        let existingItem1 = self.pagesCollection.newObject()
        let existingItem2 = self.foldersCollection.newObject()
        let existingItem3 = self.pagesCollection.newObject()
        let existingItem4 = self.pagesCollection.newObject()
        let existingItem5 = self.foldersCollection.newObject()
        let existingItem6 = self.foldersCollection.newObject()
        folder.insert([existingItem1, existingItem2, existingItem3, existingItem4, existingItem5, existingItem6])

        folder.insert([existingItem3, existingItem1], below: existingItem5)

        XCTAssertEqual(folder.contents[0].id, existingItem2.id)
        XCTAssertEqual(folder.contents[1].id, existingItem4.id)
        XCTAssertEqual(folder.contents[2].id, existingItem5.id)
        XCTAssertEqual(folder.contents[3].id, existingItem3.id)
        XCTAssertEqual(folder.contents[4].id, existingItem1.id)
        XCTAssertEqual(folder.contents[5].id, existingItem6.id)
    }

    func test_insertObjectsBelow_ifObjectsInReceiverAndSuppliedItemIsOneOfObjectsInsertsBelowSuppliedItemsPreviousIndex() {
        let folder = self.foldersCollection.newObject()

        let existingItem1 = self.pagesCollection.newObject()
        let existingItem2 = self.foldersCollection.newObject()
        let existingItem3 = self.pagesCollection.newObject()
        folder.insert([existingItem1, existingItem2, existingItem3])

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()

        folder.insert([object1, existingItem2, object2], below: existingItem2)

        XCTAssertEqual(folder.contents[1].id, object1.id)
        XCTAssertEqual(folder.contents[2].id, existingItem2.id)
        XCTAssertEqual(folder.contents[3].id, object2.id)
    }

    func test_insertObjectsBelow_ifObjectsFromAMixOfPlacesRemovesFromOtherFoldersAndInsertsBelowSuppliedItem() {
        let oldFolder1 = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.pagesCollection.newObject()
        oldFolder1.insert([object1, object2])

        let oldFolder2 = self.foldersCollection.newObject()
        let object3 = self.foldersCollection.newObject()
        let object4 = self.pagesCollection.newObject()
        oldFolder2.insert([object3, object4])

        let newFolder = self.foldersCollection.newObject()
        let existingObject1 = self.pagesCollection.newObject()
        let existingObject2 = self.foldersCollection.newObject()
        let existingObject3 = self.pagesCollection.newObject()
        newFolder.insert([existingObject1, existingObject2, existingObject3])

        newFolder.insert([object1, existingObject2, object3], below: existingObject1)

        XCTAssertEqual(oldFolder1.contents.count, 1)
        XCTAssertFalse(oldFolder1.contents.contains(where: {$0.id == object1.id}))
        XCTAssertTrue(oldFolder1.contents.contains(where: {$0.id == object2.id}))

        XCTAssertEqual(oldFolder2.contents.count, 1)
        XCTAssertFalse(oldFolder2.contents.contains(where: {$0.id == object3.id}))
        XCTAssertTrue(oldFolder2.contents.contains(where: {$0.id == object4.id}))


        XCTAssertEqual(newFolder.contents[1].id, object1.id)
        XCTAssertEqual(newFolder.contents[2].id, existingObject2.id)
        XCTAssertEqual(newFolder.contents[3].id, object3.id)

        XCTAssertEqual(object1.containingFolder, newFolder)
        XCTAssertEqual(existingObject2.containingFolder, newFolder)
        XCTAssertEqual(object3.containingFolder, newFolder)
    }


    //MARK: - remove(_:)
    func test_removeObjects() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject()
        let object4 = self.pagesCollection.newObject()
        let object5 = self.pagesCollection.newObject()

        folder.insert([object1, object2, object3, object4, object5])

        folder.remove([object2, object4])

        XCTAssertEqual(folder.contents[0].id, object1.id)
        XCTAssertEqual(folder.contents[1].id, object3.id)
        XCTAssertEqual(folder.contents[2].id, object5.id)
    }



    //MARK: - .plistRepresentation
    func test_plistRepresentation_containsID() throws {
        let folder = Folder()
        let id = try XCTUnwrap(folder.plistRepresentation["id"] as? String)
        XCTAssertEqual(id, folder.id.stringRepresentation)
    }

    func test_plistRepresentation_containsTitle() throws {
        let folder = Folder()
        folder.title = "Possum!"
        let title = try XCTUnwrap(folder.plistRepresentation["title"] as? String)
        XCTAssertEqual(title, "Possum!")
    }

    func test_plistRepresentation_contentsContents() throws {
        let folder = Folder()
        let object1 = Page()
        let object2 = Page()
        let object3 = Folder()
        folder.contents = [object1, object2, object3] as [FolderContainable]

        let contents = try XCTUnwrap(folder.plistRepresentation["contents"] as? [String])
        XCTAssertEqual(contents[0], object1.id.stringRepresentation)
        XCTAssertEqual(contents[1], object2.id.stringRepresentation)
        XCTAssertEqual(contents[2], object3.id.stringRepresentation)
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [String: Any] = [
            "id": "unknown-folder",
            "title": "Cool Pages",
            "contents": [object1.id.stringRepresentation, object2.id.stringRepresentation]
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: plist)) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .idsDontMatch)
        }
    }

    func test_updatesFromPlistRepresentation_updatesTitle() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [String: Any] = [
            "id": folder.id.stringRepresentation,
            "title": "Cool Pages",
            "contents": [object1.id.stringRepresentation, object2.id.stringRepresentation]
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: plist))

        XCTAssertEqual(folder.title, "Cool Pages")
    }

    func test_updatesFromPlistRepresentation_throwsIfTitleMissing() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [String: Any] = [
            "id": folder.id.stringRepresentation,
            "contents": [object1.id.stringRepresentation, object2.id.stringRepresentation]
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: plist)) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("title"))
        }
    }

    func test_updatesFromPlistRepresentation_updatesContents() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [String: Any] = [
            "id": folder.id.stringRepresentation,
            "title": "Cool Pages",
            "contents": [object1.id.stringRepresentation, object2.id.stringRepresentation]
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: plist))

        XCTAssertEqual(folder.contents[0].id, object1.id)
        XCTAssertEqual(folder.contents[1].id, object2.id)
    }

    func test_updatesFromPlistRepresentation_throwsIfContentsMissing() {
        let folder = Folder()

        let plist: [String: Any] = [
            "id": folder.id.stringRepresentation,
            "title": "Cool Pages",
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: plist)) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("contents"))
        }
    }

    func test_updatesFromPlistRepresentation_throwsIfContentsNotArrayOfStrings() {
        let folder = Folder()
        let plist: [String: Any] = [
            "id": folder.id.stringRepresentation,
            "title": "Cool Pages",
            "contents": [1, 4, "5"]
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: plist)) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("contents"))
        }
    }

    func test_updatesFromPlistRepresentation_throwsIfContentsNotAllModelIDStrings() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [String: Any] = [
            "id": folder.id.stringRepresentation,
            "title": "Cool Pages",
            "contents": [object1.id.stringRepresentation, "baz", object2.id.stringRepresentation]
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: plist)) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("contents"))
        }
    }
}
