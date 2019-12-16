//
//  TextEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol TextEditorView: Editor {
    func addLink(with url: URL, to range: NSRange)
}

class TextEditorViewModel: ViewModel {
    weak var view: TextEditorView?
    
    @objc dynamic let textContent: TextPageContent
    let textAutoLinker: PageLinkManager
    convenience init(textContent: TextPageContent, documentWindowViewModel: DocumentWindowViewModel) {
        self.init(textContent: textContent,
                  documentWindowViewModel: documentWindowViewModel,
                  textAutoLinker: PageLinkManager(modelController: documentWindowViewModel.modelController))
    }

    init(textContent: TextPageContent, documentWindowViewModel: DocumentWindowViewModel, textAutoLinker: PageLinkManager) {
        self.textContent = textContent
        self.textAutoLinker = textAutoLinker
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == "attributedText") {
            keyPaths.insert("textContent.text")
        }
        return keyPaths
    }

    @objc dynamic var attributedText: NSAttributedString {
        get { self.textContent.text }
        set { self.textContent.text = newValue }
    }

    func createNewLinkedPage(for range: NSRange) {
        let selectedText = self.attributedText.attributedSubstring(from: range)
        let page = self.modelController.collection(for: Page.self).newObject() { $0.title = selectedText.string }
        self.link(to: page, for: range)
    }

    func link(to page: Page, for range: NSRange) {
        self.view?.addLink(with: page.linkToPage(from: self.textContent.page).url, to: range)
    }

    var undoManager: UndoManager {
        return self.modelController.undoManager
    }
}


