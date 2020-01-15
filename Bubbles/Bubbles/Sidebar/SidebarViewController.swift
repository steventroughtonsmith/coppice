//
//  SidebarViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class SidebarViewController: NSViewController, NSMenuItemValidation {
    @objc dynamic let viewModel: SidebarViewModel
    private let pagesDataSource: PagesSidebarDataSource

    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
        self.pagesDataSource = PagesSidebarDataSource(viewModel: viewModel)
        super.init(nibName: "SidebarView", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var canvasesTable: NSTableView!
    @IBOutlet weak var pagesTable: NSTableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        self.pagesDataSource.tableView = self.pagesTable

        self.canvasesTable.setDraggingSourceOperationMask(.copy, forLocal: true)
        self.canvasesTable.registerForDraggedTypes([ModelID.PasteboardType, .fileURL])

        self.canvasesTable.register(NSNib(nibNamed: "SmallCanvasCell", bundle: nil), forIdentifier: SmallCanvasCell.identifier)
        self.canvasesTable.register(NSNib(nibNamed: "LargeCanvasCell", bundle: nil), forIdentifier: LargeCanvasCell.identifier)

        self.setupObservation()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.startObserving()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }


    //MARK: - Observation
    var smallCanvasCellObservation: AnyCancellable!
    private func setupObservation() {
        self.smallCanvasCellObservation = self.viewModel.publisher(for: \.useSmallCanvasCells).sink { [weak self] (_) in
            self?.canvasesTable.reloadData()
        }
    }


    //MARK: - Keyboard shortcuts
    override func keyDown(with event: NSEvent) {
        guard let specialKey = event.specialKey else {
            return
        }

        //For some reason NSEvent.SpecialKey.delete does not use NSDeleteFunctionKey, but NSEvent does
        guard (specialKey == .backspace) || (specialKey == .delete) || (specialKey == .deleteForward) else {
            return
        }

        guard let table = self.windowController?.window?.firstResponder as? NSTableView else {
            return
        }

        if table == self.canvasesTable {
            self.viewModel.deleteCanvases(atIndexes: self.viewModel.selectedCanvasRowIndexes)
        } else if table == self.pagesTable {
            self.viewModel.deletePages(atIndexes: self.viewModel.selectedPageRowIndexes)
        } else {
            NSSound.beep()
        }
    }


    //MARK: - Page Menu Actions
    @IBAction func editPageTitle(_ sender: Any) {
        guard self.pagesTable.clickedRow > -1 else {
            return
        }
        guard let cell = self.pagesTable.view(atColumn: 0, row: self.pagesTable.clickedRow, makeIfNecessary: false) as? EditableLabelCell else {
            return
        }
        cell.startEditing()
    }

    @IBAction func deletePage(_ sender: Any) {
        self.viewModel.deletePages(atIndexes: self.pageRowIndexesForAction)
    }

    @IBAction func exportPages(_ sender: Any?) {
        guard let window = self.view.window else {
            return
        }
        PageExporter.export(self.viewModel.selectedPages, displayingOn: window)
    }

    @IBAction func addToCanvas(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem else {
            return
        }

        self.viewModel.addPages(atIndexes: self.pageRowIndexesForAction, toCanvasAtindex: menuItem.tag)
    }

    @IBAction func changePageSorting(_ sender: Any?) {
        guard let menuItem = sender as? NSMenuItem,
            let sortKeyString = menuItem.representedObject as? String,
            let sortKey = SidebarViewModel.PageSortKey(rawValue: sortKeyString) else {
            return
        }
        self.viewModel.sortKey = sortKey
    }


    //MARK: - Canvas Menu Actions
    @IBAction func editCanvasTitle(_ sender: Any) {
        guard self.canvasesTable.clickedRow > -1 else {
            return
        }
        guard let cell = self.canvasesTable.view(atColumn: 0, row: self.canvasesTable.clickedRow, makeIfNecessary: false) as? EditableLabelCell else {
            return
        }
        cell.startEditing()
    }

    @IBAction func deleteCanvas(_ sender: Any) {
        self.viewModel.deleteCanvases(atIndexes: self.canvasRowIndexesForAction)
    }


    //MARK: - Context Menus
    @IBOutlet var pageContextMenu: NSMenu!
    @IBOutlet var canvasContextMenu: NSMenu!


    //MARK: - Menu Validation
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(editPageTitle(_:)) {
            return (self.pagesTable.clickedRow >= 0)
        }

        if menuItem.action == #selector(deletePage(_:)) {
            let rowIndexes = self.pageRowIndexesForAction
            if (rowIndexes.count == 1) {
                menuItem.title = NSLocalizedString("Delete Page…", comment: "Delete single page menu item title")
            } else {
                menuItem.title = NSLocalizedString("Delete Pages…", comment: "Delete multiple pages menu item title")
            }
            return (rowIndexes.count > 0)
        }

        if menuItem.action == #selector(exportPages(_:)) {
            let pages = self.viewModel.pageItems[self.pageRowIndexesForAction].map { $0.page }
            return PageExporter.validate(menuItem, forExporting: pages)
        }

        if menuItem.action == #selector(addToCanvas(_:)) {
            return (self.pageRowIndexesForAction.count > 0)
        }

        if menuItem.action == #selector(editCanvasTitle(_:)) {
            return (self.canvasesTable.clickedRow >= 0)
        }

        if menuItem.action == #selector(deleteCanvas(_:)) {
            let rowIndexes = self.canvasRowIndexesForAction
            if (rowIndexes.count == 1) {
                menuItem.title = NSLocalizedString("Delete Canvas…", comment: "Delete single canvas menu item title")
            } else {
                menuItem.title = NSLocalizedString("Delete Canvases…", comment: "Delete multiple canvases menu item title")
            }
            return (rowIndexes.count > 0)
        }

        if menuItem.action == #selector(changePageSorting(_:)) {
            return true
        }

        return false
    }


    //MARK: - Action Items
    private var pageRowIndexesForAction: IndexSet {
        let selectedIndexes = self.viewModel.selectedPageRowIndexes
        let clickedRow = self.pagesTable.clickedRow
        if selectedIndexes.contains(clickedRow) {
            return selectedIndexes
        }
        return (clickedRow >= 0) ? IndexSet(integer: clickedRow) : IndexSet()
    }

    private var canvasRowIndexesForAction: IndexSet {
        let selectedIndexes = self.viewModel.selectedCanvasRowIndexes
        let clickedRow = self.canvasesTable.clickedRow
        if selectedIndexes.contains(clickedRow) {
            return selectedIndexes
        }
        return (clickedRow >= 0) ? IndexSet(integer: clickedRow) : IndexSet()
    }


    //MARK: - Selection
    private var isReloadingSelection = false
}


extension SidebarViewController: SidebarView {
    func reloadSelection() {
        self.isReloadingSelection = true
        self.canvasesTable.selectRowIndexes(self.viewModel.selectedCanvasRowIndexes, byExtendingSelection: false)
        self.pagesTable.selectRowIndexes(self.viewModel.selectedPageRowIndexes, byExtendingSelection: false)
        self.isReloadingSelection = false
    }

    func reloadCanvases() {
        self.canvasesTable.reloadData()
        self.reloadSelection()
    }

    func reloadPages() {
        self.pagesTable.reloadData()
        self.reloadSelection()
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


extension SidebarViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.canvasItems.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.viewModel.canvasItems[row]
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return self.viewModel.canvasItems[row].id.pasteboardItem
    }


    //MARK: - Validate drop
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard let types = info.draggingPasteboard.types else {
            return []
        }
        if types.contains(ModelID.PasteboardType) {
            return self.validateObjectDrop(on: tableView, with: info, proposedRow: row, proposedDropOperation: dropOperation)
        }
        if types.contains(.fileURL) {
            return self.validateFileDrop(on: tableView, with: info, proposedRow: row, proposedDropOperation: dropOperation)
        }
        return []
    }

    private func validateObjectDrop(on table: NSTableView, with info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard let item = info.draggingPasteboard.pasteboardItems?.first,
            let id = ModelID(pasteboardItem: item) else {
                return []
        }

        if (id.modelType == Canvas.modelType) {
            self.canvasesTable.setDropRow(row, dropOperation: .above)
            return .move
        }

        if (id.modelType == Page.modelType), case .on = dropOperation {
            self.canvasesTable.setDropRow(row, dropOperation: .on)
            return .copy
        }

        return []
    }

    private func validateFileDrop(on table: NSTableView, with info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if (row < table.numberOfRows) {
            self.canvasesTable.setDropRow(row, dropOperation: .on)
            return .copy
        }
        return []
    }


    //MARK: - Accept drop
    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let types = info.draggingPasteboard.types else {
            return false
        }
        if (types.contains(ModelID.PasteboardType)) {
            return self.acceptObjectDrop(on: tableView, with: info, row: row, dropOperation: dropOperation)
        }
        if types.contains(.fileURL) {
            return self.acceptFileDrop(on: tableView, with: info, row: row, dropOperation: dropOperation)
        }
        return false
    }

    private func acceptObjectDrop(on table: NSTableView, with info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems else {
            return false
        }

        let modelIDs = items.compactMap({ ModelID(pasteboardItem: $0) })

        if modelIDs.count == 1, let id = modelIDs.first, (id.modelType == Canvas.modelType) {
            self.viewModel.moveCanvas(with: id, aboveCanvasAtIndex: row)
            self.reloadCanvases()
            return true
        }

        for modelID in modelIDs {
            if (modelID.modelType == Page.modelType) {
                self.viewModel.addPage(with: modelID, toCanvasAtIndex: row)
            }
        }

        return (modelIDs.count > 0)
    }

    private func acceptFileDrop(on table: NSTableView, with info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let items = info.draggingPasteboard.pasteboardItems else {
            return false
        }

        let urls = items.compactMap{ $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
        let newPages = self.viewModel.addPages(fromFilesAtURLs: urls, toCanvasAtIndex: row)
        return (newPages.count > 0) // Accept the drop if at least one file led to a new page
    }
}


extension SidebarViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = self.viewModel.useSmallCanvasCells ? SmallCanvasCell.identifier : LargeCanvasCell.identifier
        return tableView.makeView(withIdentifier: identifier, owner: nil)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        //This prevents us updating the view model in response to us reloading the selection which can cause loops and odd behaviour
        guard self.isReloadingSelection == false else {
            return
        }

        self.viewModel.selectedCanvasRowIndexes = self.canvasesTable.selectedRowIndexes
    }
}



extension SidebarViewController: NSMenuDelegate {
    func numberOfItems(in menu: NSMenu) -> Int {
        if (menu.identifier == NSUserInterfaceItemIdentifier("SortPagesMenu")) {
            return SidebarViewModel.PageSortKey.allCases.count
        }
        return self.viewModel.canvasItems.count
    }

    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
        if (menu.identifier == NSUserInterfaceItemIdentifier("SortPagesMenu")) {
            let sortKey = SidebarViewModel.PageSortKey.allCases[index]
            item.title = sortKey.localizedName
            item.representedObject = sortKey.rawValue
            item.state = (self.viewModel.sortKey == sortKey) ? .on : .off
            item.target = self
            item.action = #selector(changePageSorting(_:))
            return true
        }

        item.title = self.viewModel.canvasItems[index].canvas.title
        item.tag = index
        item.target = self
        item.action = #selector(addToCanvas(_:))
        return true
    }
}
