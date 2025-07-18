//
//  SearchResultsViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data

protocol SearchResultsView: AnyObject {
    func reload()
}

class SearchResultsViewModel: ViewModel {
    weak var view: SearchResultsView?

    @objc dynamic var searchString: String = "" {
        didSet {
            self.reload()
        }
    }

    @objc dynamic var headerText: NSAttributedString {
        let matchesForTemplate = NSLocalizedString("Matches for \"%@\"", comment: "Search Results header template")
        let actualResults = String(format: matchesForTemplate, self.searchString)

        let attributes = NSMutableAttributedString(string: actualResults, attributes: [
            .foregroundColor: NSColor.secondaryLabelColor,
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize),
        ])

        let firstQuote = (actualResults as NSString).range(of: "\"")
        let secondQuote = (actualResults as NSString).range(of: "\"", options: .backwards)
        let range = NSUnionRange(firstQuote, secondQuote)
        attributes.setAttributes([
            .foregroundColor: NSColor.textColor,
            .font: NSFont.systemFont(ofSize: NSFont.systemFontSize, weight: .medium),
        ], range: range)
        return attributes
    }

    func clearSearch() {
        self.documentWindowViewModel.searchString = nil
    }

    var selectedResults: [SearchResult] = [] {
        didSet {
            self.documentWindowViewModel.updateSelection(self.selectedResults.map(\.sidebarItem))
        }
    }

    private var cachedResults: [SearchResultGroup]?
    var results: [SearchResultGroup] {
        if let results = self.cachedResults {
            return results
        }

        var results = [SearchResultGroup]()
        let canvases = self.matchingCanvases
        if canvases.count > 0 {
            results.append(SearchResultGroup(title: "Canvases", results: canvases))
        }

        let pages = self.matchingPages
        if pages.count > 0 {
            results.append(SearchResultGroup(title: "Pages", results: pages))
        }
        self.cachedResults = results
        return results
    }

    private var matchingCanvases: [CanvasSearchResult] {
        guard self.searchString.count > 0 else {
            return []
        }
        let canvasMatches = self.modelController.canvasCollection.matches(forSearchString: self.searchString)
        let sortedCanvases = canvasMatches.map { CanvasSearchResult(match: $0, searchString: self.searchString) }
        return sortedCanvases
    }

    private var matchingPages: [PageSearchResult] {
        guard self.searchString.count > 0 else {
            return []
        }
        let pageMatches = self.modelController.pageCollection.matches(forSearchString: self.searchString)
        let sortedPages = pageMatches.map { PageSearchResult(match: $0, searchString: self.searchString) }
        return sortedPages
    }

    private func reload() {
        self.cachedResults = nil
        self.view?.reload()
    }

    func addPages(with ids: [ModelID], to canvas: Canvas) -> Bool {
        let pages = ids.compactMap { self.modelController.pageCollection.objectWithID($0) }

        let addedPages = canvas.addPages(pages)

        return (addedPages.count > 0)
    }



    //MARK: - KVO
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == #keyPath(headerText) {
            keyPaths.insert("searchString")
        }
        return keyPaths
    }
}
