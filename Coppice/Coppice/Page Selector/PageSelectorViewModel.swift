//
//  PageSelectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

protocol PageSelectorView: AnyObject {}

class PageSelectorViewModel: NSObject {
    weak var view: PageSelectorView?

    typealias SelectionBlock = (Page) -> Void

    let documentWindowViewModel: DocumentWindowViewModel
    let title: String
    let selectionBlock: SelectionBlock
    init(title: String, documentWindowViewModel: DocumentWindowViewModel, selectionBlock: @escaping SelectionBlock) {
        self.title = title
        self.documentWindowViewModel = documentWindowViewModel
        self.selectionBlock = selectionBlock
        super.init()
        self.updatePages()
    }


    @objc dynamic var searchTerm: String = "" {
        didSet {
            self.updatePages()
        }
    }

    @objc dynamic private(set) var rows = [PageSelectorRow]()

    var showFolderNames = false {
        didSet {
            guard self.showFolderNames != oldValue else {
                return
            }
            self.rows.forEach { $0.showFolderName = self.showFolderNames }
        }
    }

    private func updatePages() {
        let sortedPages = self.documentWindowViewModel.modelController.pageCollection.all.sorted(by: {
            //If one or other page is untitled we want to favour the titled page
            if ($0.title.count == 0) || ($1.title.count == 0) {
                return $0.title.count > $1.title.count
            }
            return $0.title < $1.title
        })
        var newRows: [PageSelectorRow]
        if self.searchTerm.count > 1 {
            let filteredPages = sortedPages.filter { $0.title.lowercased().contains(self.searchTerm.lowercased()) }
            newRows = filteredPages.map { PageSelectorRow(page: $0) }
        } else {
            newRows = sortedPages.map { PageSelectorRow(page: $0) }
        }

        if newRows.count > 0 {
            newRows.append(PageSelectorRow.divider)
        }

        newRows.append(PageSelectorRow(title: NSLocalizedString("Create New…", comment: "Page selector - page creation header"), body: nil, image: nil, rowType: .header))
        newRows.append(contentsOf: PageContentType.allCases.map { PageSelectorRow(contentType: $0) })
        self.rows = newRows
    }

    func confirmSelection(of result: PageSelectorRow) {
        switch result.rowType {
        case .page(let page):
            self.selectionBlock(page)
        case .contentType(let contentType):
            let page = self.documentWindowViewModel.modelController.createPage(ofType: contentType, in: self.documentWindowViewModel.folderForNewPages, below: nil) { page in
                page.title = self.searchTerm
            }

            self.selectionBlock(page)
        case .header, .divider:
            break
        }
    }
}

class PageSelectorRow: NSObject {
    @objc dynamic let title: String
    @objc dynamic let image: NSImage?

    @objc dynamic var body: String? {
        return self.showFolderName ? self.folderPath : self.content
    }

    enum RowType: Equatable {
        case page(Page)
        case contentType(PageContentType)
        case divider
        case header

        var isSelectable: Bool {
            switch self {
            case .page, .contentType:
                return true
            case .divider, .header:
                return false
            }
        }
    }

    let rowType: RowType
    private let content: String?
    private let folderPath: String?

    convenience init(page: Page) {
        let title = page.title
        var body: String?
        if let string = (page.content as? TextPageContent)?.text.string, string.count > 0 {
            body = string
        }
        let image = page.content.contentType.icon(.small)
        self.init(title: title, body: body, folderPath: page.containingFolder?.pathString, image: image, rowType: .page(page))
    }

    convenience init(contentType: PageContentType) {
        self.init(title: contentType.localizedName, body: nil, image: contentType.icon(.small), rowType: .contentType(contentType))
    }

    static var divider: PageSelectorRow {
        return PageSelectorRow(title: "", body: nil, image: nil, rowType: .divider)
    }

    init(title: String, body: String?, folderPath: String? = nil, image: NSImage?, rowType: RowType = .header) {
        self.title = title
        self.content = body
        self.folderPath = folderPath
        self.image = image
        self.rowType = rowType
    }

    @objc dynamic var showFolderName = false

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == #keyPath(body) {
            keyPaths.insert("showFolderName")
        }
        return keyPaths
    }
}
