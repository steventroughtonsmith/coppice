//
//  TextEditorAttributesTests.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 26/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Bubbles

class TextEditorAttributesTests: XCTestCase {

    //MARK: init(attributes:)
    func test_initAttributes_getsFontFamilyFromFont() {
        let editorAttributes = TextEditorAttributes(attributes: [.font: NSFont(name: "Helvetica-Bold", size: 14)!])
        XCTAssertEqual(editorAttributes.fontFamily, "Helvetica")
    }

    func test_initAttributes_getsPostscriptNameFromFont() {
        let editorAttributes = TextEditorAttributes(attributes: [.font: NSFont(name: "Helvetica-Bold", size: 14)!])
        XCTAssertEqual(editorAttributes.fontPostscriptName, "Helvetica-Bold")
    }

    func test_initAttributes_getsFontSizeFromFont() {
        let editorAttributes = TextEditorAttributes(attributes: [.font: NSFont(name: "Helvetica-Bold", size: 14)!])
        XCTAssertEqual(editorAttributes.fontSize, 14)
    }

    func test_initAttributes_getsTextColourFromForegroundColour() {
        let editorAttributes = TextEditorAttributes(attributes: [.foregroundColor: NSColor.purple])
        XCTAssertEqual(editorAttributes.textColour, NSColor.purple)
    }

    func test_initAttributes_getsAlignmentFromParagraphStyle() {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        let editorAttributes = TextEditorAttributes(attributes: [.paragraphStyle: paragraphStyle])
        XCTAssertEqual(editorAttributes.alignment, .center)
    }

    func test_initAttributes_getsBoldFromFont() {
        let editorAttributes = TextEditorAttributes(attributes: [.font: NSFont(name: "Helvetica-Bold", size: 14)!])
        XCTAssertEqual(editorAttributes.isBold, true)
    }

    func test_initAttributes_getsItalicFromFont() {
        let editorAttributes = TextEditorAttributes(attributes: [.font: NSFont(name: "Helvetica-Oblique", size: 14)!])
        XCTAssertEqual(editorAttributes.isItalic, true)
    }

    func test_initAttributes_getsUnderlinedFromUnderlineStyle() {
        let editorAttributes = TextEditorAttributes(attributes: [.underlineStyle: 1])
        XCTAssertEqual(editorAttributes.isUnderlined, true)
    }

    func test_initAttribute_getsStruckthroughFromStrikethroughStyle() {
        let editorAttributes = TextEditorAttributes(attributes: [.strikethroughStyle: 1])
        XCTAssertEqual(editorAttributes.isStruckthrough, true)
    }


    //MARK: TextEditorAttributes.merge(_:)
    func test_merge_mergingTwoIdentialEditorsResultInAnUnchangedEditor() {
        let attributes = TextEditorAttributes(fontFamily: "Helvetica",
                                              fontPostscriptName: "Helvetica-Bold",
                                              fontSize: 15,
                                              textColour: NSColor.black,
                                              alignment: .left,
                                              isBold: true,
                                              isItalic: false,
                                              isUnderlined: true,
                                              isStruckthrough: false)

        let mergedAttributes = TextEditorAttributes.merge([attributes, attributes])
        XCTAssertEqual(mergedAttributes, attributes)
    }

    func test_merge_mergingTwoCompletelyDifferentEditorsResultsInANilEditor() {
        let attributes1 = TextEditorAttributes(fontFamily: "Helvetica",
                                               fontPostscriptName: "Helvetica-Bold",
                                               fontSize: 15,
                                               textColour: NSColor.black,
                                               alignment: .left,
                                               isBold: true,
                                               isItalic: false,
                                               isUnderlined: true,
                                               isStruckthrough: false)

        let attributes2 = TextEditorAttributes(fontFamily: "Arial",
                                               fontPostscriptName: "Arial-Bold",
                                               fontSize: 20,
                                               textColour: NSColor.blue,
                                               alignment: .right,
                                               isBold: false,
                                               isItalic: true,
                                               isUnderlined: false,
                                               isStruckthrough: true)

        let mergedAttributes = TextEditorAttributes.merge([attributes1, attributes2])
        let expectedAttributes = TextEditorAttributes()
        XCTAssertEqual(mergedAttributes, expectedAttributes)
    }

    func test_merge_mergingTwoPartlyDifferentEditorsResultsInSameFieldsBeingUnchangedAndDifferentFieldsBeingNil() {
        let attributes1 = TextEditorAttributes(fontFamily: "Helvetica",
                                               fontPostscriptName: "Helvetica-Bold",
                                               fontSize: 15,
                                               textColour: NSColor.black,
                                               alignment: .left,
                                               isBold: true,
                                               isItalic: false,
                                               isUnderlined: true,
                                               isStruckthrough: false)

        let attributes2 = TextEditorAttributes(fontFamily: "Helvetica",
                                               fontPostscriptName: "Helvetica-Oblique",
                                               fontSize: 15,
                                               textColour: NSColor.blue,
                                               alignment: .left,
                                               isBold: false,
                                               isItalic: true,
                                               isUnderlined: true,
                                               isStruckthrough: false)


        let expectedAttributes = TextEditorAttributes(fontFamily: "Helvetica",
                                                      fontPostscriptName: nil,
                                                      fontSize: 15,
                                                      textColour: nil,
                                                      alignment: .left,
                                                      isBold: nil,
                                                      isItalic: nil,
                                                      isUnderlined: true,
                                                      isStruckthrough: false)

        let mergedAttributes = TextEditorAttributes.merge([attributes1, attributes2])
        XCTAssertEqual(mergedAttributes, expectedAttributes)
    }


    //MARK: apply(to:)
    func test_applyTo_updatesFontFamilyKeepingBoldAndItalicSameIfSet() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-BoldOblique", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(fontFamily: "Menlo")
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), NSFont(name: "Menlo-BoldItalic", size: 14)!)
    }

    func test_applyTo_updatesFontOverridingBoldAndItalicPostScriptNameIsSet() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-Bold", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(fontPostscriptName: "Menlo-Italic")
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), NSFont(name: "Menlo-Italic", size: 14)!)
    }

    func test_applyTo_keepsFamilyAndItalicTheSameButAddsBoldIfSetToTrue() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-Oblique", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(isBold: true)
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), NSFont(name: "Helvetica-BoldOblique", size: 14)!)
    }

    func test_applyTo_keepsFamilyAndItalicTheSameButRemovesBoldIfSetToFalse() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-BoldOblique", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(isBold: false)
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), NSFont(name: "Helvetica-Oblique", size: 14)!)
    }

    func test_applyTo_keepsFamilyAndBoldTheSameButAddsItalicIfSetToTrue() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-Bold", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(isItalic: true)
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), NSFont(name: "Helvetica-BoldOblique", size: 14)!)
    }

    func test_applyTo_keepsFamilyAndBoldTheSameButRemovesItalicIfSetToFalse() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-BoldOblique", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(isItalic: false)
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), NSFont(name: "Helvetica-Bold", size: 14)!)
    }

    func test_applyTo_fallsBackToNonItalicFontIfOneDoesntExistInNewFontFamily() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-BoldOblique", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(fontFamily: "Arial Hebrew")
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), NSFont(name: "ArialHebrew-Bold", size: 14)!)
    }

    func test_applyTo_fallsBackToNonBoldFontIfOneDoesntExistInNewFontFamily() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-BoldOblique", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes(fontFamily: "Impact")
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        let font = (newAttributes[.font] as? NSFont)
        //For some reason NSFont doesn't like equality on Impact
        XCTAssertEqual(font?.fontName, NSFont(name: "Impact", size: 14)!.fontName)
    }

    func test_applyTo_doesntUpdateFontIfFamily_PostScriptFont_Bold_andItalicAreNil() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica-BoldOblique", size: 14)!
        ]

        let editorAttributes = TextEditorAttributes()
        let newAttributes = editorAttributes.apply(to: baseAttributes)

        XCTAssertEqual((newAttributes[.font] as? NSFont), (baseAttributes[.font] as? NSFont))
    }

    func test_applyTo_updatesTextColourIfSet() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.yellow
        ]

        let editorAttributes = TextEditorAttributes(textColour: NSColor.orange)
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertEqual((newAttributes[.foregroundColor] as? NSColor), NSColor.orange)
    }

    func test_applyTo_doesntUpdateTextColourIfNil() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.yellow
        ]

        let editorAttributes = TextEditorAttributes()
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertEqual((newAttributes[.foregroundColor] as? NSColor), NSColor.yellow)
    }

    func test_applyTo_updatesParagraphStyleAlignmentIfSet() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: NSParagraphStyle()
        ]

        let editorAttributes = TextEditorAttributes(alignment: .right)
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertEqual((newAttributes[.paragraphStyle] as? NSParagraphStyle)?.alignment, .right)
    }

    func test_applyTo_doesntUpdateParagraphStyleIfNil() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: NSParagraphStyle()
        ]

        let editorAttributes = TextEditorAttributes()
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertEqual((newAttributes[.paragraphStyle] as? NSParagraphStyle), NSParagraphStyle())
    }

    func test_applyTo_updatesUnderlineStyleIfSet() {
        let baseAttributes: [NSAttributedString.Key: Any] = [:]

        let editorAttributes = TextEditorAttributes(isUnderlined: true)
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertEqual((newAttributes[.underlineStyle] as? Int), 1)
    }

    func test_applyTo_doesntUpdateUnderlineStyleIfNil() {
        let baseAttributes: [NSAttributedString.Key: Any] = [:]

        let editorAttributes = TextEditorAttributes()
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertNil(newAttributes[.underlineStyle])
    }

    func test_applyTo_updatesStrikethroughStyleIfSet() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: 1
        ]

        let editorAttributes = TextEditorAttributes(isStruckthrough: false)
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertNil(newAttributes[.strikethroughStyle])
    }

    func test_applyTo_doesntUpdateStrikethroughStyleifNil() {
        let baseAttributes: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: 1
        ]

        let editorAttributes = TextEditorAttributes()
        let newAttributes = editorAttributes.apply(to: baseAttributes)
        XCTAssertEqual((newAttributes[.strikethroughStyle] as? Int), 1)
    }


    //MARK: - NSMutableAttributesString Extensions

    private func createTestString() -> NSMutableAttributedString {
        let testString = NSMutableAttributedString(string: "foo bar baz possum")

        let attributes1: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Helvetica", size: 14)!,
            .foregroundColor: NSColor.red,
            .underlineStyle: 1
        ]
        testString.setAttributes(attributes1, range: NSRange(location: 0, length: 3))
        testString.setAttributes(attributes1, range: NSRange(location: 8, length: 3))

        let attributes2: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Menlo-Bold", size: 14)!,
            .foregroundColor: NSColor.green,
            .strikethroughStyle: 1
        ]
        testString.setAttributes(attributes2, range: NSRange(location: 4, length: 3))

        let attributes3: [NSAttributedString.Key: Any] = [
            .font: NSFont(name: "Menlo-Italic", size: 15)!,
            .foregroundColor: NSColor.blue,
            .strikethroughStyle: 1
        ]
        testString.setAttributes(attributes3, range: NSRange(location: 12, length: 6))

        return testString
    }

    //MARK: - textEditorAttributes(in:typingAttributes:)
    func test_textEditorAttributesInRanges_returnsAttributesWithAllValuesSetIfAttributesAreEqualInRanges() {
        let testString = self.createTestString()
        let attributes = testString.textEditorAttributes(in: [
            NSRange(location: 0, length: 3),
            NSRange(location: 8, length: 3)
        ], typingAttributes: [:])

        XCTAssertEqual(attributes.fontFamily, "Helvetica")
        XCTAssertEqual(attributes.fontPostscriptName, "Helvetica")
        XCTAssertEqual(attributes.fontSize, 14)
        XCTAssertEqual(attributes.textColour, NSColor.red)
        XCTAssertEqual(attributes.isBold, false)
        XCTAssertEqual(attributes.isItalic, false)
        XCTAssertEqual(attributes.isUnderlined, true)

    }

    func test_textEditorAttributesInRanges_returnsMergedAttributesIfAttributesInRangesAreDifferent() {
        let testString = self.createTestString()
        let attributes = testString.textEditorAttributes(in: [
            NSRange(location: 4, length: 3),
            NSRange(location: 12, length: 6)
        ], typingAttributes: [:])

        XCTAssertEqual(attributes.fontFamily, "Menlo")
        XCTAssertNil(attributes.fontPostscriptName)
        XCTAssertNil(attributes.fontSize)
        XCTAssertNil(attributes.textColour)
        XCTAssertNil(attributes.isBold)
        XCTAssertNil(attributes.isItalic)
        XCTAssertEqual(attributes.isStruckthrough, true)
    }


    //MARK: - apply(_:to:)
    func test_applyTextEditorAttributes_updatesAttributesOfAllRangesToMatchSuppliedAttributes() {
        let testString = self.createTestString()

        let testAttributes = TextEditorAttributes(fontFamily: "Arial", fontSize: 16, isUnderlined: false, isStruckthrough: true)
        testString.apply(testAttributes, to: [
            NSRange(location: 0, length: 18)
        ])

        XCTAssertEqual((testString.attribute(.font, at: 0, effectiveRange: nil) as? NSFont), NSFont(name: "ArialMT", size: 16))
        XCTAssertEqual((testString.attribute(.font, at: 4, effectiveRange: nil) as? NSFont), NSFont(name: "Arial-BoldMT", size: 16))
        XCTAssertEqual((testString.attribute(.font, at: 8, effectiveRange: nil) as? NSFont), NSFont(name: "ArialMT", size: 16))
        XCTAssertEqual((testString.attribute(.font, at: 12, effectiveRange: nil) as? NSFont), NSFont(name: "Arial-ItalicMT", size: 16))

        XCTAssertEqual((testString.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? NSColor), NSColor.red)
        XCTAssertEqual((testString.attribute(.foregroundColor, at: 4, effectiveRange: nil) as? NSColor), NSColor.green)
        XCTAssertEqual((testString.attribute(.foregroundColor, at: 8, effectiveRange: nil) as? NSColor), NSColor.red)
        XCTAssertEqual((testString.attribute(.foregroundColor, at: 12, effectiveRange: nil) as? NSColor), NSColor.blue)

        XCTAssertNil(testString.attribute(.underlineStyle, at: 0, effectiveRange: nil))
        XCTAssertNil(testString.attribute(.underlineStyle, at: 4, effectiveRange: nil))
        XCTAssertNil(testString.attribute(.underlineStyle, at: 8, effectiveRange: nil))
        XCTAssertNil(testString.attribute(.underlineStyle, at: 12, effectiveRange: nil))

        XCTAssertEqual((testString.attribute(.strikethroughStyle, at: 0, effectiveRange: nil) as? Int), 1)
        XCTAssertEqual((testString.attribute(.strikethroughStyle, at: 4, effectiveRange: nil) as? Int), 1)
        XCTAssertEqual((testString.attribute(.strikethroughStyle, at: 8, effectiveRange: nil) as? Int), 1)
        XCTAssertEqual((testString.attribute(.strikethroughStyle, at: 12, effectiveRange: nil) as? Int), 1)
    }
}


