//
//  HelpSearchResultsViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

protocol HelpSearchResultsViewControllerDelegate: AnyObject {
    func open(_ topic: HelpBook.Topic, from helpSearchResultsViewController: HelpSearchResultsViewController)
}

class HelpSearchResultsViewController: NSViewController {
    weak var delegate: HelpSearchResultsViewControllerDelegate?

    let topics: [HelpBook.SearchResult]
    init(topics: [HelpBook.SearchResult]) {
        self.topics = topics
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    @IBOutlet var tableView: NSTableView!
    @IBAction func openTopic(_ sender: Any) {
        guard self.tableView.clickedRow != -1 else {
            return
        }

        self.delegate?.open(self.topics[self.tableView.clickedRow].topic, from: self)
    }
}

extension HelpSearchResultsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.topics.count
    }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.topics[row]
    }
}
