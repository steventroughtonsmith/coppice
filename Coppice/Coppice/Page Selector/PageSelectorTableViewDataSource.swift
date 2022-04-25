//
//  PageSelectorTableViewDataSource.swift
//  Coppice
//
//  Created by Martin Pilkington on 10/05/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa

protocol PageSelectorTableViewDataSourceDelegate: AnyObject {
    func didReloadTable(for dataSource: PageSelectorTableViewDataSource)
}

class PageSelectorTableViewDataSource: NSObject {
    let viewModel: PageSelectorViewModel
    private var observations: [NSKeyValueObservation] = []
    init(viewModel: PageSelectorViewModel) {
        self.viewModel = viewModel
        super.init()
        self.observations.append(viewModel.observe(\.rows, changeHandler: { [weak self] (_, _) in
            self?.reloadData()
        }))
    }

    weak var delegate: PageSelectorTableViewDataSourceDelegate?

    var tableView: NSTableView? {
        didSet {
            self.tableView?.dataSource = self
            self.tableView?.delegate = self
            self.tableView?.register(PageSelectorContentTableCellView.self)
            self.tableView?.register(PageSelectorHeaderTableCellView.self)
            self.tableView?.register(PageSelectorDividerTableCellView.self)
            self.tableView?.sizeLastColumnToFit()

            self.tableView?.enclosingScrollView?.contentInsets = self.displayMode.contentInsets
        }
    }

    var displayMode: PageSelectorViewController.DisplayMode = .fromWindow {
        didSet {
            self.tableView?.enclosingScrollView?.contentInsets = self.displayMode.contentInsets
            self.reloadData()
        }
    }

    private func reloadData() {
        self.tableView?.reloadData()
        self.delegate?.didReloadTable(for: self)

        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(accessibilityAnnounceCurrentlySelectedItem), object: nil)
        self.perform(#selector(accessibilityAnnounceCurrentlySelectedItem), with: nil, afterDelay: 2)
    }

    func selectNext() {
        guard let tableView = self.tableView else {
            return
        }
        var nextRowIndex = tableView.selectedRow + 1
        while let nextRow = self.viewModel.rows[safe: nextRowIndex], nextRow.rowType.isSelectable == false {
            nextRowIndex += 1
        }
        guard (nextRowIndex < tableView.numberOfRows) else {
            return
        }

        tableView.selectRowIndexes(IndexSet(integer: nextRowIndex), byExtendingSelection: false)
        tableView.scrollRowToVisible(nextRowIndex)

        self.accessibilityAnnounceCurrentlySelectedItem()
    }

    func selectPrevious() {
        guard let tableView = self.tableView else {
            return
        }
        var nextRowIndex = tableView.selectedRow - 1
        while let nextRow = self.viewModel.rows[safe: nextRowIndex], nextRow.rowType.isSelectable == false {
            nextRowIndex -= 1
        }
        guard (nextRowIndex >= 0) else {
            return
        }
        tableView.selectRowIndexes(IndexSet(integer: nextRowIndex), byExtendingSelection: false)
        tableView.scrollRowToVisible(nextRowIndex)

        self.accessibilityAnnounceCurrentlySelectedItem()
    }

    func selectRow(at point: NSPoint) {
        guard let tableView = tableView else {
            return
        }

        let row = tableView.row(at: point)

        guard
            row >= 0,
            self.tableView(tableView, shouldSelectRow: row)
        else {
            return
        }

        tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
    }

    //MARK: - Accessibility
    @objc dynamic func accessibilityAnnounceCurrentlySelectedItem() {
        guard
            let tableView = self.tableView,
            let selectedPageRowTitle = self.viewModel.rows[safe: tableView.selectedRow]?.accessibilityTitle
        else {
            return
        }

        NSAccessibility.post(element: NSApplication.shared.mainWindow as Any, notification: .announcementRequested, userInfo: [
            .announcement: selectedPageRowTitle,
            .priority: NSAccessibilityPriorityLevel.high.rawValue,
        ])
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
        case .divider:
            return tableView.makeView(of: PageSelectorDividerTableCellView.self)
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
        case .divider:
            return self.displayMode.dividerHeight
        default:
            return self.displayMode.rowHeight
        }
    }

    func tableView(_ tableView: NSTableView, shouldSelectRow row: Int) -> Bool {
        switch self.viewModel.rows[row].rowType {
        case .header, .divider:
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
        case .fromWindow:       return 24
        case .fromView:  return 24
        }
    }

    var dividerHeight: CGFloat {
        return 11
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

