//
//  SourceListViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data
import UniformTypeIdentifiers

class SourceListViewController: NSViewController, NSMenuItemValidation {
    @objc dynamic let viewModel: SourceListViewModel

    init(viewModel: SourceListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "SourceListView", bundle: nil)
        self.viewModel.view = self

        UserDefaults.standard.addObserver(self, forKeyPath: "NSTableViewDefaultSizeMode", options: [], context: nil)
        UserDefaults.standard.addObserver(self, forKeyPath: "M3SidebarSize", options: [], context: nil)
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    deinit {
        UserDefaults.standard.removeObserver(self, forKeyPath: "NSTableViewDefaultSizeMode")
        UserDefaults.standard.removeObserver(self, forKeyPath: "M3SidebarSize")
    }

    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var outlineScrollView: NSScrollView!
    @IBOutlet weak var bottomBarConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.outlineView.registerForDraggedTypes([.fileURL, ModelID.PasteboardType])
        self.outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)

        self.setupSortFolderMenu()
        self.setupContextMenu()

        self.bottomBarConstraint.constant = GlobalConstants.bottomBarHeight
        self.setupAccessibility()

        if #available(OSX 10.16, *) {
            self.outlineScrollView.automaticallyAdjustsContentInsets = true
            self.outlineScrollView.additionalSafeAreaInsets = NSEdgeInsets(top: 5, left: 0, bottom: 0, right: 0)
        }
        self.restorePageGroup()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.startObserving()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        guard let visualEffectView = self.view.superview?.superview as? NSVisualEffectView else {
            return
        }

        //We need this to ensure that the text and icons draw the correct colour on Catalina, otherwise they are a bit washed out
        visualEffectView.state = .active
        visualEffectView.state = .followsWindowActiveState
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }


    //MARK: - New Document
    private var needsNewDocumentSetup = false
    func performNewDocumentSetup() {
        self.needsNewDocumentSetup = true
    }

    private func newDocumentSetup() {
        guard self.needsNewDocumentSetup else {
            return
        }

        self.outlineView.expandItem(self.viewModel.pagesGroupNode)
        self.needsNewDocumentSetup = false
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

        self.actionPullDownButton.menu?.items.first?.image = NSImage.symbol(withName: Symbols.Toolbars.action)

        self.outlineView.menu = contextMenu
    }


    //MARK: - Create Menu Actions
    @IBAction func newPage(_ sender: Any?) {
        var type: Page.ContentType? = nil
        //If the sender is a menu item then get the represented object. Otherwise we'll use nil and use the last created type
        if let rawType = (sender as? NSMenuItem)?.representedObject as? String {
            type = Page.ContentType(rawValue: rawType)
        } else if let rawIdentifier = (sender as? NSTouchBarItem)?.identifier.rawValue {
            type = Page.ContentType(rawValue: rawIdentifier)
        }
        self.createdItem = self.viewModel.createPage(ofType: type, underNodes: self.nodesForAction)
    }

    @IBAction func newFolder(_ sender: Any) {
        self.createdItem = self.viewModel.createFolder(underNodes: self.nodesForAction)
    }

    @IBAction func newFolderFromSelection(_ sender: Any) {
        self.createdItem = self.viewModel.createFolder(usingSelection: self.nodesForAction)
    }

    @IBAction func duplicatePage(_ sender: Any) {
        let pageNodes = self.viewModel.duplicatePages(inNodes: self.nodesForAction)
        if (pageNodes.count == 1) {
            self.createdItem = pageNodes[0]
        } else {
            self.viewModel.documentWindowViewModel.updateSelection(pageNodes)
        }
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
        panel.allowedContentTypes = [.text, .image]
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
        if menuItem.action == #selector(self.newPage(_:)) {
            return true
        }

        let proEnabled = (CoppiceSubscriptionManager.shared.state == .enabled)

        if menuItem.action == #selector(self.newFolder(_:)) {
            menuItem.image = proEnabled ? nil : CoppiceProUpsell.shared.proImage
            menuItem.toolTip = proEnabled ? nil  : CoppiceProUpsell.shared.proTooltip
            return proEnabled
        }

        if menuItem.action == #selector(self.newFolderFromSelection(_:)) {
            menuItem.image = proEnabled ? nil : CoppiceProUpsell.shared.proImage
            menuItem.toolTip = proEnabled ? nil  : CoppiceProUpsell.shared.proTooltip

            let selection = self.nodesForAction
            guard selection.count > 0 else {
                return false
            }
            return selection.nodesShareParent && proEnabled
        }

        if menuItem.action == #selector(self.editItemTitle(_:)) {
            let nodesCollection = self.nodesForAction
            return (nodesCollection.count == 1) && (nodesCollection.containsCanvases == false)
        }

        if menuItem.action == #selector(self.duplicatePage(_:)) {
            let nodesCollection = self.nodesForAction
            menuItem.title = (nodesCollection.count == 1) ? NSLocalizedString("Duplicate Page", comment: "Duplicate single page menu item title")
                                                          : NSLocalizedString("Duplicate Pages", comment: "Duplicate multiple pages menu item title")
            return (nodesCollection.containsPages == true) && (nodesCollection.containsFolders == false)
        }

        if menuItem.action == #selector(self.deleteItems(_:)) {
            return self.validateDeleteItemMenuItem(menuItem)
        }

        if menuItem.action == #selector(self.importFiles(_:)) {
            return true
        }

        if menuItem.action == #selector(self.exportPages(_:)) {
            return PageExporter.validate(menuItem, forExporting: self.nodesForAction)
        }

        if menuItem.action == #selector(self.sortFolder(_:)) {
            let selection = self.nodesForAction
            return (selection.count == 1) && selection.containsFolders
        }

        if menuItem.action == #selector(self.addToCanvas(_:)) {
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
        } else if nodes.containsFolders && !nodes.containsPages {
            menuItem.title = NSLocalizedString("Delete Folders", comment: "Delete multiple folders menu item")
        } else {
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
        self.restorePageGroup()

        self.reloadSelection()
        self.handleNewItem()
        self.newDocumentSetup()
    }

    private func restorePageGroup() {
        if (self.viewModel.isPageGroupNodeExpanded) {
            self.outlineView.expandItem(self.viewModel.pagesGroupNode)
        } else {
            self.outlineView.collapseItem(self.viewModel.pagesGroupNode)
        }
    }

    private func handleNewItem() {
        guard let item = self.createdItem else {
            return
        }
        //Always run this if we exit
        defer {
            self.createdItem = nil
        }

        self.outlineView.expandItem(self.viewModel.pagesGroupNode)

        guard let sourceListNode = self.viewModel.node(for: item) else {
            return
        }

        self.outlineView.expandItem(sourceListNode.parent)

        let index = self.outlineView.row(forItem: sourceListNode)
        guard
            (index >= 0),
            let view = self.outlineView.view(atColumn: 0, row: index, makeIfNecessary: true) as? EditableLabelCell
        else {
            return
        }

        if case .folder = sourceListNode.item {
            view.startEditing()
            return
        }

        //We don't want to select the new item if we're in a canvas, as we don't want to switch the editor
        guard !self.selectedNodes.containsCanvases else {
            return
        }

        self.outlineView.selectRowIndexes(IndexSet(integer: index), byExtendingSelection: false)
        view.startEditing()
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
        } else if let folder = (selection.nodes[0] as? PagesGroupSourceListNode)?.rootFolder {
            folder.sort(using: sortMethod)
        }
    }


    //MARK: - Accessibility
    private func setupAccessibility() {
        guard
            let scrollView = self.outlineScrollView,
            let addButton = self.addPullDownButton,
            let actionButton = self.actionPullDownButton
        else {
            return
        }

        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(NSLocalizedString("Sidebar", comment: "Sidebar accessibility label"))
        self.view.setAccessibilityChildren([scrollView, addButton, actionButton])
    }




    //MARK: - Row Size
    var activeSidebarSize: ActiveSidebarSize {
        guard
            let sidebarSizeString = UserDefaults.standard.string(forKey: .sidebarSize),
            let sidebarSize = SidebarSize(rawValue: sidebarSizeString)
        else {
            return .medium
        }
        return ActiveSidebarSize(sidebarSize: sidebarSize)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        self.outlineView.reloadData()
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
        case .navCell, .smallCell:
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
            let persistentRepresentation = DocumentWindowViewModel.SidebarItem.from(persistentRepresentation: string)
        else {
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
            let optionHeld = NSApp.currentEvent?.modifierFlags.contains(.option) ?? false
            let (canDrop, targetNode, targetIndex) = self.viewModel.canDropItems(with: modelIDs, onto: (item as? SourceListNode), atChildIndex: index, mode: optionHeld ? .copy : .move)
            guard canDrop else {
                return []
            }
            outlineView.setDropItem(targetNode, dropChildIndex: targetIndex)
            return optionHeld ? .copy : .move
        }
        if types.contains(.fileURL) {
            let fileURLs = items.compactMap { $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
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
            let optionHeld = NSApp.currentEvent?.modifierFlags.contains(.option) ?? false
            return self.viewModel.dropItems(with: modelIDs, onto: (item as? SourceListNode), atChildIndex: index, mode: optionHeld ? .copy : .move)
        }

        if types.contains(.fileURL) {
            let fileURLs = items.compactMap { $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
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
        case .navCell, .smallCell:
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
        case .navCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("BigCell"), owner: self) as? NSTableCellView
        case .smallCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SmallCell"), owner: self) as? SourceListTableCellView
        case .groupCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("GroupCell"), owner: self) as? NSTableCellView
        }
        view?.setAccessibilityLabel(sourceListItem.accessibilityDescription)
        (view as? SidebarSizable)?.activeSidebarSize = self.activeSidebarSize
        sourceListItem.activeSidebarSize = self.activeSidebarSize
        view?.objectValue = item
        return view
    }

    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let sourceListItem = item as? SourceListNode else {
            return nil
        }

        switch sourceListItem.cellType {
        case .navCell:
            let rowView = SpringLoadedTableRowView()
            rowView.delegate = self
            return rowView
        default:
            return nil
        }
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let sourceListItem = item as? SourceListNode else {
            return self.activeSidebarSize.smallRowHeight
        }
        switch sourceListItem.cellType {
        case .navCell:
            return self.activeSidebarSize.largeRowHeight
        case .smallCell, .groupCell:
            return self.activeSidebarSize.smallRowHeight
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.viewModel.selectedNodes = self.selectedNodes.nodes
    }

    func outlineViewItemDidExpand(_ notification: Notification) {
        guard (notification.userInfo?["NSObject"] as? PagesGroupSourceListNode) != nil else {
            return
        }
        self.viewModel.isPageGroupNodeExpanded = true
    }

    func outlineViewItemDidCollapse(_ notification: Notification) {
        guard (notification.userInfo?["NSObject"] as? PagesGroupSourceListNode) != nil else {
            return
        }
        self.viewModel.isPageGroupNodeExpanded = false
    }
}

extension SourceListViewController: SpringLoadedTableRowViewDelegate {
    func userDidSpringLoad(on rowView: SpringLoadedTableRowView) {
        guard
            let navigationCell = rowView.view(atColumn: 0) as? NSTableCellView,
            let node = navigationCell.objectValue as? SourceListNode
        else {
            return
        }
        self.viewModel.springLoadedNode = node
        self.reloadSelection()
    }

    func springLoadedDragEnded(_ rowView: SpringLoadedTableRowView) {
        self.viewModel.springLoadedNode = nil
        self.reloadSelection()
    }
}






extension SourceListViewController: NSMenuDelegate {
    func numberOfItems(in menu: NSMenu) -> Int {
        return self.viewModel.canvases.count
    }

    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool { //
        let canvas = self.viewModel.canvases[index]
        item.title = canvas.title
        item.representedObject = canvas
        item.target = self
        item.action = #selector(self.addToCanvas(_:))
        return true
    }
}
