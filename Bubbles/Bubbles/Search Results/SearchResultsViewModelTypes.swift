//
//  SearchResultsViewModelTypes.swift
//  Bubbles
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SearchResultGroup: NSObject {
    let title: String
    let results: [SearchResult]

    init(title: String, results: [SearchResult]) {
        self.title = title
        self.results = results
        super.init()
    }
}

class SearchResult: NSObject {
    @objc dynamic var title: NSAttributedString? {
        return nil
    }
    @objc dynamic var body: NSAttributedString? {
        return nil
    }
    @objc dynamic var image: NSImage? {
        return nil
    }

    let sidebarItem: DocumentWindowViewModel.SidebarItem
    init(sidebarItem: DocumentWindowViewModel.SidebarItem) {
        self.sidebarItem = sidebarItem
        super.init()
    }
}

class PageSearchResult: SearchResult {
    let page: Page
    let searchTerm: String
    init(page: Page, searchTerm: String) {
        self.page = page
        self.searchTerm = searchTerm
        super.init(sidebarItem: .page(page.id))
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: self.page.title, attributes: [.foregroundColor: NSColor.textColor])
    }
}

class CanvasSearchResult: SearchResult {
    let canvas: Canvas
    let searchTerm: String
    init(canvas: Canvas, searchTerm: String) {
        self.canvas = canvas
        self.searchTerm = searchTerm
        super.init(sidebarItem: .canvas(canvas.id))
    }

    override var title: NSAttributedString? {
        return NSAttributedString(string: self.canvas.title)
    }

    override var image: NSImage? {
        return self.canvas.thumbnail
    }
}
