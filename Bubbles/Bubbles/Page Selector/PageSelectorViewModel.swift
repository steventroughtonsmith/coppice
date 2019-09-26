//
//  PageSelectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol PageSelectorView: class {}

class PageSelectorViewModel: NSObject {
    weak var view: PageSelectorView?

    typealias SelectionBlock = (Page) -> Void

    let modelController: ModelController
    let title: String
    let selectionBlock: SelectionBlock
    init(title: String, modelController: ModelController, selectionBlock: @escaping SelectionBlock) {
        self.title = title
        self.modelController = modelController
        self.selectionBlock = selectionBlock
        super.init()
        self.updatePages()
    }


    @objc dynamic var searchTerm: String = "" {
        didSet {
            self.updatePages()
        }
    }

    @objc dynamic private(set) var matchingPages = [PageSelectorResult]()

    private func updatePages() {
        let sortedPages = self.modelController.collection(for: Page.self).all.sorted(by: {$0.title < $1.title})
        guard self.searchTerm.count > 1 else {
            self.matchingPages = sortedPages.map { PageSelectorResult(page: $0) }
            return
        }

        let filteredPages = sortedPages.filter { $0.title.lowercased().contains(self.searchTerm.lowercased()) }
        self.matchingPages = filteredPages.map { PageSelectorResult(page: $0) }
    }

    func confirmSelection(of result: PageSelectorResult) {
        self.selectionBlock(result.page)
    }
}

class PageSelectorResult: NSObject {
    @objc dynamic var title: String {
        return self.page.title
    }

    let page: Page
    init(page: Page) {
        self.page = page
        super.init()
    }
}
