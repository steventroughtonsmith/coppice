//
//  ModelReaderTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 28/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class ModelReaderTests: XCTestCase {

    var canvasIDs: [UUID]!
    var plistCanvases: [[String: Any]]!
    var pageIDs: [UUID]!
    var plistPages: [[String: Any]]!
    var canvasPageIDs: [UUID]!
    var plistCanvasPages: [[String: Any]]!

    var content: [String: Data]!

    var testFileWrapper: FileWrapper!

    override func setUp() {
        super.setUp()

        self.canvasIDs = [UUID(), UUID()]
        self.plistCanvases = [
            [
                "id": Canvas.modelID(with: self.canvasIDs[0]).stringRepresentation,
                "title": "Canvas 1",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 30),
                "dateModified": Date(timeIntervalSinceReferenceDate: 300),
                "sortIndex": 2,
                "viewPort": NSStringFromRect(CGRect(x: 10, y: 20, width: 30, height: 40))
            ],
            [
                "id": Canvas.modelID(with: self.canvasIDs[1]).stringRepresentation,
                "title": "Canvas 2",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 42),
                "dateModified": Date(timeIntervalSinceReferenceDate: 42),
                "sortIndex": 1
            ],
        ]

        self.pageIDs = [UUID(), UUID(), UUID()]
        self.plistPages = [
            [
                "id": Page.modelID(with: self.pageIDs[0]).stringRepresentation,
                "title": "Page 1",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 123),
                "dateModified": Date(timeIntervalSinceReferenceDate: 456),
                "content": ["type": "text", "filename": "\(self.pageIDs[0].uuidString).rtf"]
            ],
            [
                "id": Page.modelID(with: self.pageIDs[1]).stringRepresentation,
                "title": "Page 2",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 0),
                "dateModified": Date(timeIntervalSinceReferenceDate: 0),
                "userPreferredSize": NSStringFromSize(CGSize(width: 1024, height: 768)),
                "content": ["type": "empty"]
            ],
            [
                "id": Page.modelID(with: self.pageIDs[2]).stringRepresentation,
                "title": "Page 3",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 999),
                "dateModified": Date(timeIntervalSinceReferenceDate: 9999),
                "content": ["type": "image", "filename": "\(self.pageIDs[2].uuidString).png"]
            ]
        ]

        self.canvasPageIDs = [UUID(), UUID(), UUID()]
        self.plistCanvasPages = [
            [
                "id": CanvasPage.modelID(with: self.canvasPageIDs[0]).stringRepresentation,
                "frame": NSStringFromRect(CGRect(x: 0, y: 1, width: 2, height: 3)),
                "page": Page.modelID(with: self.pageIDs[0]).stringRepresentation,
                "canvas": Canvas.modelID(with: self.canvasIDs[0]).stringRepresentation
            ],
            [
                "id": CanvasPage.modelID(with: self.canvasPageIDs[1]).stringRepresentation,
                "frame": NSStringFromRect(CGRect(x: 30, y: 50, width: 200, height: 400)),
                "page": Page.modelID(with: self.pageIDs[1]).stringRepresentation,
                "canvas": Canvas.modelID(with: self.canvasIDs[0]).stringRepresentation,
                "parent": CanvasPage.modelID(with: self.canvasPageIDs[0]).stringRepresentation
            ],
            [
                "id": CanvasPage.modelID(with: self.canvasPageIDs[2]).stringRepresentation,
                "frame": NSStringFromRect(CGRect(x: -30, y: -2, width: 600, height: 40)),
                "page": Page.modelID(with: self.pageIDs[1]).stringRepresentation,
                "canvas": Canvas.modelID(with: self.canvasIDs[1]).stringRepresentation
            ]
        ]

        self.content = [
            "\(self.pageIDs[0].uuidString).rtf": try! NSAttributedString(string: "Foo Bar").data(from: NSRange(location: 0, length: 7), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf]),
            "\(self.pageIDs[2].uuidString).png": NSImage(named: "NSAddTemplate")!.pngData()!,
        ]


        let plist = [
            "canvases": self.plistCanvases,
            "pages": self.plistPages,
            "canvasPages": self.plistCanvasPages
        ]

        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        self.testFileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: self.content.mapValues { FileWrapper(regularFileWithContents: $0) })
        ])
    }

    func test_read_createsAllCanvasesFromPlist() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let canvases = modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[1])))

        let titles = canvases.map { $0.title }
        XCTAssertTrue(titles.contains("Canvas 1"))
        XCTAssertTrue(titles.contains("Canvas 2"))
    }

    func test_read_createsAllPagesFromPlist() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let pages = modelController.collection(for: Page.self).all
        XCTAssertEqual(pages.count, 3)

        let ids = pages.map { $0.id }
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[0])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[1])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[2])))

        let titles = pages.map { $0.title }
        XCTAssertTrue(titles.contains("Page 1"))
        XCTAssertTrue(titles.contains("Page 2"))
        XCTAssertTrue(titles.contains("Page 3"))
    }

    func test_read_createsAllCanvasPagesFromPlist() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let canvasPages = modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 3)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[2])))
    }

    func test_read_doesntCreateNewCanvasIfOneAlreadyExistsWithID() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        modelController.collection(for: Canvas.self).newObject() {
            $0.id = Canvas.modelID(with: self.canvasIDs[1])
            $0.title = "Foo Bar Baz"
        }

        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let canvases = modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[1])))

        let titles = canvases.map { $0.title }
        XCTAssertTrue(titles.contains("Canvas 1"))
        XCTAssertTrue(titles.contains("Canvas 2"))
    }

    func test_read_doesntCreateNewPageIfOneAlreadyExistsWithID() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        modelController.collection(for: Page.self).newObject() {
            $0.id = Page.modelID(with: self.pageIDs[0])
            $0.title = "Hello"
        }

        modelController.collection(for: Page.self).newObject() {
            $0.id = Page.modelID(with: self.pageIDs[2])
            $0.title = "World"
        }

        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let pages = modelController.collection(for: Page.self).all
        XCTAssertEqual(pages.count, 3)

        let ids = pages.map { $0.id }
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[0])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[1])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[2])))

        let titles = pages.map { $0.title }
        XCTAssertTrue(titles.contains("Page 1"))
        XCTAssertTrue(titles.contains("Page 2"))
        XCTAssertTrue(titles.contains("Page 3"))
    }

    func test_read_doesntCreateNewCanvasPageIfOneAlreadyExistsWithID() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        modelController.collection(for: CanvasPage.self).newObject() {
            $0.id = CanvasPage.modelID(with: self.canvasPageIDs[1])
        }

        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let canvasPages = modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 3)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[2])))
    }

    func test_read_removesAllExtraCanvasesFromModelController() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvasToRemove = modelController.collection(for: Canvas.self).newObject()

        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let canvases = modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[1])))
        XCTAssertFalse(ids.contains(canvasToRemove.id))
    }

    func test_read_removesAllExtraPagesFromModelController() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let pageToRemove = modelController.collection(for: Page.self).newObject()

        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let pages = modelController.collection(for: Page.self).all
        XCTAssertEqual(pages.count, 3)

        let ids = pages.map { $0.id }
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[0])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[1])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[2])))
        XCTAssertFalse(ids.contains(pageToRemove.id))
    }

    func test_read_removesAllExtraCanvasPagesFromModelController() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let canvasPageToRemove = modelController.collection(for: CanvasPage.self).newObject()

        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let canvasPages = modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 3)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[2])))
        XCTAssertFalse(ids.contains(canvasPageToRemove.id))
    }

    func test_read_allRelationshipsAreCompleted() throws {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let canvasPage1 = try XCTUnwrap(modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        let canvasPage2 = try XCTUnwrap(modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        let canvasPage3 = try XCTUnwrap(modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.canvasPageIDs[2])))

        let page1 = try XCTUnwrap(modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[0])))
        let page2 = try XCTUnwrap(modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[1])))

        let canvas1 = try XCTUnwrap(modelController.collection(for: Canvas.self).objectWithID(Canvas.modelID(with: self.canvasIDs[0])))
        let canvas2 = try XCTUnwrap(modelController.collection(for: Canvas.self).objectWithID(Canvas.modelID(with: self.canvasIDs[1])))

        XCTAssertEqual(canvasPage1.page, page1)
        XCTAssertEqual(canvasPage2.page, page2)
        XCTAssertEqual(canvasPage3.page, page2)

        XCTAssertEqual(canvasPage1.canvas, canvas1)
        XCTAssertEqual(canvasPage2.canvas, canvas1)
        XCTAssertEqual(canvasPage3.canvas, canvas2)

        XCTAssertEqual(canvasPage2.parent, canvasPage1)
    }

    func test_read_allContentIsReadFromDisk() {
        let modelController = BubblesModelController(undoManager: UndoManager())
        let modelReader = ModelReader(modelController: modelController)
        modelReader.read(self.testFileWrapper)

        let textPage = modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[0]))
        XCTAssertEqual(textPage?.content.contentType, .text)
        XCTAssertEqual((textPage?.content as? TextPageContent)?.text.string, "Foo Bar")

        let imagePage = modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[2]))
        XCTAssertEqual(imagePage?.content.contentType, .image)
        //We need to convert to data and back to ensure the resulting pngData is always equal
        let imageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let image = NSImage(data: imageData)!
        XCTAssertEqual((imagePage?.content as? ImagePageContent)?.image?.pngData(), image.pngData())
    }


    //MARK: - Helpers


}
