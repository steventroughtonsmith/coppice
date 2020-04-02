//
//  SearchResultsViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SearchResultsViewController: NSViewController {
    @IBOutlet weak var outlineView: NSOutlineView!

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

//        self.outlineView.indentationPerLevel = 10
        self.outlineView.register(NSNib(nibNamed: "SearchResultTableCellView", bundle: nil), forIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SearchResultCell"))
    }

    @IBAction func clearSearch(_ sender: Any) {
        self.viewModel.clearSearch()
    }
}


extension SearchResultsViewController: SearchResultsView {
    func reload() {
        self.outlineView.reloadData()
        self.viewModel.results.forEach { self.outlineView.expandItem($0) }
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
}
