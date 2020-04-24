//
//  BubblesModelController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class BubblesModelController: NSObject, ModelController {
    var allCollections = [ModelType: Any]()
    let settings = ModelSettings()

    lazy var identifier: UUID = {
        if let identifierString = self.settings.string(for: .documentIdentifier),
            let identifier = UUID(uuidString: identifierString) {
            return identifier
        }

        let identifier = UUID()
        self.settings.set(identifier.uuidString, for: .documentIdentifier)
        return identifier
    }()

    let undoManager: UndoManager
    init(undoManager: UndoManager) {
        self.undoManager = undoManager
        super.init()

        self.addModelCollection(for: Canvas.self)
        self.addModelCollection(for: CanvasPage.self)
        self.addModelCollection(for: Page.self)
        self.addModelCollection(for: Folder.self)
    }

    func object(with id: ModelID) -> ModelObject? {
        switch id.modelType {
        case Canvas.modelType:
            return self.collection(for: Canvas.self).objectWithID(id)
        case Page.modelType:
            return self.collection(for: Page.self).objectWithID(id)
        case CanvasPage.modelType:
            return self.collection(for: CanvasPage.self).objectWithID(id)
        case Folder.modelType:
            return self.collection(for: Folder.self).objectWithID(id)
        default:
            assertionFailure("Model type '\(id.modelType)' does not exist")
            return nil
        }
    }


    //MARK: - Page
    var pageCollection: ModelCollection<Page> {
        return self.collection(for: Page.self)
    }

    func createPage(ofType contentType: PageContentType = .text, in parentFolder: Folder, below item: FolderContainable? = nil, withUndoActionName name: String? = nil, setup: ((Page) -> Void)? = nil) -> Page {
        let page = Page()
        page.collection = self.pageCollection
        return page
    }

    func createPages(fromFilesAt urls: [URL], in parentFolder: Folder, below item: FolderContainable? = nil, withUndoActionName name: String? = nil, setup: (([Page]) -> Void)? = nil) -> [Page] {
        return []
    }

    func delete(_ page: Page) {

    }


    //MARK: - Folder
    var rootFolder: Folder {
        let folder = Folder()
        folder.collection = self.folderCollection
        return folder
    }

    var folderCollection: ModelCollection<Folder> {
        return self.collection(for: Folder.self)
    }

    func createFolder(in parentFolder: Folder, below item: FolderContainable? = nil, withUndoActionName name: String? = nil, setup: ((Folder) -> Void)? = nil) -> Folder {
        let folder = Folder()
        folder.collection = self.folderCollection
        return folder
    }

    func delete(_ folder: Folder, withUndoActionName name: String? = nil) {

    }


    //MARK: - Canvas
    var canvasCollection: ModelCollection<Canvas> {
        return self.collection(for: Canvas.self)
    }

    func createCanvas(withUndoActionName name: String? = nil, setup: ((Canvas) -> Void)? = nil) -> Canvas {
        let canvas = Canvas()
        canvas.collection = self.canvasCollection
        return canvas
    }

    func delete(_ canvas: Canvas, withUndoActionName name: String? = nil) {

    }


    //MARK: - CanvasPages
    var canvasPageCollection: ModelCollection<CanvasPage> {
        return self.collection(for: CanvasPage.self)
    }

    func addPages(_ pages: [Page], to canvas: Canvas, centredOn point: CGPoint? = nil, withUndoActionName name: String? = nil) -> [CanvasPage] {
        return []
    }

    func openPage(at link: PageLink, on canvas: Canvas, withUndoActionName name: String? = nil) -> [CanvasPage] {
        return []
    }

    func close(_ canvasPage: CanvasPage, withUndoActionName name: String? = nil) {
        
    }
}


//MARK: - ModelSettingsKeys
extension ModelSettings.Setting {
    static let pageSortKeySetting = ModelSettings.Setting(rawValue: "pageSortKey")
    static let rootFolder = ModelSettings.Setting(rawValue: "rootFolder")
    static let documentIdentifier = ModelSettings.Setting(rawValue: "identifier")
}
