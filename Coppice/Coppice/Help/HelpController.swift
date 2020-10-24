//
//  HelpController.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

extension CodingUserInfoKey {
    static let helpBookURL = CodingUserInfoKey(rawValue: "helpBookURL")!
}

class HelpController: NSObject {
    static let shared = HelpController()

    override init() {
        super.init()
        self.loadHelpBook()
    }

    var currentHelpViewer: HelpViewerWindowController?
    func showHelpViewer(initialNavigationItem: NavigationStack.NavigationItem? = nil) {
        guard let helpBook = self.helpBook else {
            return
        }

        if self.currentHelpViewer == nil {
            self.currentHelpViewer = HelpViewerWindowController(helpBook: helpBook)
        }

        self.currentHelpViewer?.showWindow(self)
        if let navigationItem = initialNavigationItem {
            self.currentHelpViewer?.navigate(to: navigationItem)
        }
    }


    private(set) var helpBook: HelpBook?
    private func loadHelpBook() {
        guard
            let url = Bundle.main.url(forResource: "Test", withExtension: "helpbook"),
            let data = try? Data(contentsOf: url.appendingPathComponent("index.json"))
        else {
            return
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.userInfo[.helpBookURL] = url
        do {
            self.helpBook = try decoder.decode(HelpBook.self, from: data)
        } catch let e {
            print("Could not load help book: \(e)")
        }
    }
}


extension HelpController: NSUserInterfaceItemSearching {
    func searchForItems(withSearch searchString: String, resultLimit: Int, matchedItemHandler handleMatchedItems: @escaping ([Any]) -> Void) {
        guard let helpBook = self.helpBook else {
            handleMatchedItems([])
            return
        }
        handleMatchedItems(helpBook.topics(matchingSearchString: searchString))
    }

    func localizedTitles(forItem item: Any) -> [String] {
        guard let result = item as? HelpBook.SearchResult else {
            return []
        }
        return [result.topic.title]
    }

    func performAction(forItem item: Any) {
        guard let result = item as? HelpBook.SearchResult else {
            return
        }
        self.showHelpViewer(initialNavigationItem: .topic(result.topic))
    }

    func showAllHelpTopics(forSearch searchString: String) {
        self.showHelpViewer(initialNavigationItem: .search(searchString))
    }
}

