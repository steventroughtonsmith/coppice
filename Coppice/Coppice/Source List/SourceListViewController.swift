//
//  SourceListViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class SourceListViewController: NSViewController, NSMenuItemValidation {
    @objc dynamic let viewModel: SourceListViewModel

    init(viewModel: SourceListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "SourceListView", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var bottomBarConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.outlineView.registerForDraggedTypes([.fileURL, ModelID.PasteboardType])
        self.outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)

        self.setupSortFolderMenu()
        self.setupContextMenu()

        self.bottomBarConstraint.constant = GlobalConstants.bottomBarHeight
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.startObserving()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }


    //MARK: - Keyboard shortcuts
    override func keyDown(with event: NSEvent) {
        guard let specialKey = event.specialKey else {
            super.keyDown(with: event)
            return
        }

        //For some reason NSEvent.SpecialKey.delete does not use NSDeleteFunctionKey, but NSEvent does
        guard (specialKey == .backspace) || (specialKey == .delete) || (specialKey == .deleteForward) else {
            super.keyDown(with: event)
            return
        }

        self.viewModel.delete(self.selectedNodes.nodes)
    }


    //MARK: - Menus
    @IBOutlet weak var addPullDownButton: NSPopUpButton!
    @IBOutlet weak var actionPullDownButton: NSPopUpButton!
    @IBOutlet var newPageMenuDelegate: NewPageMenuDelegate!

    private func setupContextMenu() {
        let contextMenu = NSMenu()

        if let addMenuItems = self.addPullDownButton.menu?.items {
            (1..<addMenuItems.count).forEach {
                contextMenu.addItem(addMenuItems[$0].copy() as! NSMenuItem)
            }
        }
        contextMenu.addItem(NSMenuItem.separator())

        if let actionMenuItems = self.actionPullDownButton.menu?.items {
            (1..<actionMenuItems.count).forEach {
                contextMenu.addItem(actionMenuItems[$0].copy() as! NSMenuItem)
            }
        }

        self.outlineView.menu = contextMenu
    }


    //MARK: - Create Menu Actions
    @IBAction func newPage(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem,
            let rawType = menuItem.representedObject as? String,
            let type = PageContentType(rawValue: rawType) else {
                self.createdItem = self.viewModel.createPage(ofType: .text, underNodes: self.nodesForAction)
                return
        }
        self.createdItem = self.viewModel.createPage(ofType: type, underNodes: self.nodesForAction)
    }

    @IBAction func newFolder(_ sender: Any) {
        self.createdItem = self.viewModel.createFolder(underNodes: self.nodesForAction)
    }

    @IBAction func newFolderFromSelection(_ sender: Any) {
        self.createdItem = self.viewModel.createFolder(usingSelection: self.selectedNodes)
    }


    //MARK: - Action Menu Actions
    @IBAction func editItemTitle(_ sender: Any) {
        let nodes = self.nodesForAction
        guard nodes.count == 1, let node = nodes.nodes.first else {
            return
        }
        let row = self.outlineView.row(forItem: node)
        guard row > -1 else {
            return
        }
        guard let cell = self.outlineView.view(atColumn: 0, row: row, makeIfNecessary: false) as? EditableLabelCell else {
            return
        }
        cell.startEditing()
    }

    @IBAction func deleteItems(_ sender: Any) {
        self.viewModel.delete(self.nodesForAction.nodes)
    }

    @IBAction func addToCanvas(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem, let canvas = menuItem.representedObject as? Canvas else {
            return
        }

        self.viewModel.addNodes(self.nodesForAction, to: canvas)
    }

    @IBAction func importFiles(_ sender: Any?) {
        guard let window = self.view.window else {
            return
        }
        let nodes = self.nodesForAction
        let panel = NSOpenPanel()
        panel.allowedFileTypes = [kUTTypeText as String, kUTTypeImage as String]
        panel.allowsMultipleSelection = true
        panel.prompt = NSLocalizedString("Import", comment: "Import button title")
        panel.beginSheetModal(for: window) { [weak self] (response) in
            guard response == .OK else {
                return
            }
            self?.viewModel.createPages(fromFilesAt: panel.urls, underNodes: nodes)
        }
    }

    @IBAction func exportPages(_ sender: Any?) {
        guard let window = self.view.window else {
            return
        }
        PageExporter.export(self.nodesForAction, displayingOn: window)
    }


    //MARK: - Menu Validation
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(newPage(_:)) ||
           menuItem.action == #selector(newFolder(_:)) {
            return true
        }

        if menuItem.action == #selector(newFolderFromSelection(_:)) {
            let selection = self.nodesForAction
            guard selection.count > 0 else {
                return false
            }
            return selection.nodesShareParent
        }

        if menuItem.action == #selector(editItemTitle(_:)) {
            let nodesCollection = self.nodesForAction
            return (nodesCollection.count == 1) && (nodesCollection.containsCanvases == false)
        }

        if menuItem.action == #selector(deleteItems(_:)) {
            return self.validateDeleteItemMenuItem(menuItem)
        }

        if menuItem.action == #selector(importFiles(_:)) {
            return true
        }

        if menuItem.action == #selector(exportPages(_:)) {
            return PageExporter.validate(menuItem, forExporting: self.nodesForAction)
        }

        if menuItem.action == #selector(sortFolder(_:)) {
            let selection = self.nodesForAction
            return (selection.count == 1) && selection.containsFolders
        }

        if menuItem.action == #selector(addToCanvas(_:)) {
            return (self.nodesForAction.count > 0)
                && (self.nodesForAction.containsFolders == false)
                && (self.nodesForAction.containsCanvases == false)
        }
        
        return false
    }

    private func validateDeleteItemMenuItem(_ menuItem: NSMenuItem) -> Bool {
        let nodes = self.nodesForAction

        guard nodes.containsCanvases == false else {
            return false
        }

        if nodes.count == 1 {
            if nodes.containsPages {
                menuItem.title = NSLocalizedString("Delete Page", comment: "Delete single page menu item")
                return true
            }
            if nodes.containsFolders {
                menuItem.title = NSLocalizedString("Delete Folder", comment: "Delete single folder menu item")
                return true
            }
            return false
        }

        if nodes.containsPages && !nodes.containsFolders {
            menuItem.title = NSLocalizedString("Delete Pages", comment: "Delete multiple pages menu item")
        }
        else if nodes.containsFolders && !nodes.containsPages {
            menuItem.title = NSLocalizedString("Delete Folders", comment: "Delete multiple folders menu item")
        }
        else {
            menuItem.title = NSLocalizedString("Delete Items", comment: "Delete multiple items menu item")
        }
        return (nodes.count > 1)
    }


    //MARK: - Action Items
    private var nodesForAction: SourceListNodeCollection {
        let selectedIndexes = self.outlineView.selectedRowIndexes
        let clickedRow = self.outlineView.clickedRow

        if selectedIndexes.contains(clickedRow) || (clickedRow == -1) {
            return self.selectedNodes
        }
        let collection = SourceListNodeCollection()
        if clickedRow >= 0, let clickedNode = self.outlineView.item(atRow: clickedRow) as? SourceListNode {
            collection.add(clickedNode)
        }
        return collection
    }


    //MARK: - Reload
    private var createdItem: DocumentWindowViewModel.SidebarItem?
    private func reloadSourceListNodes() {
        self.outlineView.reloadItem(nil, reloadChildren: true)

        self.reloadSelection()
        self.handleNewItem()
    }

    private func handleNewItem() {
        guard let item = self.createdItem else {
            return
        }
        self.outlineView.expandItem(self.viewModel.pagesGroupNode)
        
        //We don't want to select the new item if we're in a canvas, as we don't want to switch the editor
        guard !self.selectedNodes.containsCanvases else {
            return
        }
        if let sourceListNode = self.viewModel.node(for: item) {
            let index = self.outlineView.row(forItem: sourceListNode)
            self.outlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }

        self.createdItem = nil
    }

    func reloadSelection() {
        let selectedIndexes = self.viewModel.selectedNodes.map { self.outlineView.row(forItem: $0) }.filter { $0 > -1 }
        self.outlineView.selectRowIndexes(IndexSet(selectedIndexes), byExtendingSelection: false)
    }


    //MARK: - Selection
    var selectedNodes: SourceListNodeCollection {
        let collection = SourceListNodeCollection()
        self.outlineView.selectedRowIndexes.forEach {
            if let node = self.outlineView.item(atRow: $0) as? SourceListNode {
                collection.add(node)
            }
        }
        return collection
    }


    //MARK: - Folder Sorting
    @IBOutlet weak var sortFolderMenu: NSMenu!
    private func setupSortFolderMenu() {
        self.sortFolderMenu.items = Folder.SortingMethod.allCases.enumerated().map { (index, element) in
            let menuItem = NSMenuItem(title: element.localizedString, action: #selector(sortFolder(_:)), keyEquivalent: "")
            menuItem.target = self
            menuItem.tag = index
            return menuItem
        }
    }

    @IBAction func sortFolder(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else {
            return
        }
        
        let selection = self.nodesForAction
        guard (selection.count == 1) && selection.containsFolders else {
            return
        }

        guard let sortMethod = Folder.SortingMethod.allCases[safe: menuItem.tag] else {
            return
        }

        if let folder = (selection.nodes[0] as? FolderSourceListNode)?.folder {
            folder.sort(using: sortMethod)
        }
        else if let folder = (selection.nodes[0] as? PagesGroupSourceListNode)?.rootFolder {
            folder.sort(using: sortMethod)
        }
    }

}


extension SourceListViewController: SourceListView {
    func reload() {
        self.reloadSourceListNodes()
    }

    func showAlert(_ alert: Alert, callback: @escaping (Int) -> Void) {
        guard let window = self.view.window else {
            return
        }

        alert.nsAlert.beginSheetModal(for: window) { (response) in
            callback(response.rawValue)
        }
    }
}



extension SourceListViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard item != nil else {
            return self.viewModel.rootSourceListNodes.count
        }
        guard let sourceListNode = item as? SourceListNode else {
            return 0
        }
        return sourceListNode.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard item != nil else {
            return self.viewModel.rootSourceListNodes[index]
        }
        guard let sourceListItem = item as? SourceListNode else {
            preconditionFailure("Encountered an item that isn't a source list node: \(item!)")
        }
        return sourceListItem.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let sourceListItem = item as? SourceListNode else {
            return false
        }
        return (sourceListItem.children.count > 0)
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let sourceListItem = item as? SourceListNode else {
            return true
        }
        switch sourceListItem.cellType {
        case .bigCell, .smallCell:
            return true
        case .groupCell:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        guard let sourceListNode = item as? SourceListNode else {
            return nil
        }

        return sourceListNode.item.persistentRepresentation
    }

    func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        guard let string = object as? String,
            let persistentRepresentation = DocumentWindowViewModel.SidebarItem.from(persistentRepresentation: string) else {
                return nil
        }

        return self.viewModel.node(for: persistentRepresentation)
    }


    //MARK: - Drag & Drop
    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        guard let sourceListNode = item as? SourceListNode else {
            return nil
        }
        return sourceListNode.pasteboardWriter
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        //If we have an item but it's not a source list node then something has gone wrong
        if (item != nil) && ((item as? SourceListNode) == nil) {
            return []
        }

        guard let types = info.draggingPasteboard.types, let items = info.draggingPasteboard.pasteboardItems else {
            return []
        }

        if types.contains(ModelID.PasteboardType) {
            let modelIDs = items.compactMap { ModelID(pasteboardItem: $0) }
            let (canDrop, targetNode, targetIndex) = self.viewModel.canDropItems(with: modelIDs, onto: (item as? SourceListNode), atChildIndex: index)
            guard canDrop else {
                return []
            }
            outlineView.setDropItem(targetNode, dropChildIndex: targetIndex)
            return .generic
        }
        if types.contains(.fileURL) {
            let fileURLs = items.compactMap { $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil)}
            let (canDrop, targetNode, targetIndex) = self.viewModel.canDropFiles(at: fileURLs, onto: (item as? SourceListNode), atChildIndex: index)
            guard canDrop else {
                return []
            }
            outlineView.setDropItem(targetNode, dropChildIndex: targetIndex)
            return .generic
        }

        return []
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if (item != nil) && ((item as? SourceListNode) == nil) {
            return false
        }

        guard let types = info.draggingPasteboard.types, let items = info.draggingPasteboard.pasteboardItems else {
            return false
        }

        if types.contains(ModelID.PasteboardType) {
            let modelIDs = items.compactMap { ModelID(pasteboardItem: $0) }
            return self.viewModel.dropItems(with: modelIDs, onto: (item as? SourceListNode), atChildIndex: index)
        }

        if types.contains(.fileURL) {
            let fileURLs = items.compactMap { $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil)}
            return self.viewModel.dropFiles(at: fileURLs, onto: (item as? SourceListNode), atChildIndex: index)
        }

        return false
    }
}


extension SourceListViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let sourceListItem = item as? SourceListNode else {
            return false
        }
        switch sourceListItem.cellType {
        case .bigCell, .smallCell:
            return false
        case .groupCell:
            return true
        }
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let sourceListItem = item as? SourceListNode else {
            return nil
        }
        let view: NSTableCellView?
        switch sourceListItem.cellType {
        case .bigCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("BigCell"), owner: self) as? NSTableCellView
        case .smallCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SmallCell"), owner: self) as? NSTableCellView
        case .groupCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("GroupCell"), owner: self) as? NSTableCellView
        }
        view?.objectValue = item
        return view
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let sourceListItem = item as? SourceListNode else {
            return 22
        }
        switch sourceListItem.cellType {
        case .bigCell:
            return 34
        case .smallCell, .groupCell:
            return 22
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.viewModel.selectedNodes = self.selectedNodes.nodes
    }
}






extension SourceListViewController: NSMenuDelegate {
    func numberOfItems(in menu: NSMenu) -> Int {
        return self.viewModel.canvases.count
    }

    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {//
        let canvas = self.viewModel.canvases[index]
        item.title = canvas.title
        item.representedObject = canvas
        item.target = self
        item.action = #selector(addToCanvas(_:))
        return true
    }
}
