//
//  SearchResultsViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class SearchResultsViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!
    @IBOutlet weak var matchesLabel: NSTextField!
    @IBOutlet weak var clearSearchButton: NSButton!
    @IBOutlet weak var outlineScrollView: NSScrollView!
    @IBOutlet var topConstraint: NSLayoutConstraint!

    @objc dynamic let viewModel: SearchResultsViewModel
    init(viewModel: SearchResultsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "SearchResultsView", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.outlineView.indentationPerLevel = 0
        self.outlineView.register(NSNib(nibNamed: "SearchResultTableCellView", bundle: nil), forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SearchResultCell"))
        self.outlineView.setDraggingSourceOperationMask(.copy, forLocal: false)
        self.outlineView.registerForDraggedTypes([ModelID.PasteboardType])

        if #available(OSX 10.16, *) {
            self.topConstraint.constant = 42
        }

        self.setupAccessibility()
    }

    @IBAction func clearSearch(_ sender: Any) {
        self.viewModel.clearSearch()
    }

    //MARK: - Accessibility
    private func setupAccessibility() {
        guard
            let scrollView = self.outlineScrollView,
            let matchesLabel = self.matchesLabel.cell,
            let clearSearchButton = self.clearSearchButton
        else {
                return
        }

        self.view.setAccessibilityElement(true)
        self.view.setAccessibilityRole(.group)
        self.view.setAccessibilityLabel(NSLocalizedString("Search Results", comment: "Search Results accessibility label"))
        self.view.setAccessibilityChildren([scrollView, matchesLabel, clearSearchButton])
    }
}


extension SearchResultsViewController: SearchResultsView {
    func reload() {
        self.outlineView.reloadData()
        let results = self.viewModel.results
        results.forEach { self.outlineView.expandItem($0) }
        if self.outlineView.selectedRowIndexes.count == 0, let firstItem = results.first?.results.first {
            self.outlineView.selectRowIndexes(IndexSet(integer: self.outlineView.row(forItem: firstItem)), byExtendingSelection: false)
        }
    }
}


extension SearchResultsViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard item != nil else {
            return self.viewModel.results.count
        }

        guard let resultsGroup = item as? SearchResultGroup else {
            return 0
        }

        return resultsGroup.results.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard item != nil else {
            return self.viewModel.results[index]
        }

        guard let resultsGroup = item as? SearchResultGroup else {
            return ""
        }

        return resultsGroup.results[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return (item is SearchResultGroup)
    }

    func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        return (item as? SearchResult)?.pasteboardWriter
    }

    func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        return (item is CanvasSearchResult) ? .copy : []
    }

    func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        guard let result = item as? CanvasSearchResult else {
            return false
        }

        guard let types = info.draggingPasteboard.types, types.contains(ModelID.PasteboardType) else {
            return false
        }

        guard let items = info.draggingPasteboard.pasteboardItems else {
            return false
        }
        let modelIDs = items.compactMap { ModelID(pasteboardItem: $0) }
        return self.viewModel.addPages(with: modelIDs, to: result.match.canvas)
    }
}


extension SearchResultsViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let objectValue: Any
        let identifier: String
        if (item is SearchResult) {
            objectValue = item
            identifier = "SearchResultCell"
        } else if let resultGroup = item as? SearchResultGroup {
            objectValue = resultGroup.title
            identifier = "HeaderCell"
        } else {
            return nil
        }

        let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier), owner: self) as? NSTableCellView
        cell?.objectValue = objectValue
        return cell
    }

    func outlineView(_ outlineView: NSOutlineView, shouldCollapseItem item: Any) -> Bool {
        return false
    }

    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return (item is SearchResultGroup) ? 22 : 42
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        return (item is SearchResultGroup)
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        return (item is SearchResult)
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        self.viewModel.selectedResults = self.outlineView.selectedRowIndexes.compactMap { self.outlineView.item(atRow: $0) as? SearchResult }
    }
}
