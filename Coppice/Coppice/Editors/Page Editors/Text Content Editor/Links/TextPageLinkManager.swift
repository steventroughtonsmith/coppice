//
//  TextAutoLinker.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore
import M3Data

protocol TextPageLinkManagerDelegate: AnyObject {
    func willStartParsing(in manager: TextPageLinkManager)
    func didFinishParsing(in manager: TextPageLinkManager)
    func shouldChangeText(in ranges: [NSRange], manager: TextPageLinkManager) -> Bool
    func textDidChange(in manager: TextPageLinkManager)
}

extension TextPageLinkManagerDelegate {
    func willStartParsing(in manager: TextPageLinkManager) {}
    func didFinishParsing(in manager: TextPageLinkManager) {}
}


class TextPageLinkManager: PageLinkManager {
    private var observer: ModelCollection<Page>.Observation!
    private let parsingDelay: TimeInterval
    init(pageID: ModelID, modelController: ModelController, parsingDelay: TimeInterval = 0.5) {
        self.parsingDelay = parsingDelay

        super.init(pageID: pageID, modelController: modelController)

        self.observer = self.modelController.collection(for: Page.self).addObserver { [weak self] (change) in
            //Update if the current page's content was updated
            if change.object.id == self?.pageID && change.didUpdate(\.content) {
                self?.setNeedsReparse()
                return
            }

            //Update, ignoring the last parsed text, if a page was added, deleted, or has its title or allowsAutoLinking changed
            guard change.changeType != .update || change.didUpdate(\.title) || change.didUpdate(\.allowsAutoLinking) else {
                return
            }
            self?.lastParsedText = nil
            self?.setNeedsReparse()
        }
    }

    deinit {
        if let observer = self.observer {
            self.modelController.collection(for: Page.self).removeObserver(observer)
        }
    }

    /// The current text storage
    weak var currentTextStorage: NSTextStorage? {
        didSet {
            self.setNeedsReparse()
        }
    }

    weak var delegate: TextPageLinkManagerDelegate?


    //Update on all of them
    private func setNeedsReparse() {
        guard
            UserDefaults.standard.bool(forKey: .autoLinkingTextPagesEnabled),
            self.isProEnabled
        else {
            return
        }
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(self.reparseLinks), object: nil)
        guard self.isReparsing == false else {
            return
        }

        self.perform(#selector(self.reparseLinks), with: nil, afterDelay: self.parsingDelay)
    }

    private var lastParsedText: NSAttributedString?

    private var isReparsing = false
    @objc private func reparseLinks() {
        self.isReparsing = true
        self.delegate?.willStartParsing(in: self)

        //If we have storage enabled for this page then we want to enable that
        if let storage = self.currentTextStorage {
            self.update(storage)
        //Otherwise we just want to update the content
        } else if let page = self.modelController.collection(for: Page.self).objectWithID(self.pageID) {
            self.update(page)
        }

        self.delegate?.didFinishParsing(in: self)

        self.isReparsing = false
    }

    private func update(_ storage: NSTextStorage) {
        guard storage != self.lastParsedText else {
            return
        }
        let pages = Array(self.modelController.collection(for: Page.self).all)
        var ignoring = [Page]()
        if let page = self.modelController.collection(for: Page.self).objectWithID(self.pageID) {
            ignoring.append(page)
        }
        ignoring.append(contentsOf: pages.filter { $0.allowsAutoLinking == false })
        let links = TextLinkFinder().findLinkChanges(in: storage, using: pages, ignoring: ignoring)

        guard (links.linksToAdd.count > 0) || (links.linksToRemove.count > 0) else {
            return
        }

        let shouldChange = self.delegate?.shouldChangeText(in: [NSRange(location: 0, length: storage.length)], manager: self) ?? true
        guard shouldChange else {
            return
        }

        storage.beginEditing()
        for link in links.linksToRemove {
            storage.removeAttribute(.link, range: link.range)
        }
        for link in links.linksToAdd {
            if let url = link.url {
                storage.addAttribute(.link, value: url, range: link.range)
            }
        }
        storage.endEditing()

        self.delegate?.textDidChange(in: self)
        self.lastParsedText = storage.copy() as? NSAttributedString
    }

    private func update(_ page: Page) {
        guard let textContent = page.content as? TextPageContent,
            textContent.text != self.lastParsedText
        else {
            return
        }
        let pages = Array(self.modelController.collection(for: Page.self).all)
        var ignoring: [Page] = [page]
        ignoring.append(contentsOf: pages.filter { $0.allowsAutoLinking == false })
        let links = TextLinkFinder().findLinkChanges(in: textContent.text, using: pages, ignoring: ignoring)

        guard (links.linksToAdd.count > 0) || (links.linksToRemove.count > 0) else {
            return
        }
        guard let mutableString = textContent.text.mutableCopy() as? NSMutableAttributedString else {
            return
        }
        for link in links.linksToRemove {
            mutableString.removeAttribute(.link, range: link.range)
        }
        for link in links.linksToAdd {
            if let url = link.url {
                mutableString.addAttribute(.link, value: url, range: link.range)
            }
        }
        textContent.text = mutableString
        self.lastParsedText = mutableString.copy() as? NSAttributedString
    }
}

extension TextPageLinkManager: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        self.setNeedsReparse()
    }
}



