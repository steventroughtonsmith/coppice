//
//  TextEditorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import CoppiceCore
import Foundation

protocol TextEditorView: Editor {
    func addLink(with url: URL, to range: NSRange)
    func updateTextView(with text: NSAttributedString)
}

class TextEditorViewModel: ViewModel {
    weak var view: TextEditorView?

    @objc dynamic let textContent: Page.Content.Text
    let viewMode: PageContentEditorViewMode
    let pageLinkManager: TextPageLinkManager?
    init(textContent: Page.Content.Text, viewMode: PageContentEditorViewMode, documentWindowViewModel: DocumentWindowViewModel, pageLinkManager: TextPageLinkManager?) {
        self.textContent = textContent
        self.viewMode = viewMode
        self.pageLinkManager = pageLinkManager
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    var searchStringObserver: AnyCancellable?
    var textObserver: AnyCancellable?
    override func setup() {
        self.searchStringObserver = self.documentWindowViewModel.publisher(for: \.searchString).sink { [weak self] searchString in
            self?.updateHighlightedRange(with: searchString)
        }
        self.textObserver = self.textContent.$text.sink { [weak self] (text) in
            self?.view?.updateTextView(with: text)
            self?.notifyOfChange(to: \.attributedText)
        }
    }

    @objc dynamic var attributedText: NSAttributedString {
        get { self.textContent.text }
        set { self.textContent.text = newValue }
    }

    @discardableResult func createNewLinkedPage(ofType type: Page.ContentType, from range: NSRange, updatingSelection: Bool = true) -> Page {
        if updatingSelection {
            return self.actuallyCreateNewLinkedPage(ofType: type, from: range)
        }
        return self.documentWindowViewModel.performWithoutUpdatingSelection {
            return self.actuallyCreateNewLinkedPage(ofType: type, from: range)
        }
    }

    private func actuallyCreateNewLinkedPage(ofType type: Page.ContentType, from range: NSRange) -> Page {
        let selectedText = self.attributedText.attributedSubstring(from: range)
        self.modelController.undoManager.beginUndoGrouping()

        let folder: Folder
        if CoppiceSubscriptionManager.shared.state == .enabled {
            folder = self.textContent.page?.containingFolder ?? self.documentWindowViewModel.folderForNewPages
        } else {
            folder = self.documentWindowViewModel.folderForNewPages
        }

        let page = self.modelController.createPage(ofType: type,
                                                   in: folder,
                                                   below: self.textContent.page) {
                                                    $0.title = selectedText.string
        }
        self.link(to: page, for: range)
        self.modelController.undoManager.endUndoGrouping()
        return page
    }

    func link(to page: Page, for range: NSRange) {
        self.view?.addLink(with: page.linkToPage().url, to: range)
    }

    var undoManager: UndoManager {
        return self.modelController.undoManager
    }

    //MARK: - Search
    @Published var highlightedRange: NSRange?

    private func updateHighlightedRange(with searchString: String?) {
        guard let term = searchString else {
            self.highlightedRange = nil
            return
        }

        let range = (self.attributedText.string as NSString).range(of: term, options: .caseInsensitive)
        guard range.location != NSNotFound else {
            self.highlightedRange = nil
            return
        }
        self.highlightedRange = range
    }
}


