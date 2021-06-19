//
//  PageSelectorTableViewDataSource.swift
//  Coppice
//
//  Created by Martin Pilkington on 10/05/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

class PageSelectorTableViewDataSource: NSObject {
    let viewModel: PageSelectorViewModel
    private var observations: [NSKeyValueObservation] = []
    init(viewModel: PageSelectorViewModel) {
        self.viewModel = viewModel
        super.init()
        self.observations.append(viewModel.observe(\.rows, changeHandler: { [weak self] (_, _) in
            self?.tableView?.reloadData()
        }))
    }

    var tableView: NSTableView? {
        didSet {
            self.tableView?.dataSource = self
            self.tableView?.delegate = self
            self.tableView?.register(PageSelectorContentTableCellView.self)
            self.tableView?.register(PageSelectorHeaderTableCellView.self)
            self.tableView?.sizeLastColumnToFit()
        }
    }

    func selectNext() {
        guard let tableView = self.tableView else {
            return
        }
        var nextRow = tableView.selectedRow + 1
        if self.viewModel.rows[safe: nextRow]?.rowType == .header {
            nextRow += 1
        }
        guard (nextRow < tableView.numberOfRows) else {
            return
        }

        tableView.selectRowIndexes(IndexSet(integer: nextRow), byExtendingSelection: false)
        tableView.scrollRowToVisible(nextRow)
    }

    func selectPrevious() {
        guard let tableView = self.tableView else {
            return
        }
        var nextRow = tableView.selectedRow - 1
        if self.viewModel.rows[safe: nextRow]?.rowType == .header {
            nextRow -= 1
        }
        guard (nextRow >= 0) else {
            return
        }
        tableView.selectRowIndexes(IndexSet(integer: nextRow), byExtendingSelection: false)
        tableView.scrollRowToVisible(nextRow)
    }
}

extension PageSelectorTableViewDataSource: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.rows.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.viewModel.rows[row]
    }
}

extension PageSelectorTableViewDataSource: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        switch self.viewModel.rows[row].rowType {
        case .header:
            return tableView.makeView(of: PageSelectorHeaderTableCellView.self)
        default:
            return tableView.makeView(of: PageSelectorContentTableCellView.self)
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch self.viewModel.rows[row].rowType {
        case .header:
            return 32
        default:
            return 28
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        switch self.viewModel.rows[row].rowType {
        case .header:
            return false
        default:
            return true
        }
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return PageSelectorTableRowView()
    }
}

class PageSelectorTableRowView: NSTableRowView {
    override var isEmphasized: Bool {
        get { return self.isSelected }
        set {}
    }
}

