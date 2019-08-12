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
    
    let textContent: TextPageContent
    let modelController: BubblesModelController
    init(textContent: TextPageContent, modelController: BubblesModelController) {
        self.textContent = textContent
        self.modelController = modelController
        super.init()
    }

    @objc dynamic var attributedText: NSAttributedString {
        get { textContent.text }
        set { textContent.text = newValue }
    }

    func createNewLinkedPage(for range: NSRange) {
        let selectedText = self.attributedText.attributedSubstring(from: range)
        self.modelController.pages.newPage(title: selectedText.string)
    }
}


