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

    @discardableResult func createPage(ofType contentType: PageContentType = .text, in parentFolder: Folder, below item: FolderContainable? = nil, setup: ((Page) -> Void)? = nil) -> Page {
        self.undoManager.beginUndoGrouping()

        let page = Page.create(in: self) {
            //No need to change the content type if it's already the default
            guard contentType != $0.content.contentType else {
                return
            }
            $0.content = contentType.createContent()
        }

        parentFolder.insert([page], below: item)

        setup?(page)

        self.undoManager.setActionName(NSLocalizedString("Create Page", comment: "Create Page Undo Action Name"))
        self.undoManager.endUndoGrouping()

        return page
    }

    @discardableResult func createPages(fromFilesAt urls: [URL], in parentFolder: Folder, below item: FolderContainable? = nil, setup: (([Page]) -> Void)? = nil) -> [Page] {
        self.pushChangeGroup()
        self.undoManager.beginUndoGrouping()

        let newPages = urls.compactMap { self.pageCollection.newPage(fromFileAt: $0) }
        parentFolder.insert(newPages, below: item)

        setup?(newPages)

        self.undoManager.setActionName(NSLocalizedString("Create Pages", comment: "Create Page Undo Action Name"))
        self.undoManager.endUndoGrouping()
        self.popChangeGroup()
        return newPages
    }

    func delete(_ page: Page) {
        self.pushChangeGroup()
        self.undoManager.beginUndoGrouping()
        page.canvases.forEach {
            self.canvasPageCollection.delete($0)
        }

        page.containingFolder?.remove([page])
        self.pageCollection.delete(page)

        self.undoManager.setActionName(NSLocalizedString("Delete Page", comment: "Delete Page Undo Action Name"))
        self.undoManager.endUndoGrouping()
        self.popChangeGroup()
    }


    //MARK: - Folder
    lazy var rootFolder: Folder = {
        if let id = self.settings.modelID(for: .rootFolder),
            let rootFolder = self.folderCollection.objectWithID(id) {
            return rootFolder
        }

        var folder: Folder!
        self.folderCollection.disableUndo {
            folder = Folder.create(in: self) { $0.title = Folder.rootFolderTitle }
        }

        self.settings.set(folder.id, for: .rootFolder)

        return folder
    }()

    var folderCollection: ModelCollection<Folder> {
        return self.collection(for: Folder.self)
    }

    @discardableResult func createFolder(in parentFolder: Folder, below item: FolderContainable? = nil, setup: ((Folder) -> Void)? = nil) -> Folder {
        self.undoManager.beginUndoGrouping()
        let folder = Folder.create(in: self)

        parentFolder.insert([folder], below: item)
        setup?(folder)

        self.undoManager.setActionName(NSLocalizedString("Create Folder", comment: "Create Folder Undo Action Name"))
        self.undoManager.endUndoGrouping()
        return folder
    }

    func delete(_ folder: Folder) {
        folder.contents.forEach { item in
            if let folder = item as? Folder {
                self.delete(folder)
            } else if let page = item as? Page {
                self.delete(page)
            }
        }
        folder.containingFolder?.remove([folder])
        self.folderCollection.delete(folder)
        self.undoManager.setActionName(NSLocalizedString("Delete Folder", comment: "Delete Folder Undo Action Name"))
    }


    //MARK: - Folder Items
    func delete(_ folderItems: [FolderContainable]) {
        self.pushChangeGroup()
        for item in folderItems {
            if let page = item as? Page {
                self.delete(page)
            }
            else if let folder = item as? Folder {
                self.delete(folder)
            }
            else {
                assertionFailure("Tried deleting a folder item that isn't a page or file")
            }
        }
        self.undoManager.setActionName(self.undoActionName(for: folderItems))
        self.popChangeGroup()
    }

    private func undoActionName(for items: [FolderContainable]) -> String {
        var hasPages = false
        var hasFolders = false
        for item in items {
            if item is Page {
                hasPages = true
            } else if item is Folder {
                hasFolders = true
            }

            if hasPages && hasFolders {
                break
            }
        }

        if hasPages && !hasFolders {
            return NSLocalizedString("Delete Pages", comment: "Delete Pages undo action")
        } else if hasFolders && !hasPages {
            return NSLocalizedString("Delete Folders", comment: "Delete Folders undo action")
        } else {
            return NSLocalizedString("Delete Items", comment: "Delete Items undo action")
        }
    }


    //MARK: - Canvas
    var canvasCollection: ModelCollection<Canvas> {
        return self.collection(for: Canvas.self)
    }

    @discardableResult func createCanvas(setup: ((Canvas) -> Void)? = nil) -> Canvas {
        let canvas = Canvas.create(in: self)
        setup?(canvas)
        self.undoManager.setActionName(NSLocalizedString("Create Canvas", comment: "Create Canvas Undo Action Name"))
        return canvas
    }

    func delete(_ canvas: Canvas) {
        self.pushChangeGroup()
        canvas.pages.forEach {
            self.canvasPageCollection.delete($0)
        }
        self.canvasCollection.delete(canvas)
        self.undoManager.setActionName(NSLocalizedString("Delete Canvas", comment: "Delete Canvas Undo Action Name"))
        self.popChangeGroup()
    }


    //MARK: - CanvasPages
    var canvasPageCollection: ModelCollection<CanvasPage> {
        return self.collection(for: CanvasPage.self)
    }

    @discardableResult func addPages(_ pages: [Page], to canvas: Canvas, centredOn point: CGPoint? = nil) -> [CanvasPage] {
        return []
    }

    @discardableResult func openPage(at link: PageLink, on canvas: Canvas) -> [CanvasPage] {
        guard let page = self.pageCollection.objectWithID(link.destination) else {
            return []
        }

        let undoActionName = NSLocalizedString("Open Page Link", comment: "Open Page Link Undo Action Name")

        guard let source = link.source,
            let sourcePage = self.canvasPageCollection.objectWithID(source) else {
                self.undoManager.setActionName(undoActionName)
                return canvas.addPages([page])
        }

        if let existingPage = sourcePage.existingCanvasPage(for: page) {
            return [existingPage]
        }

        self.undoManager.setActionName(undoActionName)
        return canvas.open(page, linkedFrom: sourcePage)
    }

    func close(_ canvasPage: CanvasPage) {
        guard let canvas = canvasPage.canvas else {
            return
        }
        self.pushChangeGroup()
        canvas.close(canvasPage)
        self.undoManager.setActionName(NSLocalizedString("Close Pages", comment: "Close Pages From Canvas Undo Action Name"))
        self.popChangeGroup()
    }
}


//MARK: - ModelSettingsKeys
extension ModelSettings.Setting {
    static let pageSortKeySetting = ModelSettings.Setting(rawValue: "pageSortKey")
    static let rootFolder = ModelSettings.Setting(rawValue: "rootFolder")
    static let documentIdentifier = ModelSettings.Setting(rawValue: "identifier")
}
