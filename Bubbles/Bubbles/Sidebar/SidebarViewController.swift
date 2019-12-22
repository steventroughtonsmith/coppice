//
//  SidebarViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController, NSMenuItemValidation {
    let viewModel: SidebarViewModel

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
        // Do view setup here.
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.startObserving()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }

    override func keyDown(with event: NSEvent) {
        guard let specialKey = event.specialKey else {
            return
        }

        //For some reason NSEvent.SpecialKey.delete does not use NSDeleteFunctionKey, but NSEvent does
        guard (specialKey == .backspace) || (specialKey == .init(rawValue: NSDeleteFunctionKey)) || (specialKey == .deleteForward) else {
            return
        }

        self.viewModel.deleteSelectedObject()
    }


    //MARK: - Menu Actions

    @IBAction func exportPages(_ sender: Any?) {
        guard let window = self.view.window else {
            return
        }
        PageExporter.export(self.viewModel.selectedPages, displayingOn: window)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return PageExporter.validate(menuItem, forExporting: self.viewModel.selectedPages)
    }
}


extension SidebarViewController: SidebarView {
    func reloadSelection() {
        if (self.viewModel.selectedCanvasRow >= 0) {
            self.canvasesTable.selectRowIndexes(IndexSet(integer: self.viewModel.selectedCanvasRow),
                                                byExtendingSelection: false)
            #warning("For some reason this causes a loop, we ideally need to find a better way of doing it")
//            self.view.window?.makeFirstResponder(self.canvasesTable)
        } else {
            self.canvasesTable.deselectRow(self.canvasesTable.selectedRow)
        }

        if (self.viewModel.selectedPageRow >= 0) {
            self.pagesTable.selectRowIndexes(IndexSet(integer: self.viewModel.selectedPageRow),
                                             byExtendingSelection: false)
//            self.view.window?.makeFirstResponder(self.pagesTable)
        } else {
            self.pagesTable.deselectAll(nil)
        }
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
        guard let item = info.draggingPasteboard.pasteboardItems?.first,
            let id = ModelID(pasteboardItem: item) else {
            return false
        }

        if (id.modelType == Canvas.modelType) {
            self.viewModel.moveCanvas(with: id, aboveCanvasAtIndex: row)
            self.reloadCanvases()
            return true
        }

        if (id.modelType == Page.modelType) {
            self.viewModel.addPage(with: id, toCanvasAtIndex: row)
            return true
        }

        return false
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
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {
            return
        }

        if (tableView == self.canvasesTable) {
            self.viewModel.selectedCanvasRow = self.canvasesTable.selectedRow
        } else {
            self.viewModel.selectedPageRow = self.pagesTable.selectedRow
        }
    }
}
