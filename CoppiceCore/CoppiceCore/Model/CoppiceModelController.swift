//
//  CoppiceModelController.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Data

public class CoppiceModelController: NSObject, ModelController {
    public var allCollections = [ModelType: AnyModelCollection]()
    public let settings = ModelSettings()
    public let croppedImageCache = CroppedImageCache()

    public lazy var identifier: UUID = {
        if let identifierString = self.settings.string(for: .documentIdentifier),
            let identifier = UUID(uuidString: identifierString)
        {
            return identifier
        }

        let identifier = UUID()
        self.settings.set(identifier.uuidString, for: .documentIdentifier)
        return identifier
    }()

    public let undoManager: UndoManager
    public init(undoManager: UndoManager) {
        self.undoManager = undoManager
        super.init()

        self.addModelCollection(for: Canvas.self)
        self.addModelCollection(for: CanvasPage.self)
        self.addModelCollection(for: Page.self)
        self.addModelCollection(for: Folder.self)
        self.addModelCollection(for: CanvasLink.self)
        self.addModelCollection(for: PageHierarchy.self)
    }

    //MARK: - Page
    public var pageCollection: ModelCollection<Page> {
        return self.collection(for: Page.self)
    }

    @discardableResult public func createPage(ofType contentType: PageContentType = .text, in parentFolder: Folder, below item: FolderContainable? = nil, setup: ((Page) -> Void)? = nil) -> Page {
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

    @discardableResult public func createPages(fromFilesAt urls: [URL], in parentFolder: Folder, below item: FolderContainable? = nil, setup: (([Page]) -> Void)? = nil) -> [Page] {
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

    @discardableResult public func duplicatePages(_ pages: [Page]) -> [Page] {
        self.pushChangeGroup()
        self.undoManager.beginUndoGrouping()

        let duplicatedPages = pages.map { page -> Page in
            let duplicatedPage = Page.create(in: self) {
                var plist = page.plistRepresentation
                plist[.id] = $0.id

                let newDateCreated = Date()
                plist[.Page.dateCreated] = newDateCreated
                plist[.Page.dateModified] = newDateCreated

                try? $0.update(fromPlistRepresentation: plist)
            }

            page.containingFolder?.insert([duplicatedPage], below: page)
            return duplicatedPage
        }

        self.undoManager.setActionName(NSLocalizedString("Duplicate Pages", comment: "Duplicate pages undo action name"))
        self.undoManager.endUndoGrouping()
        self.popChangeGroup()

        return duplicatedPages
    }

    public func delete(_ page: Page) {
        self.pushChangeGroup()
        self.undoManager.beginUndoGrouping()
        page.canvasPages.forEach {
            self.canvasPageCollection.delete($0)
        }

        page.containingFolder?.remove([page])
        self.pageCollection.delete(page)

        self.undoManager.setActionName(NSLocalizedString("Delete Page", comment: "Delete Page Undo Action Name"))
        self.undoManager.endUndoGrouping()
        self.popChangeGroup()
    }


    //MARK: - Folder
    public lazy var rootFolder: Folder = {
        if let id = self.settings.modelID(for: .rootFolder),
            let rootFolder = self.folderCollection.objectWithID(id)
        {
            return rootFolder
        }

        var folder: Folder!
        self.folderCollection.disableUndo {
            folder = Folder.create(in: self) { $0.title = Folder.rootFolderTitle }
        }

        self.settings.set(folder.id, for: .rootFolder)

        return folder
    }()

    public var folderCollection: ModelCollection<Folder> {
        return self.collection(for: Folder.self)
    }

    @discardableResult public func createFolder(in parentFolder: Folder, below item: FolderContainable? = nil, setup: ((Folder) -> Void)? = nil) -> Folder {
        self.undoManager.beginUndoGrouping()
        let folder = Folder.create(in: self)

        parentFolder.insert([folder], below: item)
        setup?(folder)

        self.undoManager.setActionName(NSLocalizedString("Create Folder", comment: "Create Folder Undo Action Name"))
        self.undoManager.endUndoGrouping()
        return folder
    }

    public func delete(_ folder: Folder) {
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
    public func delete(_ folderItems: [FolderContainable]) {
        self.pushChangeGroup()
        for item in folderItems {
            if let page = item as? Page {
                self.delete(page)
            } else if let folder = item as? Folder {
                self.delete(folder)
            } else {
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
    public var canvasCollection: ModelCollection<Canvas> {
        return self.collection(for: Canvas.self)
    }

    @discardableResult public func createCanvas(setup: ((Canvas) -> Void)? = nil) -> Canvas {
        let canvas = Canvas.create(in: self)
        setup?(canvas)
        self.undoManager.setActionName(NSLocalizedString("Create Canvas", comment: "Create Canvas Undo Action Name"))
        return canvas
    }

    public func delete(_ canvas: Canvas) {
        self.pushChangeGroup()
        canvas.pages.forEach {
            self.canvasPageCollection.delete($0)
        }
        self.canvasCollection.delete(canvas)
        self.undoManager.setActionName(NSLocalizedString("Delete Canvas", comment: "Delete Canvas Undo Action Name"))
        self.popChangeGroup()
    }


    //MARK: - CanvasPages
    public var canvasPageCollection: ModelCollection<CanvasPage> {
        return self.collection(for: CanvasPage.self)
    }

    @discardableResult public func openPage(at link: PageLink, on canvas: Canvas, mode: Canvas.OpenPageMode) -> [CanvasPage] {
        guard let page = self.pageCollection.objectWithID(link.destination) else {
            return []
        }

        let undoActionName = NSLocalizedString("Open Page Link", comment: "Open Page Link Undo Action Name")

        guard
            let source = link.source,
            let sourcePage = self.canvasPageCollection.objectWithID(source)
        else {
            self.undoManager.setActionName(undoActionName)
            return canvas.addPages([page])
        }

        if let existingPage = sourcePage.existingLinkedCanvasPage(for: page) {
            return [existingPage]
        }

        self.undoManager.setActionName(undoActionName)
        return canvas.open(page, linkedFrom: sourcePage, with: link, mode: mode)
    }

    public func close(_ canvasPage: CanvasPage) {
        guard let canvas = canvasPage.canvas else {
            return
        }
        self.pushChangeGroup()
        canvas.close(canvasPage)
        self.undoManager.setActionName(NSLocalizedString("Close Pages", comment: "Close Pages From Canvas Undo Action Name"))
        self.popChangeGroup()
    }

    //MARK: - Canvas Link
    public var canvasLinkCollection: ModelCollection<CanvasLink> {
        return self.collection(for: CanvasLink.self)
    }

    //MARK: - Page Hierarchy
    public var pageHierarchyCollection: ModelCollection<PageHierarchy> {
        return self.collection(for: PageHierarchy.self)
    }
}


//MARK: - ModelSettingsKeys
extension ModelSettings.Setting {
    public static let pageSortKeySetting = ModelSettings.Setting(rawValue: "pageSortKey")
    public static let pageGroupExpanded = ModelSettings.Setting(rawValue: "pageGroupExpanded")
    public static let rootFolder = ModelSettings.Setting(rawValue: "rootFolder")
    public static let documentIdentifier = ModelSettings.Setting(rawValue: "identifier")
}
