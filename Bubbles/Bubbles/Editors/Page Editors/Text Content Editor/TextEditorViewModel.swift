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

class TextEditorViewModel: NSObject {
    weak var view: TextEditorView?
    
    @objc dynamic let textContent: TextPageContent
    let modelController: ModelController
    let documentWindowState: DocumentWindowState
    let textAutoLinker: PageLinkManager
    convenience init(textContent: TextPageContent, modelController: ModelController, documentWindowState: DocumentWindowState) {
        self.init(textContent: textContent,
                  modelController: modelController,
                  documentWindowState: documentWindowState,
                  textAutoLinker: PageLinkManager(modelController: modelController))
    }

    init(textContent: TextPageContent, modelController: ModelController, documentWindowState: DocumentWindowState, textAutoLinker: PageLinkManager) {
        self.textContent = textContent
        self.modelController = modelController
        self.documentWindowState = documentWindowState
        self.textAutoLinker = textAutoLinker
        super.init()
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

    private var changeRange: NSRange?

    func textWillChange(in range: NSRange) {
        self.changeRange = range
    }

    func textDidChange() {
        guard let changeRange = self.changeRange else {
            return
        }

//        let newLinks = self.textAutoLinker.findNewLinks(in: self.attributedText, forChangeIn: changeRange)
//        for link in newLinks {
//            self.view?.addLink(with: link.url, to: link.range)
//        }

        self.changeRange = nil
//        let maxTitleRange = 10
//        let start = max(changeRange.location - maxTitleRange, 0)
//        let end = min(NSMaxRange(changeRange) + maxTitleRange, self.attributedText.length)
//
//        let range = NSRange(location: start, length: end-start)
//        let searchString = (self.attributedText.string as NSString).substring(with: range)


        //Need to add auto links when typing
        //Need to update auto links when changing page title
        //Need to update auto links when adding/removing page
        //Need to verify auto links when opening a page
    }

    private func findAndCreateLinks(in range: NSRange) {

    }

}


