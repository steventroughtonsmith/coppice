//
//  SidebarViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController {
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
        self.canvasesTable.registerForDraggedTypes([ModelID.PasteboardType])
        self.pagesTable.setDraggingSourceOperationMask(.copy, forLocal: false)
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
}

extension SidebarViewController: SidebarView {
    func reloadSelection() {
        if (self.viewModel.selectedCanvasRow >= 0) {
            self.canvasesTable.selectRowIndexes(IndexSet(integer: self.viewModel.selectedCanvasRow),
                                                byExtendingSelection: false)
            self.view.window?.makeFirstResponder(self.canvasesTable)
        } else {
            self.canvasesTable.deselectRow(self.canvasesTable.selectedRow)
        }

        if (self.viewModel.selectedPageRow >= 0) {
            self.pagesTable.selectRowIndexes(IndexSet(integer: self.viewModel.selectedPageRow),
                                             byExtendingSelection: false)
            self.view.window?.makeFirstResponder(self.pagesTable)
        } else {
            self.pagesTable.deselectAll(nil)
        }
    }

    func reloadCanvases() {
        self.canvasesTable.reloadData()
    }

    func reloadPages() {
        self.pagesTable.reloadData()
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

    func tableView(_ tableView: NSTableView, validateDrop info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
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

    func tableView(_ tableView: NSTableView, acceptDrop info: NSDraggingInfo, row: Int, dropOperation: NSTableView.DropOperation) -> Bool {
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
