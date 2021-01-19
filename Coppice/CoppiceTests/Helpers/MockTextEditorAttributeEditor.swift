//
//  MockTextEditorAttributeEditor.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 19/01/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import AppKit
@testable import Coppice

class MockTextEditorAttributeEditor: TextEditorAttributeEditor {
    var updatedFontAttributes: TextEditorFontAttributes?
    override func updateSelection(with editorAttributes: TextEditorFontAttributes) {
        self.updatedFontAttributes = editorAttributes
    }

    var updatedParagraphAttributes: TextEditorParagraphAttributes?
    override func updateSelection(with paragraphAttributes: TextEditorParagraphAttributes) {
        self.updatedParagraphAttributes = paragraphAttributes
    }

    var updatedListType: NSTextList?
    override func updateSelection(withListType listType: NSTextList?) {
        self.updatedListType = listType
    }
}
