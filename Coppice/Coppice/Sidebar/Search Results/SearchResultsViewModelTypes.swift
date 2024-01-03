//
//  SearchResultsViewModelTypes.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

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

    var pasteboardWriter: NSPasteboardWriting? {
        return nil
    }


    static let standardTitleAttributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail

        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        attributes[.foregroundColor] = NSColor.labelColor
        attributes[.paragraphStyle] = paragraph

        return attributes
    }()

    static let standardBodyAttributes: [NSAttributedString.Key: Any] = {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byTruncatingTail

        var attributes = [NSAttributedString.Key: Any]()
        attributes[.font] = NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)
        attributes[.foregroundColor] = NSColor.secondaryLabelColor
        attributes[.paragraphStyle] = paragraph

        return attributes
    }()

    static let titleMatchAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
        .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]

    static let bodyMatchAttributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize, weight: .semibold),
        .underlineStyle: NSUnderlineStyle.single.rawValue,
    ]
}


class PageSearchResult: SearchResult {
    let match: Page.Match
    let searchString: String
    init(match: Page.Match, searchString: String) {
        self.match = match
        self.searchString = searchString
        super.init(sidebarItem: .page(match.page.id))
    }

    override var title: NSAttributedString? {
        let title = NSMutableAttributedString(string: self.match.page.title, attributes: SearchResult.standardTitleAttributes)
        if case .title(let matchRange) = self.match.matchType {
            title.setAttributes(SearchResult.titleMatchAttributes, range: matchRange)
        }
        return (title.length > 0) ? title : nil
    }

    override var body: NSAttributedString? {
        guard case .content(let contentMatch) = self.match.matchType else {
            guard let textContent = self.match.page.content as? Page.Content.Text else {
                return nil
            }
            var baseString = textContent.text.string
            if let firstLinebreakIndex = baseString.firstIndex(of: "\n") {
                baseString = String(baseString[baseString.startIndex..<firstLinebreakIndex])
            }
            return NSAttributedString(string: baseString, attributes: SearchResult.standardBodyAttributes)
        }

        var baseString = contentMatch.string

        var matchRange = contentMatch.range
        if matchRange.upperBound >= 20 {
            baseString = "… \((baseString as NSString).substring(from: matchRange.location))"
            matchRange.location = 2
        }

        if let firstLinebreakIndex = baseString.firstIndex(of: "\n") {
            baseString = String(baseString[baseString.startIndex..<firstLinebreakIndex])
        }

        let attributedString = NSMutableAttributedString(string: baseString, attributes: SearchResult.standardBodyAttributes)
        attributedString.setAttributes(SearchResult.bodyMatchAttributes, range: matchRange)

        return attributedString
    }

    override var image: NSImage? {
        guard let imageContent = self.match.page.content as? Page.Content.Image else {
            return nil
        }

        return imageContent.image
    }

    override var pasteboardWriter: NSPasteboardWriting? {
        return self.match.page.pasteboardWriter
    }
}


class CanvasSearchResult: SearchResult {
    let match: Canvas.Match
    let searchString: String
    init(match: Canvas.Match, searchString: String) {
        self.match = match
        self.searchString = searchString
        super.init(sidebarItem: .canvas(match.canvas.id))
    }

    override var title: NSAttributedString? {
        let title = NSMutableAttributedString(string: self.match.canvas.title, attributes: SearchResult.standardTitleAttributes)
        if case .title(let matchRange) = self.match.matchType {
            title.setAttributes([
                .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .semibold),
                .underlineStyle: NSUnderlineStyle.single.rawValue,
            ], range: matchRange)
        }
        return title
    }

    override var body: NSAttributedString? {
        switch self.match.matchType {
        case .title:
            return nil
        case .pages(let numberOfPages):
            let localizedBodyTemplate: String
            if numberOfPages == 1 {
                localizedBodyTemplate = NSLocalizedString("%d matching page", comment: "Canvas search result singular body text")
            } else {
                localizedBodyTemplate = NSLocalizedString("%d matching pages", comment: "Canvas search result plural body text")
            }
            let localizedBody = String(format: localizedBodyTemplate, numberOfPages)
            return NSAttributedString(string: localizedBody, attributes: SearchResult.standardBodyAttributes)
        }
    }

    override var image: NSImage? {
        return self.match.canvas.thumbnail
    }
}
