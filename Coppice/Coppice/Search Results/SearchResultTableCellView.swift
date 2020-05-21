//
//  SearchResultTableCellView.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/05/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SearchResultTableCellView: NSTableCellView {

    override var objectValue: Any? {
        didSet {
            self.updateAccessibility()
        }
    }

    private func updateAccessibility() {
        guard let searchResult = self.objectValue as? SearchResult else {
            return
        }

        var accessibilityLabel = ""
        if let title = searchResult.title?.string {
            accessibilityLabel.append("\(title). ")
        } else if case .page(_) = searchResult.sidebarItem {
            accessibilityLabel.append("\(Page.localizedDefaultTitle). ")
        }
        if let body = searchResult.body?.string {
            accessibilityLabel.append("\(body) ")
        }
        self.setAccessibilityLabel(accessibilityLabel)
        self.setAccessibilityChildren(nil)
    }
    
}
