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

            self.tableView?.enclosingScrollView?.contentInsets = self.displayMode.contentInsets
        }
    }

    var displayMode: PageSelectorViewController.DisplayMode = .fromWindow {
        didSet {
            self.tableView?.enclosingScrollView?.contentInsets = self.displayMode.contentInsets
            self.tableView?.reloadData()
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
            let cell = tableView.makeView(of: PageSelectorContentTableCellView.self)
            cell?.mode = self.displayMode
            return cell
        }
    }

    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        switch self.viewModel.rows[row].rowType {
        case .header:
            return self.displayMode.headerHeight
        default:
            return self.displayMode.rowHeight
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
        let row = PageSelectorTableRowView()
        row.cornerRadius = self.displayMode.cornerRadius
        return row
    }
}

extension PageSelectorViewController.DisplayMode {
    var cornerRadius: CGFloat {
        switch self {
        case .fromWindow:       return 6
        case .fromView:  return 4
        }
    }

    var headerHeight: CGFloat {
        switch self {
        case .fromWindow:       return 37
        case .fromView:  return 37
        }
    }

    var rowHeight: CGFloat {
        switch self {
        case .fromWindow:       return 26
        case .fromView:  return 22
        }
    }

    var contentInsets: NSEdgeInsets {
        switch self {
        case .fromWindow:
            return NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        case .fromView:
            return NSEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        }
    }
}

