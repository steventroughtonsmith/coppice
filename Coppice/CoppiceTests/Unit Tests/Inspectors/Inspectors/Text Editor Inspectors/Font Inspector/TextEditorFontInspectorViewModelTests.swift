//
//  TextEditorFontInspectorViewModelTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 26/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
@testable import Coppice
@testable import CoppiceCore
import XCTest

class TextEditorFontInspectorViewModelTests: XCTestCase {
    var editor: MockTextEditorAttributeEditor!
    var modelController: CoppiceModelController!
    var viewModel: TextEditorFontInspectorViewModel!

    override func setUp() {
        super.setUp()

        self.modelController = CoppiceModelController(undoManager: UndoManager())
        self.editor = MockTextEditorAttributeEditor()
        self.viewModel = TextEditorFontInspectorViewModel(attributeEditor: self.editor, modelController: self.modelController)
    }


    //MARK: - Tests

    func test_fontFamilies_returnsAvailableFamiliesFromSystem() {
        let families = NSFontManager.shared.availableFontFamilies
        XCTAssertEqual(self.viewModel.fontFamilies.count, families.count)
    }

    func test_typefaces_returnsAllTypefacesForSelectedFamily() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(fontFamily: "Helvetica")

        let expectedNames = Set(["Light", "Regular", "Light Oblique", "Oblique", "Bold", "Bold Oblique"])

        let typefaceNames = Set(self.viewModel.typefaces.map { $0.displayName })
        XCTAssertEqual(typefaceNames, expectedNames)
    }

    func test_selectedFontFamily_getReturnsFamilyFromAttributes() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(fontFamily: "Helvetica")
        XCTAssertEqual(self.viewModel.selectedFontFamily, "Helvetica")
    }

    func test_selectedFontFamily_setUpdatesEditorWithNewFamily() {
        self.viewModel.selectedFontFamily = "Impact"
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(fontFamily: "Impact"))
    }

    func test_selectedTypeface_getReturnsTypefaceObjectMatchingAttributesPostscriptName() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(fontFamily: "Helvetica", fontPostscriptName: "Helvetica-Bold")
        XCTAssertEqual(self.viewModel.selectedTypeface?.fontName, "Helvetica-Bold")
    }

    func test_selectedTypeface_setUpdatesEditorWithNewPostscriptName() {
        self.viewModel.selectedTypeface = Typeface(memberInfo: ["DejaVuSansMono-Bold", "Bold", 5, UInt(1)])
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(fontPostscriptName: "DejaVuSansMono-Bold"))
    }

    func test_fontSize_getReturnsFontSizeFromAttributes() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(fontSize: .absolute(30.0))
        XCTAssertEqual(self.viewModel.fontSize, NSNumber(floatLiteral: 30.0))
    }

    func test_fontSize_setUpdatesEditorWithNewFontSize() {
        self.viewModel.fontSize = 42.0
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(fontSize: .absolute(42.0)))
    }

    func test_textColour_getReturnsColourFromAttributes() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(textColour: NSColor.red)
        XCTAssertEqual(self.viewModel.textColour, NSColor.red)
    }

    func test_textColour_setUpdatesEditorWithNewTextColour() {
        self.viewModel.textColour = NSColor.green
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(textColour: NSColor.green))
    }

    func test_isBold_getReturnsBoldFromAttributes() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(isBold: true)
        XCTAssertEqual(self.viewModel.isBold, true)
    }

    func test_isBold_setUpdatesEditorWithNewBoldValue() {
        self.viewModel.isBold = true
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(isBold: true))
    }

    func test_isItalic_getReturnsItalicFromAttributes() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(isItalic: true)
        XCTAssertEqual(self.viewModel.isItalic, true)
    }

    func test_isItalic_setUpdatesEditorWithNewItalicValue() {
        self.viewModel.isItalic = true
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(isItalic: true))
    }

    func test_isUnderlined_getReturnsUnderlinedFromAttributes() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(isUnderlined: true)
        XCTAssertEqual(self.viewModel.isUnderlined, true)
    }

    func test_isUnderlined_setUpdatesEditorWithNewUnderlinedValue() {
        self.viewModel.isUnderlined = true
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(isUnderlined: true))
    }

    func test_isStruckthrough_getReturnsStrikethroughFromAttributes() {
        self.editor.selectedFontAttributes = TextEditorFontAttributes(isStruckthrough: true)
        XCTAssertEqual(self.viewModel.isStruckthrough, true)
    }

    func test_isStruckthrough_setUpdatesEditorWithNewStrikethroughValue() {
        self.viewModel.isStruckthrough = true
        XCTAssertEqual(self.editor.updatedFontAttributes, TextEditorFontAttributes(isStruckthrough: true))
    }
}
