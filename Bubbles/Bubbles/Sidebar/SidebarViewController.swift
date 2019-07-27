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

        self.pagesTable.setDraggingSourceOperationMask(.copy, forLocal: false)
        // Do view setup here.
    }
}

extension SidebarViewController: SidebarView {
    func reloadSelection() {
        if (self.viewModel.selectedCanvasRow >= 0) {
            self.canvasesTable.selectRowIndexes(IndexSet(integer: self.viewModel.selectedCanvasRow),
                                                byExtendingSelection: false)
        } else {
            self.canvasesTable.deselectRow(self.canvasesTable.selectedRow)
        }

        if (self.viewModel.selectedPageRow >= 0) {
            self.pagesTable.selectRowIndexes(IndexSet(integer: self.viewModel.selectedPageRow),
                                             byExtendingSelection: false)
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
            return self.viewModel.numberOfCanvases
        }
        return self.viewModel.numberOfPages
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        if (tableView == self.canvasesTable) {
            return self.viewModel.canvas(forRow: row)
        }
        let page = self.viewModel.page(forRow: row)
        return page
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        if (tableView == self.pagesTable) {
            return self.viewModel.page(forRow: row).id.uuidString as NSString
        }
        return nil
    }
}

extension SidebarViewController: NSTableViewDelegate {
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? NSTableView else {
            return
        }

        if (tableView == self.canvasesTable) {
            self.viewModel.selectCanvas(atRow: self.canvasesTable.selectedRow)
        } else {
            self.viewModel.selectPage(atRow: self.pagesTable.selectedRow)
        }
    }
}
