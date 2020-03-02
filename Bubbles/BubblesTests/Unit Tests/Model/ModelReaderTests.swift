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
    var modelController: BubblesModelController!
    var modelReader: ModelReader!

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
                "theme": "auto",
                "viewPort": NSStringFromRect(CGRect(x: 10, y: 20, width: 30, height: 40))
            ],
            [
                "id": Canvas.modelID(with: self.canvasIDs[1]).stringRepresentation,
                "title": "Canvas 2",
                "dateCreated": Date(timeIntervalSinceReferenceDate: 42),
                "dateModified": Date(timeIntervalSinceReferenceDate: 42),
                "sortIndex": 1,
                "theme": "light",
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
                "content": ["type": "image", "filename": "\(self.pageIDs[2].uuidString).png", "metadata": ["description": "This is an image"]]
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

        self.modelController = BubblesModelController(undoManager: UndoManager())
        self.modelReader = ModelReader(modelController: modelController)
    }

    func test_read_createsAllCanvasesFromPlist() {
        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let canvases = self.modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[1])))

        let titles = canvases.map { $0.title }
        XCTAssertTrue(titles.contains("Canvas 1"))
        XCTAssertTrue(titles.contains("Canvas 2"))
    }

    func test_read_createsAllPagesFromPlist() {
        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let pages = self.modelController.collection(for: Page.self).all
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
        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let canvasPages = self.modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 3)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[2])))
    }

    func test_read_doesntCreateNewCanvasIfOneAlreadyExistsWithID() {
        self.modelController.collection(for: Canvas.self).newObject() {
            $0.id = Canvas.modelID(with: self.canvasIDs[1])
            $0.title = "Foo Bar Baz"
        }

        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let canvases = self.modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[1])))

        let titles = canvases.map { $0.title }
        XCTAssertTrue(titles.contains("Canvas 1"))
        XCTAssertTrue(titles.contains("Canvas 2"))
    }

    func test_read_doesntCreateNewPageIfOneAlreadyExistsWithID() {
        self.modelController.collection(for: Page.self).newObject() {
            $0.id = Page.modelID(with: self.pageIDs[0])
            $0.title = "Hello"
        }

        self.modelController.collection(for: Page.self).newObject() {
            $0.id = Page.modelID(with: self.pageIDs[2])
            $0.title = "World"
        }

        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let pages = self.modelController.collection(for: Page.self).all
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
        self.modelController.collection(for: CanvasPage.self).newObject() {
            $0.id = CanvasPage.modelID(with: self.canvasPageIDs[1])
        }

        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let canvasPages = self.modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 3)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[2])))
    }

    func test_read_removesAllExtraCanvasesFromModelController() {
        let canvasToRemove = self.modelController.collection(for: Canvas.self).newObject()

        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let canvases = self.modelController.collection(for: Canvas.self).all
        XCTAssertEqual(canvases.count, 2)

        let ids = canvases.map { $0.id }
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[0])))
        XCTAssertTrue(ids.contains(Canvas.modelID(with: self.canvasIDs[1])))
        XCTAssertFalse(ids.contains(canvasToRemove.id))
    }

    func test_read_removesAllExtraPagesFromModelController() {
        let pageToRemove = self.modelController.collection(for: Page.self).newObject()

        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let pages = self.modelController.collection(for: Page.self).all
        XCTAssertEqual(pages.count, 3)

        let ids = pages.map { $0.id }
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[0])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[1])))
        XCTAssertTrue(ids.contains(Page.modelID(with: self.pageIDs[2])))
        XCTAssertFalse(ids.contains(pageToRemove.id))
    }

    func test_read_removesAllExtraCanvasPagesFromModelController() {
        let canvasPageToRemove = self.modelController.collection(for: CanvasPage.self).newObject()
        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let canvasPages = self.modelController.collection(for: CanvasPage.self).all
        XCTAssertEqual(canvasPages.count, 3)

        let ids = canvasPages.map { $0.id }
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        XCTAssertTrue(ids.contains(CanvasPage.modelID(with: self.canvasPageIDs[2])))
        XCTAssertFalse(ids.contains(canvasPageToRemove.id))
    }

    func test_read_allRelationshipsAreCompleted() throws {
        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let canvasPage1 = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.canvasPageIDs[0])))
        let canvasPage2 = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.canvasPageIDs[1])))
        let canvasPage3 = try XCTUnwrap(self.modelController.collection(for: CanvasPage.self).objectWithID(CanvasPage.modelID(with: self.canvasPageIDs[2])))

        let page1 = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[0])))
        let page2 = try XCTUnwrap(self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[1])))

        let canvas1 = try XCTUnwrap(self.modelController.collection(for: Canvas.self).objectWithID(Canvas.modelID(with: self.canvasIDs[0])))
        let canvas2 = try XCTUnwrap(self.modelController.collection(for: Canvas.self).objectWithID(Canvas.modelID(with: self.canvasIDs[1])))

        XCTAssertEqual(canvasPage1.page, page1)
        XCTAssertEqual(canvasPage2.page, page2)
        XCTAssertEqual(canvasPage3.page, page2)

        XCTAssertEqual(canvasPage1.canvas, canvas1)
        XCTAssertEqual(canvasPage2.canvas, canvas1)
        XCTAssertEqual(canvasPage3.canvas, canvas2)

        XCTAssertEqual(canvasPage2.parent, canvasPage1)
    }

    func test_read_allContentIsReadFromDisk() {
        XCTAssertNoThrow(try self.modelReader.read(self.testFileWrapper))

        let textPage = self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[0]))
        XCTAssertEqual(textPage?.content.contentType, .text)
        XCTAssertEqual((textPage?.content as? TextPageContent)?.text.string, "Foo Bar")

        let imagePage = self.modelController.collection(for: Page.self).objectWithID(Page.modelID(with: self.pageIDs[2]))
        XCTAssertEqual(imagePage?.content.contentType, .image)
        //We need to convert to data and back to ensure the resulting pngData is always equal
        let imageData = NSImage(named: "NSAddTemplate")!.pngData()!
        let image = NSImage(data: imageData)!
        XCTAssertEqual((imagePage?.content as? ImagePageContent)?.image?.pngData(), image.pngData())
        XCTAssertEqual((imagePage?.content as? ImagePageContent)?.imageDescription, "This is an image")
    }


    //MARK: - Errors

    func test_errors_doesntThrowErrorIfFileWrapperIsEmpty() {
        XCTAssertNoThrow(try self.modelReader.read(FileWrapper(directoryWithFileWrappers: [:])))
    }

    func test_errors_throwsCorruptDataErrorIfDataPlistExistsButIsEmpty() {
        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: Data()),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.corruptData {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsCorruptDataErrorIfPlistCannotBeDecoded() {
        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: "abcdefgh".data(using: .utf8)!),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.corruptData {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfCanvasesMissing() {
        let plist = ["pages": [[String: Any]](), "canvasPages": [[String: Any]]()]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.missingCollection("canvases") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfPagesMissing() {
        let plist = ["canvases": [[String: Any]](), "canvasPages": [[String: Any]]()]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.missingCollection("pages") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingCollectionErrorIfCanvasPagesMissing() {
        let plist = ["pages": [[String: Any]](), "canvases": [[String: Any]]()]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.missingCollection("canvasPages") {
            //Correct
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfACanvasIsMissingAnID() {
        let plist: [String: [[String: Any]]] = [
            "canvases": [["title": "Canvas Without ID"]],
            "pages": [],
            "canvasPages": []
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["title": "Canvas Without ID"])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfAPageIsMissingAnID() {
        let plist: [String: [[String: Any]]] = [
            "canvases": [],
            "pages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "title": "Page With ID"],
                ["title": "Page Without ID"]
            ],
            "canvasPages": []
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["title": "Page Without ID"])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsMissingIDErrorIfACanvasPageIsMissingAnID() {
        let plist: [String: [[String: Any]]] = [
            "canvases": [],
            "pages": [],
            "canvasPages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation, "frame": NSStringFromRect(CGRect(x: 0, y: 2, width: 8, height: 9))],
                ["frame": NSStringFromRect(CGRect(x: 0, y: 12, width: 5, height: 4))]
            ]
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelReader.Errors.missingID(let object) {
            XCTAssertEqual(object as? [String: String], ["frame": NSStringFromRect(CGRect(x: 0, y: 12, width: 5, height: 4))])
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsModelObjectUpdateErrorIfCanvasUpdateFailed() {
        let plist: [String: [[String: Any]]] = [
            "canvases": [
                ["id": Canvas.modelID(with: UUID()).stringRepresentation]
            ],
            "pages": [],
            "canvasPages": []
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelObjectUpdateErrors.attributeNotFound {
            //Passes
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsModelObjectUpdateErrorIfPageUpdateFailed() {
        let plist: [String: [[String: Any]]] = [
            "canvases": [],
            "pages": [
                ["id": Page.modelID(with: UUID()).stringRepresentation]
            ],
            "canvasPages": []
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelObjectUpdateErrors.attributeNotFound {
            //Passes
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }

    func test_errors_throwsModelObjectUpdateErrorIfCanvasPageUpdateFailed() {
        let plist: [String: [[String: Any]]] = [
            "canvases": [],
            "pages": [],
            "canvasPages": [
                ["id": CanvasPage.modelID(with: UUID()).stringRepresentation]
            ]
        ]
        let plistData = try! PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)

        let fileWrapper = FileWrapper(directoryWithFileWrappers: [
            "data.plist": FileWrapper(regularFileWithContents: plistData),
            "content": FileWrapper(directoryWithFileWrappers: [:])
        ])
        do {
            try self.modelReader.read(fileWrapper)
            XCTFail("Error not thrown")
        } catch ModelObjectUpdateErrors.attributeNotFound {
            //Passes
        } catch let e {
            XCTFail("Threw incorrect error: \(e)")
        }
    }
}
