//
//  ModelReaderTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import M3Data
import XCTest

class ModelReaderTests: XCTestCase {
    var testPlist: TestPlists.V2!

    var plistFileWrapper: FileWrapper!
    var contentFileWrapper: FileWrapper!
    var modelController: CoppiceModelController!
    var modelReader: ModelReader!

    override func setUp() {
        super.setUp()

        self.testPlist = TestPlists.V2()

        let plistData = try! PropertyListSerialization.data(fromPropertyList: self.testPlist.plist, format: .xml, options: 0)

        self.plistFileWrapper = FileWrapper(regularFileWithContents: plistData)
        self.contentFileWrapper = FileWrapper(directoryWithFileWrappers: self.testPlist.content.mapValues { FileWrapper(regularFileWithContents: $0) })

        self.modelController = CoppiceModelController(undoManager: UndoManager())
        self.modelReader = ModelReader(modelController: self.modelController, plists: [Plist.V2.self])
    }

    func test_read_createsAllCanvasesFromPlist() {
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let canvases = self.modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.testPlist.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.testPlist.canvasIDs[1])))

        let titles = canvases.map { $0.title }
        XCTAssertTrue(titles.contains("Canvas 1"))
        XCTAssertTrue(titles.contains("Canvas 2"))
    }

    func test_read_createsAllPagesFromPlist() {
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let pages = self.modelController.collection(for: Page.self).all
        XCTAssertEqual(pages.count, 3)

        let ids = pages.map { $0.id }
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[0])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[1])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[2])))

        let titles = pages.map { $0.title }
        XCTAssertTrue(titles.contains("Page 1"))
        XCTAssertTrue(titles.contains("Page 2"))
        XCTAssertTrue(titles.contains("Page 3"))
    }

    func test_read_createsAllCanvasPagesFromPlist() {
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let canvasPages = self.modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 4)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[2])))
    }

    func test_read_createsAllFoldersFromPlist() {
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let folders = self.modelController.collection(for: Folder.self).all
        XCTAssertEqual(folders.count, 2)

        let ids = folders.map { $0.id }
        XCTAssertTrue(ids.contains(Folder.modelID(with: self.testPlist.folderIDs[0])))
        XCTAssertTrue(ids.contains(Folder.modelID(with: self.testPlist.folderIDs[1])))
    }

    func test_read_doesntCreateNewCanvasIfOneAlreadyExistsWithID() {
        self.modelController.collection(for: Canvas.self).newObject() {
            $0.id = Canvas.modelID(with: self.testPlist.canvasIDs[1])
            $0.title = "Foo Bar Baz"
        }

        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let canvases = self.modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.testPlist.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.testPlist.canvasIDs[1])))

        let titles = canvases.map { $0.title }
        XCTAssertTrue(titles.contains("Canvas 1"))
        XCTAssertTrue(titles.contains("Canvas 2"))
    }

    func test_read_doesntCreateNewPageIfOneAlreadyExistsWithID() {
        self.modelController.collection(for: Page.self).newObject() {
            $0.id = Page.modelID(with: self.testPlist.pageIDs[0])
            $0.title = "Hello"
        }

        self.modelController.collection(for: Page.self).newObject() {
            $0.id = Page.modelID(with: self.testPlist.pageIDs[2])
            $0.title = "World"
        }

        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let pages = self.modelController.collection(for: Page.self).all
        XCTAssertEqual(pages.count, 3)

        let ids = pages.map { $0.id }
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[0])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[1])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[2])))

        let titles = pages.map { $0.title }
        XCTAssertTrue(titles.contains("Page 1"))
        XCTAssertTrue(titles.contains("Page 2"))
        XCTAssertTrue(titles.contains("Page 3"))
    }

    func test_read_doesntCreateNewCanvasPageIfOneAlreadyExistsWithID() {
        self.modelController.collection(for: CanvasPage.self).newObject() {
            $0.id = CanvasPage.modelID(with: self.testPlist.canvasPageIDs[1])
        }

        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let canvasPages = self.modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 4)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[2])))
    }

    func test_read_doesntCreatenewFolderIfOneAlreadyExistsWithID() {
        self.modelController.collection(for: Folder.self).newObject() {
            $0.id = Folder.modelID(with: self.testPlist.folderIDs[0])
        }

        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let folders = self.modelController.collection(for: Folder.self).all
        XCTAssertEqual(folders.count, 2)

        let ids = folders.map { $0.id }
        XCTAssertTrue(ids.contains(Folder.modelID(with: self.testPlist.folderIDs[0])))
        XCTAssertTrue(ids.contains(Folder.modelID(with: self.testPlist.folderIDs[1])))
    }

    func test_read_removesAllExtraCanvasesFromModelController() {
        let canvasToRemove = self.modelController.collection(for: Canvas.self).newObject()

        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let canvases = self.modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.testPlist.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.testPlist.canvasIDs[1])))
        XCTAssertFalse(ids.contains(canvasToRemove.id))
    }

    func test_read_removesAllExtraPagesFromModelController() {
        let pageToRemove = self.modelController.collection(for: Page.self).newObject()

        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let pages = self.modelController.collection(for: Page.self).all
        XCTAssertEqual(pages.count, 3)

        let ids = pages.map { $0.id }
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[0])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[1])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.testPlist.pageIDs[2])))
        XCTAssertFalse(ids.contains(pageToRemove.id))
    }

    func test_read_removesAllExtraCanvasPagesFromModelController() {
        let canvasPageToRemove = self.modelController.collection(for: CanvasPage.self).newObject()
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let canvasPages = self.modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 4)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[2])))
        XCTAssertFalse(ids.contains(canvasPageToRemove.id))
    }

    func test_read_removesAllExtraFoldersFromModelController() {
        let folderToRemove = self.modelController.collection(for: Folder.self).newObject()
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let folders = self.modelController.collection(for: Folder.self).all
        XCTAssertEqual(folders.count, 2)

        let ids = folders.map { $0.id }
        XCTAssertTrue(ids.contains(Folder.modelID(with: self.testPlist.folderIDs[0])))
        XCTAssertTrue(ids.contains(Folder.modelID(with: self.testPlist.folderIDs[1])))
        XCTAssertFalse(ids.contains(folderToRemove.id))
    }

    func test_read_allRelationshipsAreCompleted() throws {
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let canvasPage1 = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[0])))
        let canvasPage2 = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[1])))
        let canvasPage3 = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.testPlist.canvasPageIDs[2])))

        let page1 = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.testPlist.pageIDs[0])))
        let page2 = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.testPlist.pageIDs[1])))
        let page3 = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.testPlist.pageIDs[2])))

        let canvas1 = try XCTUnwrap(self.modelController.collection(for: Canvas.self).objectWithID(Canvas.modelID(with: self.testPlist.canvasIDs[0])))
        let canvas2 = try XCTUnwrap(self.modelController.collection(for: Canvas.self).objectWithID(Canvas.modelID(with: self.testPlist.canvasIDs[1])))

        let folder1 = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(Folder.modelID(with: self.testPlist.folderIDs[0])))
        let folder2 = try XCTUnwrap(self.modelController.collection(for: Folder.self).objectWithID(Folder.modelID(with: self.testPlist.folderIDs[1])))

        XCTAssertEqual(canvasPage1.page, page1)
        XCTAssertEqual(canvasPage2.page, page2)
        XCTAssertEqual(canvasPage3.page, page2)

        XCTAssertEqual(canvasPage1.canvas, canvas1)
        XCTAssertEqual(canvasPage2.canvas, canvas1)
        XCTAssertEqual(canvasPage3.canvas, canvas2)

        XCTAssertEqual(canvasPage2.parent, canvasPage1)

        XCTAssertEqual(folder1.contents[safe: 0]?.id, page1.id)
        XCTAssertEqual(page1.containingFolder, folder1)
        XCTAssertEqual(folder1.contents[safe: 1]?.id, folder2.id)
        XCTAssertEqual(folder2.containingFolder, folder1)
        XCTAssertEqual(folder1.contents[safe: 2]?.id, page3.id)
        XCTAssertEqual(page3.containingFolder, folder1)

        XCTAssertEqual(folder2.contents[safe: 0]?.id, page2.id)
        XCTAssertEqual(page2.containingFolder, folder2)
    }

    func test_read_allContentIsReadFromDisk() {
        XCTAssertNoThrow(try self.modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper))

        let textPage = self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.testPlist.pageIDs[0]))
        XCTAssertEqual(textPage?.content.contentType, .text)
        XCTAssertEqual((textPage?.content as? TextPageContent)?.text.string, "Foo Bar")

        let imagePage = self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.testPlist.pageIDs[2]))
        XCTAssertEqual(imagePage?.content.contentType, .image)
        //We need to convert to data and back to ensure the resulting pngData is always equal
        let imageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let image = NSImage(data: imageData)!
        XCTAssertEqual((imagePage?.content as? ImagePageContent)?.image?.pngData(), image.pngData())
        XCTAssertEqual((imagePage?.content as? ImagePageContent)?.imageDescription, "This is an image")
    }


    //MARK: - Errors
    func test_errors_throwsCorruptDataErrorIfDataPlistExistsButIsEmpty() {
        do {
            try self.modelReader.read(plistWrapper: FileWrapper(regularFileWithContents: Data()),
                                      contentWrapper: FileWrapper(directoryWithFileWrappers: [:]))
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.invalidPlist {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsCorruptDataErrorIfPlistCannotBeDecoded() {
        do {
            try self.modelReader.read(plistWrapper: FileWrapper(regularFileWithContents: "abcdefgh".data(using: .utf8)!),
                                      contentWrapper: FileWrapper(directoryWithFileWrappers: [:]))
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.invalidPlist {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsVersionTooNewErrorIfPlistVersionIsGreaterThanDocumentVersion() throws {
        let modelReader = ModelReader(modelController: modelController, plists: [V1Plist.self])
        do {
            try modelReader.read(plistWrapper: self.plistFileWrapper, contentWrapper: self.contentFileWrapper)
        } catch ModelReader.Errors.versionNotSupported {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsModelObjectUpdateErrorIfCanvasUpdateFailed() {
        let plist: [String: Any] = [
            "canvases": [
                ["id": Canvas.modelID(with: UUID()).stringRepresentation],
            ],
            "pages": [],
            "canvasPages": [],
            "folders": [],
            "version": 2,//Plist.allPlists.last!.version,
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        do {
            try self.modelReader.read(plistWrapper: FileWrapper(regularFileWithContents: plistData), contentWrapper: FileWrapper(directoryWithFileWrappers: [:]))
            XCTFail("Error not thrown")
        } catch ModelObjectUpdateErrors.attributeNotFound {
            //Passes
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsModelObjectUpdateErrorIfPageUpdateFailed() {
        let plist: [String: Any] = [
            "canvases": [],
            "pages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation],
            ],
            "canvasPages": [],
            "folders": [],
            "version": 2,//Plist.allPlists.last!.version,
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        do {
            try self.modelReader.read(plistWrapper: FileWrapper(regularFileWithContents: plistData), contentWrapper: FileWrapper(directoryWithFileWrappers: [:]))
            XCTFail("Error not thrown")
        } catch ModelObjectUpdateErrors.attributeNotFound {
            //Passes
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsModelObjectUpdateErrorIfCanvasPageUpdateFailed() {
        let plist: [String: Any] = [
            "canvases": [],
            "pages": [],
            "canvasPages": [
                ["id": CanvasPage.modelID(with: UUID()).stringRepresentation],
            ],
            "folders": [],
            "version": 2,//Plist.allPlists.last!.version,
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        do {
            try self.modelReader.read(plistWrapper: FileWrapper(regularFileWithContents: plistData), contentWrapper: FileWrapper(directoryWithFileWrappers: [:]))
            XCTFail("Error not thrown")
        } catch ModelObjectUpdateErrors.attributeNotFound {
            //Passes
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsModelObjectUpdateErrorIfFolderUpdateFailed() {
        let plist: [String: Any] = [
            "canvases": [],
            "pages": [],
            "canvasPages": [],
            "folders": [
                ["id": Folder.modelID(with: UUID()).stringRepresentation],
            ],
            "version": 2,//Plist.allPlists.last!.version,
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        do {
            try self.modelReader.read(plistWrapper: FileWrapper(regularFileWithContents: plistData), contentWrapper: FileWrapper(directoryWithFileWrappers: [:]))
            XCTFail("Error not thrown")
        } catch ModelObjectUpdateErrors.attributeNotFound {
            //Passes
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }
}

fileprivate class V1Plist: M3Data.ModelPlist {
    override class var version: Int {
        return 1
    }

    override class var supportedTypes: [M3Data.ModelPlist.PersistenceTypes] {
        return []
    }
}
