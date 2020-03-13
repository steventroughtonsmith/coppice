//
//  SidebarViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class SidebarViewController: NSViewController, NSMenuItemValidation, RootViewController {
    @objc dynamic let viewModel: SidebarViewModel

    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "SidebarView", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    @IBOutlet weak var outlineView: NSOutlineView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadSidebarNodes()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.startObserving()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }


    //MARK: - RootViewController
    lazy var splitViewItem: NSSplitViewItem = {
        let item = NSSplitViewItem(sidebarWithViewController: self)
        return item
    }()


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

//        self.viewModel.deletePages(atIndexes: self.viewModel.selectedPageRowIndexes)
    }


    //MARK: - Page Menu Actions
    @IBAction func editPageTitle(_ sender: Any) {
        guard self.outlineView.clickedRow > -1 else {
            return
        }
        guard let cell = self.outlineView.view(atColumn: 0, row: self.outlineView.clickedRow, makeIfNecessary: false) as? EditableLabelCell else {
            return
        }
        cell.startEditing()
    }

    @IBAction func deletePage(_ sender: Any) {
//        self.viewModel.deletePages(atIndexes: self.pageRowIndexesForAction)
    }

    @IBAction func exportPages(_ sender: Any?) {
        guard self.view.window != nil else {
            return
        }
//        PageExporter.export(self.viewModel.selectedPages, displayingOn: window)
    }

    @IBAction func addToCanvas(_ sender: Any?) {
        guard (sender as? NSMenuItem) != nil else {
            return
        }

//        self.viewModel.addPages(atIndexes: self.pageRowIndexesForAction, toCanvasAtindex: menuItem.tag)
    }


    //MARK: - Context Menus
    @IBOutlet var pageContextMenu: NSMenu!


    //MARK: - Menu Validation
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem.action == #selector(editPageTitle(_:)) {
//            return (self.pagesTable.clickedRow >= 0)
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

//        if menuItem.action == #selector(exportPages(_:)) {
//            let pages = self.viewModel.pageItems[self.pageRowIndexesForAction].map { $0.page }
//            return PageExporter.validate(menuItem, forExporting: pages)
//        }

        if menuItem.action == #selector(addToCanvas(_:)) {
            return (self.pageRowIndexesForAction.count > 0)
        }
        
        return false
    }


    //MARK: - Action Items
    private var pageRowIndexesForAction: IndexSet {
        return IndexSet()
//        let selectedIndexes = self.viewModel.selectedPageRowIndexes
//        let clickedRow = self.pagesTable.clickedRow
//        if selectedIndexes.contains(clickedRow) {
//            return selectedIndexes
//        }
//        return (clickedRow >= 0) ? IndexSet(integer: clickedRow) : IndexSet()
    }




    //MARK: - Reload
    private func reloadSidebarNodes() {
        self.outlineView.reloadData()
        let rootFolder = self.viewModel.documentWindowViewModel.rootFolder
        if let pagesGroup = self.viewModel.rootSidebarNodes.first(where: { $0.item == .folder(rootFolder.id)}) {
            self.outlineView.expandItem(pagesGroup)
        }
    }

}


extension SidebarViewController: SidebarView {
    func reload() {
        self.reloadSidebarNodes()
    }

    func reloadSelection() {
//        self.isReloadingSelection = true
//        self.pagesTable.selectRowIndexes(self.viewModel.selectedPageRowIndexes, byExtendingSelection: false)
//        self.isReloadingSelection = false
    }

    func reloadCanvases() {
    }

    func reloadPages() {
//        self.pagesTable.reloadData()
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



extension SidebarViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard item != nil else {
            return self.viewModel.rootSidebarNodes.count
        }
        guard let sidebarItem = item as? SidebarNode else {
            return 0
        }
        return sidebarItem.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard item != nil else {
            return self.viewModel.rootSidebarNodes[index]
        }
        guard let sidebarItem = item as? SidebarNode else {
            preconditionFailure("Encountered an item that isn't a sidebar item: \(item!)")
        }
        return sidebarItem.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let sidebarItem = item as? SidebarNode else {
            return false
        }
        return (sidebarItem.children.count > 0)
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let sidebarItem = item as? SidebarNode else {
            return true
        }
        switch sidebarItem.cellType {
        case .bigCell, .smallCell:
            return true
        case .groupCell:
            return false
        }
    }
}


extension SidebarViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let sidebarItem = item as? SidebarNode else {
            return false
        }
        switch sidebarItem.cellType {
        case .bigCell, .smallCell:
            return false
        case .groupCell:
            return true
        }
    }

    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let sidebarItem = item as? SidebarNode else {
            return nil
        }
        let view: NSTableCellView?
        switch sidebarItem.cellType {
        case .bigCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("BigCell"), owner: self) as? NSTableCellView
        case .smallCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("SmallCell"), owner: self) as? NSTableCellView
        case .groupCell:
            view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier("GroupCell"), owner: self) as? NSTableCellView
        }
        view?.objectValue = item
        return view
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        guard let sidebarItem = item as? SidebarNode else {
            return 22
        }
        switch sidebarItem.cellType {
        case .bigCell:
            return 34
        case .smallCell, .groupCell:
            return 22
        }
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        let selectedNodes = self.outlineView.selectedRowIndexes.compactMap { self.outlineView.item(atRow: $0) as? SidebarNode }
        self.viewModel.updateSelectedNodes(selectedNodes)
    }
}






//extension SidebarViewController: NSMenuDelegate {
//    func numberOfItems(in menu: NSMenu) -> Int {
//        if (menu.identifier == NSUserInterfaceItemIdentifier("SortPagesMenu")) {
//            return SidebarViewModel.PageSortKey.allCases.count
//        }
//        return self.viewModel.canvasItems.count
//    }
//
//    func menu(_ menu: NSMenu, update item: NSMenuItem, at index: Int, shouldCancel: Bool) -> Bool {
//        if (menu.identifier == NSUserInterfaceItemIdentifier("SortPagesMenu")) {
//            let sortKey = SidebarViewModel.PageSortKey.allCases[index]
//            item.title = sortKey.localizedName
//            item.representedObject = sortKey.rawValue
//            item.state = (self.viewModel.sortKey == sortKey) ? .on : .off
//            item.target = self
//            item.action = #selector(changePageSorting(_:))
//            return true
//        }
//
//        item.title = self.viewModel.canvasItems[index].canvas.title
//        item.tag = index
//        item.target = self
//        item.action = #selector(addToCanvas(_:))
//        return true
//    }
//}
