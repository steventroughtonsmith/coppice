//
//  PageSelectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

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
        let sortedPages = self.modelController.collection(for: Page.self).all.sorted(by: {
            //If one or other page is untitled we want to favour the titled page
            if ($0.title.count == 0) || ($1.title.count == 0) {
                return $0.title.count > $1.title.count
            }
            return $0.title < $1.title
        })
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

    @objc dynamic var body: String? {
        guard let textContent = self.page.content as? TextPageContent else {
            return nil
        }
        let string = textContent.text.string
        if string.count == 0 {
            return nil
        }
        return string
    }

    @objc dynamic var image: NSImage? {
        guard let imageContent = self.page.content as? ImagePageContent else {
            return self.page.content.contentType.icon
        }
        return imageContent.image
    }

    let page: Page
    init(page: Page) {
        self.page = page
        super.init()
    }
}
