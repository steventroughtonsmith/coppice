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

    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
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

        self.canvasesTable.setDraggingSourceOperationMask(.copy, forLocal: true)
        self.canvasesTable.registerForDraggedTypes([ModelID.PasteboardType, .fileURL])
        self.pagesTable.setDraggingSourceOperationMask(.copy, forLocal: false)
        self.pagesTable.registerForDraggedTypes([.fileURL])

        self.pagesTable.register(NSNib(nibNamed: "PageCell", bundle: nil), forIdentifier: PageCell.identifier)
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


    //MARK: - Menu Actions
    @IBAction func exportPages(_ sender: Any?) {
        guard let window = self.view.window else {
            return
        }
        PageExporter.export(self.viewModel.selectedPages, displayingOn: window)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(exportPages(_:)) {
            return PageExporter.validate(menuItem, forExporting: self.viewModel.selectedPages)
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

        return false
    }


    //MARK: - Context Menu
    @IBOutlet var canvasContextMenu: NSMenu!
    @IBAction func editCanvasTitle(_ sender: Any) {
        print("edit cell")
    }

    @IBAction func deleteCanvas(_ sender: Any) {
        self.viewModel.deleteCanvases(atIndexes: self.canvasRowIndexesForAction)
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
        if (tableView == self.canvasesTable) {
            return self.viewModel.canvasItems.count
        }
        return self.viewModel.pageItems.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if (tableView == self.canvasesTable) {
            return self.viewModel.canvasItems[row]
        }
        return self.viewModel.pageItems[row]
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        if (tableView == self.pagesTable) {
            return self.viewModel.pageItems[row].id.pasteboardItem
        }

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
        if table == self.pagesTable {
            self.pagesTable.setDropRow(-1, dropOperation: .on)
            return .copy
        }
        if (table == self.canvasesTable) && (row < table.numberOfRows) {
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
        let newPages = self.viewModel.addPages(fromFilesAtURLs: urls, toCanvasAtIndex: (table == self.canvasesTable) ? row : nil)
        return (newPages.count > 0) // Accept the drop if at least one file led to a new page
    }
}

extension SidebarViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if (tableView == self.pagesTable) {
            return tableView.makeView(withIdentifier: PageCell.identifier, owner: nil)
        }

        let identifier = self.viewModel.useSmallCanvasCells ? SmallCanvasCell.identifier : LargeCanvasCell.identifier
        return tableView.makeView(withIdentifier: identifier, owner: nil)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        //This prevents us updating the view model in response to us reloading the selection which can cause loops and odd behaviour
        guard self.isReloadingSelection == false else {
            return
        }
        guard let tableView = notification.object as? NSTableView else {
            return
        }

        if (tableView == self.canvasesTable) {
            self.viewModel.selectedCanvasRowIndexes = self.canvasesTable.selectedRowIndexes
        } else {
            self.viewModel.selectedPageRowIndexes = self.pagesTable.selectedRowIndexes
        }
    }
}
