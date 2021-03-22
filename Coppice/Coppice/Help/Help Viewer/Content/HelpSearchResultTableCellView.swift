//
//  HelpSearchResultTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class HelpSearchResultTableCellView: NSTableCellView {
    @IBOutlet var relevanceIndicator: NSLevelIndicator!

    override var objectValue: Any? {
        didSet {
            self.reloadData()
        }
    }


    private func reloadData() {
        guard let searchResult = self.objectValue as? HelpBook.SearchResult else {
            return
        }

        self.textField?.stringValue = searchResult.topic.title
        self.relevanceIndicator.floatValue = searchResult.relevance
    }
}
