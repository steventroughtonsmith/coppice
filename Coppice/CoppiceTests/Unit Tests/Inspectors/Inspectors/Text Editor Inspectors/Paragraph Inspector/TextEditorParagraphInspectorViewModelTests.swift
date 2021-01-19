//
//  TextEditorParagraphInspectorViewModelTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 19/01/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import XCTest
import Combine
@testable import Coppice
@testable import CoppiceCore

class TextEditorParagraphInspectorViewModelTests: XCTestCase {

    var editor: MockTextEditorAttributeEditor!
    var modelController: CoppiceModelController!
    var viewModel: TextEditorParagraphInspectorViewModel!

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
        self.editor = MockTextEditorAttributeEditor()
        self.viewModel = TextEditorParagraphInspectorViewModel(attributeEditor: self.editor, modelController: self.modelController)
    }


    //MARK: - Tests
    func test_rawAlignment_getReturnsAlignmentFromParagraphAttributes() throws {
        self.editor.selectedParagraphAttributes = TextEditorParagraphAttributes(alignment: .center)
        XCTAssertEqual(self.viewModel.rawAlignment, NSTextAlignment.center.rawValue)
    }

    func test_rawAlignment_setUpdatesEditorWithNewAlignment() throws {
        self.viewModel.rawAlignment = NSTextAlignment.justified.rawValue
        XCTAssertEqual(self.editor.updatedParagraphAttributes?.alignment, .justified)
    }

    func test_paragraphSpacing_getReturnsSpacingFromParagraphAttributes() throws {
        self.editor.selectedParagraphAttributes = TextEditorParagraphAttributes(paragraphSpacing: 5.0)
        XCTAssertEqual(self.viewModel.paragraphSpacing, NSNumber(floatLiteral: 5.0))
    }

    func test_paragraphSpacing_setUpdatesEditorWithNewSpacing() throws {
        self.viewModel.paragraphSpacing = NSNumber(floatLiteral: 42)
        XCTAssertEqual(self.editor.updatedParagraphAttributes?.paragraphSpacing, 42.0)
    }

    func test_lineHeightMultiple_getReturnsLineHeightFromParagraphAttributes() throws {
        self.editor.selectedParagraphAttributes = TextEditorParagraphAttributes(lineHeightMultiple: 1.2)
        XCTAssertEqual(self.viewModel.lineHeightMultiple, NSNumber(floatLiteral: 1.2))
    }

    func test_lineHeightMultiple_getReturns1IfMultipleInParagraphAttributesIs0() throws {
        self.editor.selectedParagraphAttributes = TextEditorParagraphAttributes(lineHeightMultiple: 0)
        XCTAssertEqual(self.viewModel.lineHeightMultiple, NSNumber(floatLiteral: 1.0))
    }

    func test_lineHeightMultiple_setUpdatesEditorWithNewLineHeight() throws {
        self.viewModel.lineHeightMultiple = NSNumber(floatLiteral: 1.5)
        XCTAssertEqual(self.editor.updatedParagraphAttributes?.lineHeightMultiple, 1.5)
    }

    func test_listTypes_returnsListTypesFromEditor() throws {
        let listTypes = [NSTextList(markerFormat: .box, options: 0), NSTextList(markerFormat: .lowercaseHexadecimal, options: 0)]
        self.editor.selectedListTypes = listTypes
        XCTAssertEqual(self.viewModel.listTypes, listTypes)
    }

    func test_updateListType_updatesListTypeOnEditor() throws {
        let newList = NSTextList(markerFormat: .uppercaseLatin, options: 0)
        self.viewModel.updateListType(to: newList)
        XCTAssertEqual(self.editor.updatedListType, newList)
    }
}
