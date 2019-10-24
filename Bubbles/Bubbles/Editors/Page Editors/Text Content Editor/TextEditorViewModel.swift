//
//  TextEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol TextEditorView: class {

}

class TextEditorViewModel: NSObject {
    weak var view: TextEditorView?
    
    @objc dynamic let textContent: TextPageContent
    let modelController: ModelController
    init(textContent: TextPageContent, modelController: ModelController) {
        self.textContent = textContent
        self.modelController = modelController
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
        let page = self.modelController.collection(for: Page.self).newPage(title: selectedText.string)
        self.link(to: page, for: range)
    }

    func link(to page: Page, for range: NSRange) {
        guard let mutableText = self.attributedText.mutableCopy() as? NSMutableAttributedString else {
            return
        }

        mutableText.addAttribute(.link, value: page.linkToPage(from: self.textContent.page).url, range: range)

        self.attributedText = mutableText
    }
}


