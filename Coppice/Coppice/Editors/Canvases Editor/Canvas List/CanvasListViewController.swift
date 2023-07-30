//
//  CanvasListViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data

class CanvasListViewController: NSViewController, SplitViewContainable, NSMenuItemValidation {
    @IBOutlet weak var tableView: SpringLoadedTableView!
    @IBOutlet weak var tableScrollView: NSScrollView!
    @IBOutlet weak var addButton: NSButton!

    let viewModel: CanvasListViewModel
    init(viewModel: CanvasListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasListView", bundle: nil)
        viewModel.view = self
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet weak var bottomBarConstraint: NSLayoutConstraint!

    override func viewDidLoad() {
        super.viewDidLoad()

        if #available(macOS 11, *) {
            self.tableView.style = .fullWidth
        }

        self.tableView.setDraggingSourceOperationMask(.copy, forLocal: true)
        self.tableView.registerForDraggedTypes([ModelID.PasteboardType, .fileURL])

        self.tableView.register(NSNib(nibNamed: "SmallCanvasCell", bundle: nil), forIdentifier: SmallCanvasCell.identifier)
        self.tableView.register(NSNib(nibNamed: "LargeCanvasCell", bundle: nil), forIdentifier: LargeCanvasCell.identifier)

        self.tableView.springLoadingDelegate = self

        self.updateCanvasListState()
        self.setupActionButton()

        self.bottomBarConstraint.constant = GlobalConstants.bottomBarHeight

        self.setupAccessibility()
        self.tableView.sizeToFit() //For some reason the table doesn't correctly size the cells when first loaded
    }

    var viewAppeared = false
    override func viewDidAppear() {
        super.viewDidAppear()
        self.viewAppeared = true
        UserDefaults.standard.addObserver(self, forKeyPath: UserDefaultsKeys.canvasListIsCompact.rawValue, options: [], context: nil)
        self.viewModel.startObserving()
        self.reload()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        //For some reason viewDidDisappear can be called without viewDidAppear being called, so we need to check here
        guard self.viewAppeared else {
            return
        }
        UserDefaults.standard.removeObserver(self, forKeyPath: UserDefaultsKeys.canvasListIsCompact.rawValue)
        self.viewModel.stopObserving()
        self.viewAppeared = false
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
        guard keyPath == UserDefaultsKeys.canvasListIsCompact.rawValue else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        self.updateCanvasListState()
    }

    func createSplitViewItem() -> NSSplitViewItem {
        let item = NSSplitViewItem(viewController: self)
        item.maximumThickness = 250
        item.minimumThickness = 130
        return item
    }


    var isChangingSelection: Bool = false


    //MARK: - Visual State
    var isCompact: Bool {
        UserDefaults.standard.bool(forKey: .canvasListIsCompact)
    }

    static let compactSize: CGFloat = 64
    static let regularMinimumSize: CGFloat = 150
    static let regularMaximumSize: CGFloat = 250

    private func updateCanvasListState() {
        self.splitViewItem?.minimumThickness = (self.isCompact ? CanvasListViewController.compactSize : CanvasListViewController.regularMinimumSize)
        self.splitViewItem?.maximumThickness = (self.isCompact ? CanvasListViewController.compactSize : CanvasListViewController.regularMaximumSize)
        self.reload()
    }

    var currentThumbnailSize: CGSize {
        //May get called before when not displayed so we want to check the optional
        guard (self.tableView?.numberOfRows ?? 0) > 0 else {
            return .zero
        }
        let canvasCell = self.tableView.view(atColumn: 0, row: 0, makeIfNecessary: true) as? CanvasCell
        return canvasCell?.thumbnailImageView.frame.size ?? .zero
    }


    //MARK: - Menus
    @IBOutlet var contextMenu: NSMenu!
    @IBOutlet weak var actionButton: NSPopUpButton!

    private func setupActionButton() {
        for menuItem in self.contextMenu.items {
            let menuItemCopy = menuItem.copy() as! NSMenuItem
            self.actionButton.menu?.addItem(menuItemCopy)
        }
        self.actionButton.menu?.items.first?.image = NSImage.symbol(withName: Symbols.Toolbars.action)
    }


    //MARK: - Canvas Menu Actions
    private var rowForAction: Int {
        let clickedRow = self.tableView.clickedRow
        if clickedRow != -1 {
            return clickedRow
        }
        return self.tableView.selectedRow
    }

    @IBAction func editCanvasTitle(_ sender: Any) {
        let row = self.rowForAction
        guard row != -1 else {
            return
        }
        guard let cell = self.tableView.view(atColumn: 0, row: row, makeIfNecessary: false) as? EditableLabelCell else {
            return
        }
        cell.startEditing()
    }

    @IBAction func deleteCanvas(_ sender: Any) {
        self.viewModel.deleteCanvas(atIndex: self.rowForAction)
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(self.editCanvasTitle(_:)) {
            return (self.rowForAction != -1) && (self.isCompact == false)
        }

        if menuItem.action == #selector(self.deleteCanvas(_:)) {
            return (self.rowForAction != -1)
        }
        return false
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

        self.viewModel.deleteCanvas(atIndex: self.rowForAction)
    }


    //MARK: - Accessibility
    private func setupAccessibility() {
        guard
            let scrollView = self.tableScrollView,
            let addButton = self.addButton,
            let actionButton = self.actionButton
        else {
                return
        }

        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(NSLocalizedString("Canvas List", comment: "Canvas List accessibility label"))
        self.view.setAccessibilityChildren([scrollView, addButton, actionButton])
    }
}


extension CanvasListViewController: CanvasListView {
    func reload() {
        self.tableView.reloadData()
        self.reloadSelection()
    }

    func reloadSelection() {
        guard self.isChangingSelection == false else {
            return
        }

        guard let selectedIndex = self.viewModel.selectedCanvasIndex else {
            self.tableView.deselectAll(nil)
            return
        }
        self.tableView.selectRowIndexes(IndexSet(integer: selectedIndex), byExtendingSelection: false)
    }
}


extension CanvasListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.viewModel.canvases.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.viewModel.canvases[row]
    }

    func tableView(_ tableView: NSTableView, pasteboardWriterForRow row: Int) -> NSPasteboardWriting? {
        //Don't allow re-arranging canvases without pro
        guard (CoppiceSubscriptionManager.shared.state == .enabled) else {
            return nil
        }
        return self.viewModel.canvases[row].pasteboardWriter
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
            let id = ModelID(pasteboardItem: item)
        else {
                return []
        }

        let proEnabled = (CoppiceSubscriptionManager.shared.state == .enabled)

        if (id.modelType == Canvas.modelType) {
            self.tableView.setDropRow(row, dropOperation: .above)
            return proEnabled ? .move : []
        }

        if (id.modelType == Page.modelType), case .on = dropOperation {
            guard proEnabled || row == 0 else {
                return []
            }
            self.tableView.setDropRow(row, dropOperation: .on)
            return .copy
        }

        return []
    }

    private func validateFileDrop(on table: NSTableView, with info: NSDraggingInfo, proposedRow row: Int, proposedDropOperation dropOperation: NSTableView.DropOperation) -> NSDragOperation {
        if (row < table.numberOfRows) {
            self.tableView.setDropRow(row, dropOperation: .on)
            self.viewModel.selectedCanvasIndex = row
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

        let modelIDs = items.compactMap { ModelID(pasteboardItem: $0) }

        if modelIDs.count == 1, let id = modelIDs.first, (id.modelType == Canvas.modelType) {
            self.viewModel.moveCanvas(with: id, aboveCanvasAtIndex: row)
            self.reload()
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

        let urls = items.compactMap { $0.data(forType: .fileURL) }.compactMap { URL(dataRepresentation: $0, relativeTo: nil) }
        let newPages = self.viewModel.addPages(fromFilesAtURLs: urls, toCanvasAtIndex: row)
        return (newPages.count > 0) // Accept the drop if at least one file led to a new page
    }


    func tableView(_ tableView: NSTableView, draggingSession session: NSDraggingSession, willBeginAt screenPoint: NSPoint, forRowIndexes rowIndexes: IndexSet) {
        guard rowIndexes.count == 1 else {
            return
        }

        guard let cell = tableView.view(atColumn: 0, row: rowIndexes[rowIndexes.startIndex], makeIfNecessary: false) else {
            return
        }

        guard let imageRep = cell.bitmapImageRepForCachingDisplay(in: cell.bounds) else {
            return
        }
        cell.cacheDisplay(in: cell.bounds, to: imageRep)

        let image = NSImage(size: cell.bounds.size)
        image.addRepresentation(imageRep)

        session.enumerateDraggingItems(for: tableView, classes: [NSPasteboardItem.self]) { (draggingItem, index, stop) in
            draggingItem.setDraggingFrame(draggingItem.draggingFrame.rounded(), contents: image)
        }
    }
}


extension CanvasListViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let identifier = self.isCompact ? SmallCanvasCell.identifier : LargeCanvasCell.identifier
        return tableView.makeView(withIdentifier: identifier, owner: nil)
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        self.isChangingSelection = true
        self.viewModel.selectCanvas(atIndex: self.tableView.selectedRow)
        self.isChangingSelection = false
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        return RoundSelectionTableRowView()
    }
}


extension CanvasListViewController: SpringLoadedTableViewDelegate {
    func userDidSpringLoad(on row: NSTableRowView, of tableView: SpringLoadedTableView) {
        guard
            let canvasCell = row.view(atColumn: 0) as? NSTableCellView,
            let canvas = canvasCell.objectValue as? Canvas
        else {
            return
        }
        self.viewModel.select(canvas)
    }

    func springLoadedDragEnded(_ tableView: SpringLoadedTableView) {}
}
