//
//  DocumentWindowState.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import CoppiceCore
import Foundation
import M3Data

protocol DocumentWindow: AnyObject {
    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void)
    func invalidateRestorableState()
}

class DocumentWindowViewModel: NSObject {
    weak var document: Document?
    weak var window: DocumentWindow?
    @Published var currentInspectors: [Inspector] = []

    let modelController: CoppiceModelController
    let thumbnailController: ThumbnailController
    let pageImageController: PageImageController
    let pageLinkController: PageLinkController
    init(modelController: CoppiceModelController) {
        self.modelController = modelController
        self.thumbnailController = ThumbnailController(modelController: modelController)
        self.pageImageController = PageImageController(modelController: modelController)
        self.pageLinkController = PageLinkController(modelController: modelController)
        super.init()
        self.thumbnailController.documentViewModel = self
        self.pageImageController.documentViewModel = self

        //Force the root folder to load immediately so we don't end up with observation loops later
        _ = self.modelController.rootFolder

        for page in self.modelController.pageCollection.all {
            if page.containingFolder == nil {
                self.modelController.rootFolder.insert([page])
            }
            if let imageContent = page.content as? ImagePageContent {
                //Pre-generate the cropped images if needed
                modelController.croppedImageCache.croppedImage(for: imageContent)
            }
        }

        self.setupObservation()
    }

    deinit {
        self.cleanUpObserveration()
    }

    func performNewDocumentSetup() {
        self.modelController.disableUndo {
            let page = self.modelController.createPage(in: self.modelController.rootFolder) {
                $0.title = NSLocalizedString("First Page", comment: "New document first page title")
            }
            let canvas = self.modelController.createCanvas()
            canvas.addPages([page])

            self.updateSelection([.canvas(canvas.id)])
        }
    }

    #if TEST
    var proEnabled: Bool = true
    #else
    var proEnabled: Bool {
        return CoppiceSubscriptionManager.shared.activationResponse?.isActive == true
    }
    #endif


    //MARK: - Search
    @objc dynamic var searchString: String?


    //MARK: - Selection Logic
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

    private var updateSelection = true
    func performWithoutUpdatingSelection<T>(_ block: () -> T) -> T {
        self.updateSelection = false
        let result = block()
        self.updateSelection = true
        return result
    }


    //MARK: - Editor Logic
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
            guard let page = self.modelController.pageCollection.objectWithID(modelID) else {
                self.currentEditor = .none
                return
            }
            self.currentEditor = .page(page)
        //Don't bother changing for a folder
        case .folder:
            return
        }
    }

    //MARK: - Navigation Stack
    struct NavStack {
        let editor: Editor
        let sidebarSelection: [SidebarItem]
        let selectedCanvasID: ModelID?
    }

    private var currentNavStack: NavStack?

    func saveNavigation() {
        guard self.currentNavStack == nil else {
            return
        }
        self.currentNavStack = NavStack(editor: self.currentEditor, sidebarSelection: self.sidebarSelection, selectedCanvasID: self.selectedCanvasID)
    }

    func restoreNavigation() {
        guard let stack = self.currentNavStack else {
            return
        }
        self.selectedCanvasID = stack.selectedCanvasID
        self.sidebarSelection = stack.sidebarSelection
        self.currentEditor = stack.editor

        self.currentNavStack = nil
    }

    func clearSavedNavigation() {
        self.currentNavStack = nil
    }


    //MARK: - Observation
    var canvasObserver: ModelCollection<Canvas>.Observation?
    var folderObserver: ModelCollection<Folder>.Observation?
    var pageObserver: ModelCollection<Page>.Observation?
    private func setupObservation() {
        self.canvasObserver = self.modelController.canvasCollection.addObserver { [weak self] (change) in
            self?.handleCanvasChange(change)
        }

        self.folderObserver = self.modelController.folderCollection.addObserver { [weak self] (change) in
            self?.handleFolderChange(change)
        }

        self.pageObserver = self.modelController.pageCollection.addObserver { [weak self] (change) in
            self?.handlePageChange(change)
        }
    }

    private func cleanUpObserveration() {
        if let observer = self.canvasObserver {
            self.modelController.canvasCollection.removeObserver(observer)
        }

        if let observer = self.folderObserver {
            self.modelController.folderCollection.removeObserver(observer)
        }

        if let observer = self.pageObserver {
            self.modelController.pageCollection.removeObserver(observer)
        }
    }

    private func handleCanvasChange(_ change: ModelCollection<Canvas>.Change) {
        guard self.updateSelection else {
            return
        }
        switch change.changeType {
        case .insert:
            self.selectedCanvasID = change.object.id
            self.updateSelection([.canvases])
        case .delete:
            if self.selectedCanvasID == change.object.id {
                self.selectedCanvasID = nil
            }
        default:
            break
        }
    }

    private func handleFolderChange(_ change: ModelCollection<Folder>.Change) {
        guard self.updateSelection else {
            return
        }
        guard self.currentEditor != .canvas else {
            return
        }

        switch change.changeType {
        case .insert:
            break
        case .delete:
            let newSelection = self.sidebarSelection.filter { $0 != .folder(change.object.id) }
            self.updateSelection(newSelection)
        default:
            break
        }
    }

    private func handlePageChange(_ change: ModelCollection<Page>.Change) {
        guard self.updateSelection else {
            return
        }
        guard self.currentEditor != .canvas else {
            return
        }

        switch change.changeType {
        case .insert:
            self.updateSelection([.page(change.object.id)])
        case .delete:
            let newSelection = self.sidebarSelection.filter { $0 != .page(change.object.id) }
            self.updateSelection(newSelection)
        default:
            break
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
            self.currentEditor = Editor.from(persistentRepresentation: currentEditorString, pagesCollection: self.modelController.pageCollection)
        }
    }



    //MARK: - New Page Helpers
    @Published var lastCreatePageType: PageContentType = .text

    var canvasForNewPages: Canvas? {
        guard self.sidebarSelection.firstIndex(of: .canvases) != nil else {
            return nil
        }

        guard let selectedCanvasID = self.selectedCanvasID else {
            return nil
        }

        return self.modelController.canvasCollection.objectWithID(selectedCanvasID)
    }

    var folderForNewPages: Folder {
        guard
            self.proEnabled,
            let selection = self.sidebarSelection.last(where: { $0 != .canvases })
        else {
            return self.modelController.rootFolder
        }

        switch selection {
        case .canvases, .canvas:
            return self.modelController.rootFolder
        case .page(let modelID):
            return self.modelController.pageCollection.objectWithID(modelID)?.containingFolder ?? self.modelController.rootFolder
        case .folder(let modelID):
            return self.modelController.folderCollection.objectWithID(modelID) ?? self.modelController.rootFolder
        }
    }


    //MARK: - Deleting Sidebar Items
    func deleteItems(_ folderItems: [FolderContainable]) {
        guard let alert = self.alertForDeleting(folderItems) else {
            self.modelController.delete(folderItems)
            return
        }

        self.window?.showAlert(alert, callback: { (index) in
            let (type, _) = alert.buttons[index]
            if (type == .confirm) {
                self.modelController.delete(folderItems)
            }
        })
    }




    //MARK: - Deleting Canvas
    func delete(_ canvas: Canvas) {
        guard let alert = alertForDeleting(canvas) else {
            self.modelController.delete(canvas)
            return
        }

        self.window?.showAlert(alert, callback: { (index) in
            let (type, _) = alert.buttons[index]
            if (type == .confirm) {
                self.modelController.delete(canvas)
            }
        })
    }


    //MARK: - Navigating Pages

    /// Opens the page
    /// - Parameter pageLink: The PageLink to handle
    /// - Returns: True if the page link was handled, false if it wasn't
    @discardableResult func openPage(at pageLink: PageLink) -> Bool {
        guard self.modelController.object(with: pageLink.destination) != nil else {
            return false
        }

        self.updateSelection([.page(pageLink.destination)])
        return true
    }


    //MARK: - Undo
    var previousSelectionAtStartOfEditing: ([SidebarItem], ModelID?)? = nil
    func registerStartOfEditing() {
        //If there's no previous selection then we've just opened the document
        guard let previousSelection = self.previousSelectionAtStartOfEditing else {
            self.previousSelectionAtStartOfEditing = (self.sidebarSelection, self.selectedCanvasID)
            return
        }
        let (previousItems, previousCanvasID) = previousSelection
        //We only want to register an undo if the selection has changed since the last time we edited something
        guard (previousItems != self.sidebarSelection) || (previousCanvasID != self.selectedCanvasID) else {
            return
        }
        //Wrap this in its own group to avoid the event coalescing
        self.modelController.undoManager.beginUndoGrouping()
        self.modelController.undoManager.registerUndo(withTarget: self) { (target) in
            target.undoableUpdateSelection(previousItems, selectedCanvasID: previousCanvasID)
        }
        self.modelController.undoManager.setActionIsDiscardable(true)
        self.modelController.undoManager.setActionName("Select Item")
        self.modelController.undoManager.endUndoGrouping()

        self.previousSelectionAtStartOfEditing = (self.sidebarSelection, self.selectedCanvasID)
    }

    private func undoableUpdateSelection(_ sidebarItems: [SidebarItem], selectedCanvasID: ModelID?) {
        let oldItems = self.sidebarSelection
        let oldCanvasID = self.selectedCanvasID
        self.updateSelection(sidebarItems)
        self.selectedCanvasID = selectedCanvasID
        self.modelController.undoManager.registerUndo(withTarget: self) { (target) in
            target.undoableUpdateSelection(oldItems, selectedCanvasID: oldCanvasID)
        }
    }
}


//MARK: - Alerts
extension DocumentWindowViewModel {
    //MARK: - SidebarItems
    private func alertForDeleting(_ folderItems: [FolderContainable]) -> Alert? {
        guard folderItems.count <= 1 else {
            return self.alertForDeletingMultipleItems(folderItems)
        }

        if let page = folderItems.first as? Page {
            return self.alertForDeletingSinglePage(page)
        } else if let folder = folderItems.first as? Folder {
            return self.alertForDeletingSingleFolder(folder)
        }
        return nil
    }

    private func alertForDeletingSinglePage(_ page: Page) -> Alert? {
        let canvases = Set(page.canvasPages.compactMap { $0.canvas })
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

    private func alertForDeletingMultipleItems(_ items: [FolderContainable]) -> Alert? {
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

    //MARK: - Canvas
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
}



//MARK: - Types
extension DocumentWindowViewModel {
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
                let modelID = ModelID(string: components[1])
            else {
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
}
