//
//  PagesSidebarDataSource.swift
//  Bubbles
//
//  Created by Martin Pilkington on 14/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class PagesSidebarDataSource: NSObject {
    let viewModel: SidebarViewModel
    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
    }


    //MARK: - Table View
    weak var tableView: NSTableView? {
        didSet { self.setupTableView() }
    }

    private func setupTableView() {
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
        self.tableView?.setDraggingSourceOperationMask(.copy, forLocal: false)
        self.tableView?.registerForDraggedTypes([.fileURL])

        self.tableView?.register(NSNib(nibNamed: "PageCell", bundle: nil), forIdentifier: PageCell.identifier)
    }

    //MARK: - Selection
    private var isReloadingSelection = false
    func reloadSelection() {
        self.isReloadingSelection = true
        self.tableView?.selectRowIndexes(self.viewModel.selectedPageRowIndexes, byExtendingSelection: false)
    }
}


extension PagesSidebarDataSource: NSTableViewDataSource {
    //MARK: - NSTableViewDataSource
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.pageItems.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.viewModel.pageItems[row]
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        return self.viewModel.pageItems[row].page.pasteboardWriter
    }


    //MARK: - Drag & Drop
    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        guard let types = info.draggingPasteboard.types, types.contains(.fileURL) else {
            return []
        }
        tableView.setDropRow(-1, dropOperation: .on)
        return .copy
    }

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
        guard let types = info.draggingPasteboard.types, types.contains(.fileURL) else {
            return false
        }

        guard let items = info.draggingPasteboard.pasteboardItems else {
            return false
        }

        let urls = items.compactMap{ $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
        let newPages = self.viewModel.addPages(fromFilesAtURLs: urls, toCanvasAtIndex: nil)
        return (newPages.count > 0) // Accept the drop if at least one file led to a new page
    }
}


extension PagesSidebarDataSource: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        return tableView.makeView(withIdentifier: PageCell.identifier, owner: nil)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        guard self.isReloadingSelection == false else {
            return
        }
        guard let indexes = self.tableView?.selectedRowIndexes else {
            return
        }
        self.viewModel.selectedPageRowIndexes = indexes
    }
}
