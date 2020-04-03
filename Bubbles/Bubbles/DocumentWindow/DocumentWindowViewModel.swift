//
//  DocumentWindowState.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol DocumentWindow: class {
    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void)
    func invalidateRestorableState()
}

class DocumentWindowViewModel: NSObject {
    weak var document: Document?
    weak var window: DocumentWindow?
    @Published var currentInspectors: [Inspector] = []

    let modelController: ModelController
    let thumbnailController: ThumbnailController
    let pageImageController: PageImageController
    let pageLinkController: PageLinkController
    init(modelController: ModelController) {
        self.modelController = modelController
        self.thumbnailController = ThumbnailController(modelController: modelController)
        self.pageImageController = PageImageController(modelController: modelController)
        self.pageLinkController = PageLinkController(modelController: modelController)
        super.init()
        self.thumbnailController.documentViewModel = self
        self.pageImageController.documentViewModel = self

        //Force the root folder to load immediately so we don't end up with observation loops later
        _ = self.rootFolder
        self.setupSelectionUndo()
    }


    //MARK: - Search
    @objc dynamic var searchString: String?
    

    //MARK: - Model Helpers
    var pageCollection: ModelCollection<Page> {
        return self.modelController.collection(for: Page.self)
    }

    var canvasCollection: ModelCollection<Canvas> {
        return self.modelController.collection(for: Canvas.self)
    }

    var canvasPageCollection: ModelCollection<CanvasPage> {
        return self.modelController.collection(for: CanvasPage.self)
    }

    var foldersCollection: ModelCollection<Folder> {
        return self.modelController.collection(for: Folder.self)
    }


    //MARK: - Selection Logic
    enum SidebarItem: Equatable, Hashable {
        case canvases
        case canvas(ModelID)
        case page(ModelID)
        case folder(ModelID)

        var persistentRepresentation: String {
            switch self {
            case .canvases:
                return "canvases"
            case .canvas(let modelID):
                return "canvas::\(modelID.stringRepresentation)"
            case .page(let modelID):
                return "page::\(modelID.stringRepresentation)"
            case .folder(let modelID):
                return "folder::\(modelID.stringRepresentation)"
            }
        }

        static func from(persistentRepresentation: String) -> Self? {
            let components = (persistentRepresentation as NSString).components(separatedBy: "::")
            if components[0] == "canvases" {
                return .canvases
            }

            guard components.count == 2,
                let modelID = ModelID(string: components[1]) else {
                    return nil
            }

            if components[0] == "page" {
                return .page(modelID)
            }
            if components[0] == "folder" {
                return .folder(modelID)
            }
            if components[0] == "canvas" {
                return .canvas(modelID)
            }
            return nil
        }
    }
    @Published var selectedCanvasID: ModelID? {
        didSet {
            self.window?.invalidateRestorableState()
        }
    }

    @Published private(set) var sidebarSelection: [SidebarItem] = [] {
        didSet {
            self.window?.invalidateRestorableState()
        }
    }

    //Updates the sidebar selection and the editor
    func updateSelection(_ selection: [SidebarItem]) {
        self.sidebarSelection = selection
        self.updateEditor(basedOnNewSelection: selection)
    }


    //MARK: - Editor Logic
    enum Editor: Equatable {
        case none
        case canvas
        case page(Page)

        var persistentRepresentation: String {
            switch self {
            case .none: return "none"
            case .canvas: return "canvas"
            case .page(let page): return "page::\(page.id.stringRepresentation)"
            }
        }

        static func from(persistentRepresentation: String, pagesCollection: ModelCollection<Page>) -> Self {
            if persistentRepresentation == "canvas" {
                return .canvas
            }
            if persistentRepresentation.hasPrefix("page") {
                if let modelIDString = persistentRepresentation.components(separatedBy: "::").last,
                    let modelID = ModelID(string: modelIDString),
                    let page = pagesCollection.objectWithID(modelID)
                {
                    return .page(page)
                }
            }
            return .none
        }
    }
    @Published var currentEditor: Editor = .none

    private func updateEditor(basedOnNewSelection selection: [SidebarItem]) {
        //We won't update the editor if we have multiple items selected
        guard selection.count <= 1 else {
            return
        }

        //If nothing is selected then display nothing
        guard let selectedItem = selection.first else {
            self.currentEditor = .none
            return
        }

        switch selectedItem {
        case .canvases:
            self.currentEditor = .canvas
        case .canvas(let modelID):
            self.currentEditor = .canvas
            self.selectedCanvasID = modelID
        case .page(let modelID):
            guard let page = self.pageCollection.objectWithID(modelID) else {
                self.currentEditor = .none
                return
            }
            self.currentEditor = .page(page)
        //Don't bother changing for a folder
        case .folder(_):
            return
        }
    }


    //MARK: - State Restoration
    func encodeRestorableState(with coder: NSCoder) {
        coder.encode(self.sidebarSelection.map(\.persistentRepresentation), forKey: "sidebarSelection")
        coder.encode(self.selectedCanvasID?.stringRepresentation, forKey: "selectedCanvasID")
        coder.encode(self.currentEditor.persistentRepresentation, forKey: "currentEditor")
    }

    func restoreState(with coder: NSCoder) {
        if let sidebarSelectionStrings = coder.decodeObject(forKey: "sidebarSelection") as? [String] {
            self.sidebarSelection = sidebarSelectionStrings.compactMap { SidebarItem.from(persistentRepresentation: $0) }

        }
        if let canvasIDString = coder.decodeObject(forKey: "selectedCanvasID") as? String {
            self.selectedCanvasID = ModelID(string: canvasIDString)
        }
        if let currentEditorString = coder.decodeObject(forKey: "currentEditor") as? String {
            self.currentEditor = Editor.from(persistentRepresentation: currentEditorString, pagesCollection: self.pageCollection)
        }
    }


    //MARK: - New Page Helpers
    var canvasForNewPages: Canvas? {
        guard self.sidebarSelection.firstIndex(of: .canvases) != nil else {
            return nil
        }

        guard let selectedCanvasID = self.selectedCanvasID else {
            return nil
        }

        return self.canvasCollection.objectWithID(selectedCanvasID)
    }

    var folderForNewPages: Folder {
        guard let selection = self.sidebarSelection.last(where: { $0 != .canvases }) else {
            return self.rootFolder
        }

        switch selection {
        case .canvases, .canvas(_):
            return self.rootFolder
        case .page(let modelID):
            return self.pageCollection.objectWithID(modelID)?.containingFolder ?? self.rootFolder
        case .folder(let modelID):
            return self.foldersCollection.objectWithID(modelID) ?? self.rootFolder
        }
    }


    //MARK: - Folders
    lazy var rootFolder: Folder = {
        if let id = self.modelController.settings.modelID(for: .rootFolder),
            let rootFolder = self.foldersCollection.objectWithID(id) {
            return rootFolder
        }

        var folder: Folder!
        self.foldersCollection.disableUndo {
            folder = self.foldersCollection.newObject() { $0.title = Folder.rootFolderTitle }
        }

        self.modelController.settings.set(folder.id, for: .rootFolder)

        return folder
    }()

    @discardableResult func createFolder(in parentFolder: Folder? = nil, below item: FolderContainable? = nil, withInitialContents contents: [FolderContainable] = []) -> Folder {
        self.modelController.undoManager.beginUndoGrouping()
        let folder = self.foldersCollection.newObject()

        (parentFolder ?? self.folderForNewPages).insert([folder], below: item)
        folder.insert(contents)
        self.sidebarSelection = [.folder(folder.id)]
        self.modelController.undoManager.endUndoGrouping()
        return folder
    }


    //MARK: - Creating Pages
    @discardableResult func createPage(ofType contentType: PageContentType = .text, in parentFolder: Folder? = nil, below item: FolderContainable? = nil) -> Page {
        self.modelController.undoManager.beginUndoGrouping()
        self.modelController.undoManager.setActionName(NSLocalizedString("Create Page", comment: "Create Page Undo Action Name"))
        let page = self.pageCollection.newObject() {
            //No need to change the content type if it's already the default
            guard contentType != $0.content.contentType else {
                return
            }
            $0.content = contentType.createContent()
        }

        (parentFolder ?? self.folderForNewPages).insert([page], below: item)

        if self.sidebarSelection.contains(.canvases) {
            self.canvasForNewPages?.addPages([page])
        } else {
            self.updateSelection([.page(page.id)])
        }

        self.modelController.undoManager.endUndoGrouping()
        return page
    }

    @discardableResult func createPages(fromFilesAtURLs fileURLs: [URL], in folder: Folder? = nil, below item: FolderContainable? = nil, addingTo canvas: Canvas? = nil, centredOn point: CGPoint? = nil) -> [Page] {
        self.modelController.pushChangeGroup()
        self.modelController.undoManager.setActionName(NSLocalizedString("Create Pages", comment: "Create Page Undo Action Name"))
        let newPages = fileURLs.compactMap { self.pageCollection.newPage(fromFileAt: $0) }
        if let canvas = canvas {
            canvas.addPages(newPages, centredOn: point)
        }

        (folder ?? self.folderForNewPages).insert(newPages, below: item)

        self.modelController.popChangeGroup()

        return newPages
    }


    //MARK: - Deleting Pages
    func delete(_ sidebarItems: [SidebarItem]) {
        guard let alert = self.alertForDeleting(sidebarItems) else {
            self.actuallyDelete(sidebarItems)
            return
        }

        self.window?.showAlert(alert, callback: { (index) in
            let (type, _) = alert.buttons[index]
            if (type == .confirm) {
                self.actuallyDelete(sidebarItems)
            }
        })
    }

    private func alertForDeleting(_ sidebarItems: [SidebarItem]) -> Alert? {
        guard sidebarItems.count <= 1 else {
            return self.alertForDeletingMultipleItems(sidebarItems)
        }

        guard let item = sidebarItems.first else {
            return nil
        }

        switch item {
        case .page(let modelID):
            guard let page = self.pageCollection.objectWithID(modelID) else {
                return nil
            }
            return self.alertForDeletingSinglePage(page)
        case .folder(let modelID):
            guard let folder = self.foldersCollection.objectWithID(modelID) else {
                return nil
            }
            return self.alertForDeletingSingleFolder(folder)
        default:
            return nil
        }
    }

    private func alertForDeletingSinglePage(_ page: Page) -> Alert? {
        let canvases = Set(page.canvases.compactMap { $0.canvas })
        guard canvases.count > 0 else {
            return nil
        }
        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString("Delete Page '%@'", comment: "Delete Page alert title"),
                                                              page.title)

        let localizedMessage: String
        if canvases.count == 1 {
            let messageFormat = NSLocalizedString("This page is on the canvas '%@'. Deleting it will also remove it and any linked pages from that canvas.",
                                                  comment: "Delete Page single canvas alert message")
            localizedMessage = String.localizedStringWithFormat(messageFormat, canvases.first!.title)
        } else {
            let messageFormat = NSLocalizedString("This page is on %d canvases. Deleting it will also remove it and any linked pages from those canvases.",
                                                  comment: "Delete Page multiple pages alert message")
            localizedMessage = String.localizedStringWithFormat(messageFormat, canvases.count)
        }
        return Alert(title: localizedTitle,
                     message: localizedMessage,
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func alertForDeletingSingleFolder(_ folder: Folder) -> Alert? {
        guard folder.contents.count > 0 else {
            return nil
        }
        return Alert(title: NSLocalizedString("Delete Folder", comment: "Delete folder alert title"),
                     message: NSLocalizedString("This will also delete any items contained in this folder", comment: "Delete Folder single alert message"),
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func alertForDeletingMultipleItems(_ items: [SidebarItem]) -> Alert? {
        var hasPages = false
        var hasFolders = false
        for item in items {
            switch item {
            case .page(_):
                hasPages = true
            case .folder(_):
                hasFolders = true
            case .canvases, .canvas(_):
                continue
            }

            if hasPages && hasFolders {
                break
            }
        }

        let localizedTitle: String
        let localizedMessage: String
        if hasPages && !hasFolders {
            localizedTitle = NSLocalizedString("Delete multiple pages", comment: "Delete multiple pages alert title")
            localizedMessage = NSLocalizedString("This will also remove these pages from any canvases they are on", comment: "Delete multiple pages alert message")
        } else if hasFolders && !hasPages {
            localizedTitle = NSLocalizedString("Delete multiple folders", comment: "Delete multiple folders alert title")
            localizedMessage = NSLocalizedString("This will also delete any items contained in these folders", comment: "Delete multiple folders alert message")
        } else {
            localizedTitle = NSLocalizedString("Delete multiple items", comment: "Delete multiple folders alert title")
            localizedMessage = NSLocalizedString("This will also delete any items contained in folders and remove pages from any canvases they are on", comment: "Delete multiple items alert message")
        }

        return Alert(title: localizedTitle,
                     message: localizedMessage,
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func actuallyDelete(_ items: [SidebarItem]) {
        self.modelController.pushChangeGroup()
        self.modelController.undoManager.setActionName(self.undoActionName(for: items))
        var itemsToRemoveFromSelection = items
        for item in items {
            switch item {
            case .page(let modelID):
                guard let page = self.pageCollection.objectWithID(modelID) else {
                    continue
                }
                self.actuallyDelete(page)
            case .folder(let modelID):
                guard let folder = self.foldersCollection.objectWithID(modelID) else {
                    continue
                }
                let deletedContents = self.actuallyDelete(folder)
                itemsToRemoveFromSelection.append(contentsOf: deletedContents)
            case .canvases, .canvas(_):
                continue
            }
        }

        let newSelection = self.sidebarSelection.filter { !itemsToRemoveFromSelection.contains($0) }
        self.updateSelection(newSelection)

        self.modelController.popChangeGroup()
    }

    private func actuallyDelete(_ page: Page) {
        page.canvases.forEach {
            self.canvasPageCollection.delete($0)
        }

        page.containingFolder?.remove([page])
        self.pageCollection.delete(page)
    }

    private func actuallyDelete(_ folder: Folder) -> [SidebarItem] {
        var contentItemsDeleted = [SidebarItem]()
        folder.contents.forEach { (containable) in
            if let folder = containable as? Folder {
                contentItemsDeleted.append(contentsOf: self.actuallyDelete(folder))
                contentItemsDeleted.append(.folder(folder.id))
            } else if let page = containable as? Page {
                self.actuallyDelete(page)
                contentItemsDeleted.append(.page(page.id))
            }
        }
        folder.containingFolder?.remove([folder])
        self.foldersCollection.delete(folder)
        return contentItemsDeleted
    }

    private func undoActionName(for items: [SidebarItem]) -> String {
        var hasPages = false
        var hasFolders = false
        for item in items {
            switch item {
            case .page(_):
                hasPages = true
            case .folder(_):
                hasFolders = true
            case .canvases, .canvas(_):
                continue
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


    //MARK: - Navigating Pages

    /// Either opens the page or adds it to the canvas, depending on what is selected in the sidebar
    /// - Parameter pageLink: The PageLink to handle
    /// - Returns: True if the page link was handled, false if it wasn't
    @discardableResult func handle(_ pageLink: PageLink) -> Bool {
        guard self.modelController.object(with: pageLink.destination) != nil else {
            return false
        }

//        guard self.selectedCanvasInSidebar == nil else {
//            self.addPage(at: pageLink, to: self.selectedCanvasInSidebar!)
//            return true
//        }

        self.openPage(at: pageLink)
        return true
    }

    /// Displays the page at the supplied link in the main editor
    /// - Parameter pageLink: The page link to open
    func openPage(at pageLink: PageLink) {
        self.updateSelection([.page(pageLink.destination)])
    }


    //MARK: - Adding Pages To Canvas
    @discardableResult func addPages(_ pages: [Page], to canvas: Canvas, centredOn point: CGPoint? = nil) -> [CanvasPage] {
        guard pages.count > 0 else {
            return []
        }
        if pages.count == 1 {
        	self.modelController.undoManager.setActionName(NSLocalizedString("Add Page to Canvas", comment: "Add Page To Canvas Undo Action Name"))
        } else {
            self.modelController.undoManager.setActionName(NSLocalizedString("Add Pages to Canvas", comment: "Add Pages To Canvas Undo Action Name"))
        }

        return canvas.addPages(pages, centredOn: point)
    }


    //MARK: - Creating Canvases
    @discardableResult func createCanvas() -> Canvas {
        self.modelController.undoManager.setActionName(NSLocalizedString("Create Canvas", comment: "Create Canvas Undo Action Name"))
        let canvas = self.modelController.collection(for: Canvas.self).newObject()
        self.selectedCanvasID = canvas.id
        self.sidebarSelection = [.canvases]
        return canvas
    }


    //MARK: - Deleting Canvas
    func delete(_ canvas: Canvas) {
        guard let alert = alertForDeleting(canvas) else {
            self.actuallyDelete(canvas)
            return
        }

        self.window?.showAlert(alert, callback: { (index) in
            let (type, _) = alert.buttons[index]
            if (type == .confirm) {
                self.actuallyDelete(canvas)
            }
        })
    }

    private func alertForDeleting(_ canvas: Canvas) -> Alert? {
        guard canvas.pages.count > 0 else {
            return nil
        }

        let localizedTitle = String.localizedStringWithFormat(NSLocalizedString("Delete Canvas '%@'", comment: "Delete Canvas alert title"),
                                                              canvas.title)
        return Alert(title: localizedTitle,
                     message: NSLocalizedString("Are you sure you want to delete this canvas?", comment: "Delete canvas confirm message"),
                     confirmButtonTitle: NSLocalizedString("Delete", comment: "Delete alert confirm button"))
    }

    private func actuallyDelete(_ canvas: Canvas) {
        self.modelController.pushChangeGroup()
        self.modelController.undoManager.setActionName(NSLocalizedString("Delete Canvas", comment: "Delete Canvas Undo Action Name"))
        canvas.pages.forEach {
            self.canvasPageCollection.delete($0)
        }
        self.canvasCollection.delete(canvas)
        self.modelController.popChangeGroup()

        self.selectedCanvasID = nil
    }


    //MARK: - Opening & Closing Canvas Pages

    @discardableResult func openPage(at link: PageLink, on canvas: Canvas) -> [CanvasPage] {
        guard let page = self.pageCollection.objectWithID(link.destination) else {
            return []
        }

        let undoActionName = NSLocalizedString("Open Page Link", comment: "Open Page Link Undo Action Name")

        guard let source = link.source,
            let sourcePage = self.canvasPageCollection.objectWithID(source) else {
                self.modelController.undoManager.setActionName(undoActionName)
                return canvas.addPages([page])
        }

        if let existingPage = sourcePage.existingCanvasPage(for: page) {
            return [existingPage]
        }

        self.modelController.undoManager.setActionName(undoActionName)
        return canvas.open(page, linkedFrom: sourcePage)
    }

    //Removing page from canvas
    func close(_ canvasPage: CanvasPage) {
        guard let canvas = canvasPage.canvas else {
            return
        }
        self.modelController.pushChangeGroup()
        self.modelController.undoManager.setActionName(NSLocalizedString("Close Pages", comment: "Close Pages From Canvas Undo Action Name"))
        canvas.close(canvasPage)
        self.modelController.popChangeGroup()
    }


    //MARK: - Undo
    private var undoObservation: NSObjectProtocol?
    private func setupSelectionUndo() {
        let undoManager = self.modelController.undoManager
        self.undoObservation = NotificationCenter.default.addObserver(forName: .NSUndoManagerDidOpenUndoGroup,
                                                                      object: undoManager,
                                                                      queue: .main)
        { [weak self] (notification) in
            guard let strongSelf = self else {
                return
            }
            let sidebarSelection = strongSelf.sidebarSelection
            let selectedCanvas = strongSelf.selectedCanvasID
            undoManager.setActionIsDiscardable(true)
            undoManager.registerUndo(withTarget: strongSelf) { (target) in
                let oldSelection = target.sidebarSelection
                let oldCanvas = target.selectedCanvasID
                target.updateSelection(sidebarSelection)
                target.selectedCanvasID = selectedCanvas
                undoManager.registerUndo(withTarget: strongSelf) { (target) in
                    target.updateSelection(oldSelection)
                    target.selectedCanvasID = oldCanvas
                }
            }
        }
    }
}
