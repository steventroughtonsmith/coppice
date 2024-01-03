//
//  FolderTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 09/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest

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
        self.modelController = CoppiceModelController(undoManager: UndoManager())
    }


    //MARK: - .dateModified {
    func test_dateModified_returnsDateCreatedIfNothinginFolder() {
        let folder = self.foldersCollection.newObject()
        XCTAssertEqual(folder.dateModified, folder.dateCreated)
    }

    func test_dateModified_returnsDateOfMostRecentlyModifiedContentItem() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject() { $0.dateModified = Date(timeIntervalSinceNow: 200) }
        let object2 = self.foldersCollection.newObject()  { $0.dateCreated = Date(timeIntervalSinceNow: 150) }
        let object3 = self.pagesCollection.newObject()  { $0.dateModified = Date(timeIntervalSinceNow: 300) }

        folder.insert([object1, object2, object3])

        XCTAssertEqual(folder.dateModified, object3.dateModified)
    }


    //MARK: - insert(_:above:)
    func test_insertObjectsBelow_addsObjectsToEmptyFolder() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject()

        folder.insert([object1, object2, object3])

        XCTAssertEqual(folder.folderContents[0].id, object1.id)
        XCTAssertEqual(folder.folderContents[1].id, object2.id)
        XCTAssertEqual(folder.folderContents[2].id, object3.id)
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

        XCTAssertEqual(folder.folderContents[0].id, object1.id)
        XCTAssertEqual(folder.folderContents[1].id, object2.id)
        XCTAssertEqual(folder.folderContents[2].id, object3.id)
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

        XCTAssertEqual(folder.folderContents[2].id, object1.id)
        XCTAssertEqual(folder.folderContents[3].id, object2.id)
        XCTAssertEqual(folder.folderContents[4].id, object3.id)
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

        XCTAssertEqual(folder.folderContents[1].id, object1.id)
        XCTAssertEqual(folder.folderContents[2].id, object2.id)
        XCTAssertEqual(folder.folderContents[3].id, object3.id)
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

        XCTAssertEqual(folder.folderContents[0].containingFolder, folder)
        XCTAssertEqual(folder.folderContents[1].containingFolder, folder)
        XCTAssertEqual(folder.folderContents[2].containingFolder, folder)
        XCTAssertEqual(folder.folderContents[3].containingFolder, folder)
        XCTAssertEqual(folder.folderContents[4].containingFolder, folder)
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

        XCTAssertEqual(oldFolder.folderContents.count, 1)
        XCTAssertFalse(oldFolder.folderContents.contains(where: { $0.id == object1.id }))
        XCTAssertTrue(oldFolder.folderContents.contains(where: { $0.id == object2.id }))
        XCTAssertFalse(oldFolder.folderContents.contains(where: { $0.id == object3.id }))


        XCTAssertEqual(newFolder.folderContents[1].id, object1.id)
        XCTAssertEqual(newFolder.folderContents[2].id, object3.id)

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

        XCTAssertEqual(oldFolder1.folderContents.count, 1)
        XCTAssertFalse(oldFolder1.folderContents.contains(where: { $0.id == object1.id }))
        XCTAssertTrue(oldFolder1.folderContents.contains(where: { $0.id == object2.id }))

        XCTAssertEqual(oldFolder2.folderContents.count, 1)
        XCTAssertFalse(oldFolder2.folderContents.contains(where: { $0.id == object3.id }))
        XCTAssertTrue(oldFolder2.folderContents.contains(where: { $0.id == object4.id }))


        XCTAssertEqual(newFolder.folderContents[1].id, object1.id)
        XCTAssertEqual(newFolder.folderContents[2].id, object3.id)

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

        XCTAssertEqual(folder.folderContents[0].id, existingItem2.id)
        XCTAssertEqual(folder.folderContents[1].id, existingItem4.id)
        XCTAssertEqual(folder.folderContents[2].id, existingItem5.id)
        XCTAssertEqual(folder.folderContents[3].id, existingItem3.id)
        XCTAssertEqual(folder.folderContents[4].id, existingItem1.id)
        XCTAssertEqual(folder.folderContents[5].id, existingItem6.id)
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

        XCTAssertEqual(folder.folderContents[1].id, object1.id)
        XCTAssertEqual(folder.folderContents[2].id, existingItem2.id)
        XCTAssertEqual(folder.folderContents[3].id, object2.id)
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

        XCTAssertEqual(oldFolder1.folderContents.count, 1)
        XCTAssertFalse(oldFolder1.folderContents.contains(where: { $0.id == object1.id }))
        XCTAssertTrue(oldFolder1.folderContents.contains(where: { $0.id == object2.id }))

        XCTAssertEqual(oldFolder2.folderContents.count, 1)
        XCTAssertFalse(oldFolder2.folderContents.contains(where: { $0.id == object3.id }))
        XCTAssertTrue(oldFolder2.folderContents.contains(where: { $0.id == object4.id }))


        XCTAssertEqual(newFolder.folderContents[1].id, object1.id)
        XCTAssertEqual(newFolder.folderContents[2].id, existingObject2.id)
        XCTAssertEqual(newFolder.folderContents[3].id, object3.id)

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

        XCTAssertEqual(folder.folderContents[0].id, object1.id)
        XCTAssertEqual(folder.folderContents[1].id, object3.id)
        XCTAssertEqual(folder.folderContents[2].id, object5.id)
    }


    //MARK: - sort(using:)
    func test_sortUsingMethod_sortsContentsAscendingByTitle() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject() { $0.title = "bee" }
        let object2 = self.foldersCollection.newObject() { $0.title = "ay" }
        let object3 = self.pagesCollection.newObject() { $0.title = "cee" }

        folder.insert([object1, object2, object3])

        folder.sort(using: .title)

        XCTAssertEqual(folder.folderContents[0].id, object2.id)
        XCTAssertEqual(folder.folderContents[1].id, object1.id)
        XCTAssertEqual(folder.folderContents[2].id, object3.id)
    }

    func test_sortUsingMethod_sortsContentsAscendingByType() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject() { $0.content = Page.Content.Image() }
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject() { $0.content = Page.Content.Text() }

        folder.insert([object1, object2, object3])

        folder.sort(using: .type)

        XCTAssertEqual(folder.folderContents[0].id, object2.id)
        XCTAssertEqual(folder.folderContents[1].id, object3.id)
        XCTAssertEqual(folder.folderContents[2].id, object1.id)
    }

    func test_sortUsingMethod_sortsFolderDescendingByDateCreated() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject() { $0.dateCreated = Date(timeIntervalSinceReferenceDate: 29) }
        let object2 = self.foldersCollection.newObject() { $0.dateCreated = Date(timeIntervalSinceReferenceDate: 30) }
        let object3 = self.pagesCollection.newObject() { $0.dateCreated = Date(timeIntervalSinceReferenceDate: 31) }

        folder.insert([object1, object2, object3])

        folder.sort(using: .dateCreated)

        XCTAssertEqual(folder.folderContents[0].id, object3.id)
        XCTAssertEqual(folder.folderContents[1].id, object2.id)
        XCTAssertEqual(folder.folderContents[2].id, object1.id)
    }

    func test_sortUsingMethod_sortsFolderDescendingUsingLastModified() {
        let folder = self.foldersCollection.newObject()

        let object1 = self.pagesCollection.newObject() { $0.dateModified = Date(timeIntervalSinceReferenceDate: 29) }
        let object2 = self.foldersCollection.newObject()
        let object3 = self.pagesCollection.newObject() { $0.dateModified = Date(timeIntervalSinceReferenceDate: 31) }

        let subObject1 = self.pagesCollection.newObject() { $0.dateModified = Date(timeIntervalSinceReferenceDate: 32) }
        object2.insert([subObject1])

        folder.insert([object1, object2, object3])

        folder.sort(using: .lastModified)

        XCTAssertEqual(folder.folderContents[0].id, object2.id)
        XCTAssertEqual(folder.folderContents[1].id, object3.id)
        XCTAssertEqual(folder.folderContents[2].id, object1.id)
    }


    //MARK: - .pathString
    func test_pathString_returnsNilIfUsingRootFolderTitle() throws {
        let rootFolder = self.foldersCollection.newObject() { $0.title = Folder.rootFolderTitle }
        XCTAssertNil(rootFolder.pathString)
    }

    func test_pathString_returnsTitleIfContainedByRootFolder() throws {
        let rootFolder = self.foldersCollection.newObject() { $0.title = Folder.rootFolderTitle }
        let folder = self.foldersCollection.newObject { $0.title = "Hello World" }
        rootFolder.insert([folder])
        XCTAssertEqual(folder.pathString, "Hello World")
    }

    func test_pathString_returnsTitleOfFolderAndParents() throws {
        let rootFolder = self.foldersCollection.newObject() { $0.title = Folder.rootFolderTitle }
        let folder = self.foldersCollection.newObject { $0.title = "Hello World" }
        rootFolder.insert([folder])
        let childFolder = self.foldersCollection.newObject { $0.title = "Foobar" }
        folder.insert([childFolder])
        let grandchildFolder = self.foldersCollection.newObject { $0.title = "Coppice" }
        childFolder.insert([grandchildFolder])
        XCTAssertEqual(grandchildFolder.pathString, "Coppice  ◁  Foobar  ◁  Hello World")
    }


    //MARK: - .plistRepresentation
    func test_plistRepresentation_containsID() throws {
        let folder = Folder()
        XCTAssertEqual(try folder.plistRepresentation[.id], folder.id)
    }

    func test_plistRepresentation_containsTitle() throws {
        let folder = Folder()
        folder.title = "Possum!"
        XCTAssertEqual(try folder.plistRepresentation[Folder.PlistKeys.title], "Possum!")
    }

    func test_plistRepresentation_contentsContents() throws {
        let folder = Folder()
        let object1 = Page()
        let object2 = Page()
        let object3 = Folder()
        folder.folderContents = [object1, object2, object3] as [FolderContainable]

        let contents: [ModelID] = try folder.plistRepresentation[required: Folder.PlistKeys.contents]
        XCTAssertEqual(contents[0], object1.id)
        XCTAssertEqual(contents[1], object2.id)
        XCTAssertEqual(contents[2], object3.id)
    }

    func test_plistRepresentation_includesAnyOtherProperties() throws {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3106),
            ModelPlistKey(rawValue: "foo"): "bar",
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
            ModelPlistKey(rawValue: "baz"): ["hello": "world"],
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist)))

        let plistRepresentation = try folder.plistRepresentation
        XCTAssertEqual(try plistRepresentation[ModelPlistKey(rawValue: "foo")], "bar")
        XCTAssertEqual(try plistRepresentation[ModelPlistKey(rawValue: "baz")], ["hello": "world"])
    }


    //MARK: - update(fromPlistRepresentation:)
    func test_updateFromPlistRepresentation_doesntUpdateIfIDsDontMatch() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: "unknown-folder",
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist))) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .idsDontMatch)
        }
    }

    func test_updatesFromPlistRepresentation_updatesTitle() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3106),
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist)))

        XCTAssertEqual(folder.title, "Cool Pages")
    }

    func test_updatesFromPlistRepresentation_throwsIfTitleMissing() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist))) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("title"))
        }
    }

    func test_updatesFromPlistRepresentation_updatesContents() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3100),
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist)))

        XCTAssertEqual(folder.folderContents[safe: 0]?.id, object1.id)
        XCTAssertEqual(folder.folderContents[safe: 1]?.id, object2.id)
    }

    func test_updatesFromPlistRepresentation_throwsIfContentsMissing() {
        let folder = Folder()

        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3101),
            Folder.PlistKeys.title: "Cool Pages",
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist))) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("contents"))
        }
    }

    func test_updatesFromPlistRepresentation_throwsIfContentsNotArrayOfStrings() {
        XCTFail()
//        let folder = Folder()
//        let plist: [ModelPlistKey: PlistValue] = [
//            .id: folder.id.stringRepresentation,
//            Folder.PlistKeys.title: "Cool Pages",
//            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3101),
//            Folder.PlistKeys.contents: [1, 4, "5"] as [PlistValue],
//        ]
//
//        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist))) {
//            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("contents"))
//        }
    }

    func test_updatesFromPlistRepresentation_throwsIfContentsNotAllModelIDStrings() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3102),
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, "baz", object2.id.stringRepresentation] as [String],
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist))) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("contents"))
        }
    }

    func test_updatesPlistRepresentation_updatesDateCreated() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3106),
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist)))

        XCTAssertEqual(folder.dateCreated.timeIntervalSinceReferenceDate, 3106)
    }

    func test_updatesPlistRepresentation_throwsIfDateCreatedMissing() {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
        ]

        XCTAssertThrowsError(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist))) {
            XCTAssertEqual(($0 as? ModelObjectUpdateErrors), .attributeNotFound("dateCreated"))
        }
    }

    func test_updateFromPlistRepresentation_addsAnythingElseInPlistToOtherProperties() throws {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3106),
            ModelPlistKey(rawValue: "foo"): "bar",
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
            ModelPlistKey(rawValue: "baz"): ["hello": "world"],
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist)))

        XCTAssertEqual(folder.otherProperties[ModelPlistKey(rawValue: "foo")] as? String, "bar")
        XCTAssertEqual(folder.otherProperties[ModelPlistKey(rawValue: "baz")] as? [String: String], ["hello": "world"])
    }

    func test_updateFromPlistRepresentation_doesntIncludeAnySupportPlistKeysInOtherProperties() throws {
        let folder = self.foldersCollection.newObject()
        let object1 = self.pagesCollection.newObject()
        let object2 = self.foldersCollection.newObject()
        let plist: [ModelPlistKey: PlistValue] = [
            .id: folder.id.stringRepresentation,
            Folder.PlistKeys.title: "Cool Pages",
            Folder.PlistKeys.dateCreated: Date(timeIntervalSinceReferenceDate: 3106),
            ModelPlistKey(rawValue: "foo"): "bar",
            Folder.PlistKeys.contents: [object1.id.stringRepresentation, object2.id.stringRepresentation],
            ModelPlistKey(rawValue: "baz"): ["hello": "world"],
        ]

        XCTAssertNoThrow(try folder.update(fromPlistRepresentation: .init(id: folder.id, plist: plist)))
        XCTAssertEqual(folder.otherProperties.count, 2)
        for key in Folder.PlistKeys.all {
            XCTAssertNil(folder.otherProperties[key])
        }
    }
}
