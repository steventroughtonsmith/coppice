//
//  SidebarViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class SidebarViewController: NSViewController, NSMenuItemValidation, SplitViewContainable {
    @objc dynamic let viewModel: SidebarViewModel

    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "SidebarView", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    @IBOutlet weak var outlineView: NSOutlineView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.outlineView.registerForDraggedTypes([.fileURL, ModelID.PasteboardType])

        self.setupContextMenu()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.startObserving()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }


    //MARK: - RootViewController
    lazy var splitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(sidebarWithViewController: self)
        return item
    }()


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
        guard self.outlineView.clickedRow > -1 else {
            return
        }
        guard let cell = self.outlineView.view(atColumn: 0, row: self.outlineView.clickedRow, makeIfNecessary: false) as? EditableLabelCell else {
            return
        }
        cell.startEditing()
    }

    @IBAction func deleteItems(_ sender: Any) {
        self.viewModel.delete(self.nodesForAction.nodes)
    }

    @IBAction func exportPages(_ sender: Any?) {
        guard self.view.window != nil else {
            return
        }
//        PageExporter.export(self.viewModel.selectedPages, displayingOn: window)
    }

    @IBAction func addToCanvas(_ sender: Any?) {
        guard (sender as? NSMenuItem) != nil else {
            return
        }

//        self.viewModel.addPages(atIndexes: self.pageRowIndexesForAction, toCanvasAtindex: menuItem.tag)
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

        if menuItem.action == #selector(exportPages(_:)) {
//            let pages = self.viewModel.pageItems[self.pageRowIndexesForAction].map { $0.page }
//            return PageExporter.validate(menuItem, forExporting: pages)
        }

        if menuItem.action == #selector(addToCanvas(_:)) {
            return (self.nodesForAction.count > 0)
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
    private var nodesForAction: SidebarNodeCollection {
        let selectedIndexes = self.outlineView.selectedRowIndexes
        let clickedRow = self.outlineView.clickedRow

        if selectedIndexes.contains(clickedRow) || (clickedRow == -1) {
            return self.selectedNodes
        }
        let collection = SidebarNodeCollection()
        if clickedRow >= 0, let clickedNode = self.outlineView.item(atRow: clickedRow) as? SidebarNode {
            collection.add(clickedNode)
        }
        return collection
    }


    //MARK: - Reload
    private var createdItem: DocumentWindowViewModel.SidebarItem?
    private func reloadSidebarNodes() {
        let selectedItems = self.outlineView.selectedRowIndexes.compactMap { self.outlineView.item(atRow: $0) }
        self.outlineView.reloadItem(nil, reloadChildren: true)
        let selectedIndexes = selectedItems.map { self.outlineView.row(forItem: $0) }.filter { $0 > -1 }
        self.outlineView.selectRowIndexes(IndexSet(selectedIndexes), byExtendingSelection: false)

        self.handleNewItem()
    }

    private func handleNewItem() {
        guard let item = self.createdItem else {
            return
        }
        self.outlineView.expandItem(self.viewModel.pagesGroupNode)
        if let sidebarNode = self.viewModel.node(for: item) {
            let index = self.outlineView.row(forItem: sidebarNode)
            self.outlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        }

        self.createdItem = nil
    }


    //MARK: - Selection
    var selectedNodes: SidebarNodeCollection {
        let collection = SidebarNodeCollection()
        self.outlineView.selectedRowIndexes.forEach {
            if let node = self.outlineView.item(atRow: $0) as? SidebarNode {
                collection.add(node)
            }
        }
        return collection
    }

}


extension SidebarViewController: SidebarView {
    func reload() {
        self.reloadSidebarNodes()
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



extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard item != nil else {
            return self.viewModel.rootSidebarNodes.count
        }
        guard let sidebarItem = item as? SidebarNode else {
            return 0
        }
        return sidebarItem.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard item != nil else {
            return self.viewModel.rootSidebarNodes[index]
        }
        guard let sidebarItem = item as? SidebarNode else {
            preconditionFailure("Encountered an item that isn't a sidebar item: \(item!)")
        }
        return sidebarItem.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let sidebarItem = item as? SidebarNode else {
            return false
        }
        return (sidebarItem.children.count > 0)
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let sidebarItem = item as? SidebarNode else {
            return true
        }
        switch sidebarItem.cellType {
        case .bigCell, .smallCell:
            return true
        case .groupCell:
            return false
        }
    }

    func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        guard let sidebarNode = item as? SidebarNode else {
            return nil
        }

        return sidebarNode.item.persistentRepresentation
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
        guard let sidebarNode = item as? SidebarNode else {
            return nil
        }
        return sidebarNode.pasteboardWriter
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        //If we have an item but it's not a sidebar node then something has gone wrong
        if (item != nil) && ((item as? SidebarNode) == nil) {
            return []
        }

        guard let types = info.draggingPasteboard.types, let items = info.draggingPasteboard.pasteboardItems else {
            return []
        }

        if types.contains(ModelID.PasteboardType) {
            let modelIDs = items.compactMap { ModelID(pasteboardItem: $0) }
            let (canDrop, targetNode, targetIndex) = self.viewModel.canDropItems(with: modelIDs, onto: (item as? SidebarNode), atChildIndex: index)
            guard canDrop else {
                return []
            }
            outlineView.setDropItem(targetNode, dropChildIndex: targetIndex)
            return .generic
        }
        if types.contains(.fileURL) {
            let fileURLs = items.compactMap { $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil)}
            let (canDrop, targetNode, targetIndex) = self.viewModel.canDropFiles(at: fileURLs, onto: (item as? SidebarNode), atChildIndex: index)
            guard canDrop else {
                return []
            }
            outlineView.setDropItem(targetNode, dropChildIndex: targetIndex)
            return .generic
        }

        return []
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        if (item != nil) && ((item as? SidebarNode) == nil) {
            return false
        }

        guard let types = info.draggingPasteboard.types, let items = info.draggingPasteboard.pasteboardItems else {
            return false
        }

        if types.contains(ModelID.PasteboardType) {
            let modelIDs = items.compactMap { ModelID(pasteboardItem: $0) }
            return self.viewModel.dropItems(with: modelIDs, onto: (item as? SidebarNode), atChildIndex: index)
        }

        if types.contains(.fileURL) {
            let fileURLs = items.compactMap { $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil)}
            return self.viewModel.dropFiles(at: fileURLs, onto: (item as? SidebarNode), atChildIndex: index)
        }

        return false
    }
}


extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let sidebarItem = item as? SidebarNode else {
            return false
        }
        switch sidebarItem.cellType {
        case .bigCell, .smallCell:
            return false
        case .groupCell:
            return true
        }
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let sidebarItem = item as? SidebarNode else {
            return nil
        }
        let view: NSTableCellView?
        switch sidebarItem.cellType {
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
        guard let sidebarItem = item as? SidebarNode else {
            return 22
        }
        switch sidebarItem.cellType {
        case .bigCell:
            return 34
        case .smallCell, .groupCell:
            return 22
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.viewModel.updateSelectedNodes(self.selectedNodes.nodes)
    }
}






//extension SidebarViewController: NSMenuDelegate {
//    func numberOfItems(in menu: NSMenu) -> Int {
//        if (menu.identifier == NSUserInterfaceItemIdentifier("SortPagesMenu")) {
//            return SidebarViewModel.PageSortKey.allCases.count
//        }
//        return self.viewModel.canvasItems.count
//    }
//
//    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
//        if (menu.identifier == NSUserInterfaceItemIdentifier("SortPagesMenu")) {
//            let sortKey = SidebarViewModel.PageSortKey.allCases[index]
//            item.title = sortKey.localizedName
//            item.representedObject = sortKey.rawValue
//            item.state = (self.viewModel.sortKey == sortKey) ? .on : .off
//            item.target = self
//            item.action = #selector(changePageSorting(_:))
//            return true
//        }
//
//        item.title = self.viewModel.canvasItems[index].canvas.title
//        item.tag = index
//        item.target = self
//        item.action = #selector(addToCanvas(_:))
//        return true
//    }
//}
