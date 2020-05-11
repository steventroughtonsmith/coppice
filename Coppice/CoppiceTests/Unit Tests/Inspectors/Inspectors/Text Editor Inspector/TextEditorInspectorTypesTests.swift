//
//  TextEditorInspectorTypesTests.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 26/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import XCTest
@testable import Coppice

class TextEditorInspectorTypesTests: XCTestCase {

    func test_typeface_initAssignsValuesToCorrectProperties() throws {
        let fontTraitMask = NSFontTraitMask(arrayLiteral: [.boldFontMask, .italicFontMask])
        let fontMember: [Any] = ["Helvetica-Bold", "Bold", 4, fontTraitMask.rawValue]

        let typeface = try XCTUnwrap(Typeface(memberInfo: fontMember))
        XCTAssertEqual(typeface.fontName, "Helvetica-Bold")
        XCTAssertEqual(typeface.displayName, "Bold")
        XCTAssertEqual(typeface.weight, 4)
        XCTAssertEqual(typeface.traits, fontTraitMask)
    }

    func test_typeface_equalityIsBasedOffFontName() throws {
        let typeface1 = try XCTUnwrap(Typeface(memberInfo: ["Helvetica-Bold", "Bold", 4, UInt(1)]))
        let typeface2 = try XCTUnwrap(Typeface(memberInfo: ["Helvetica-Bold", "Oblique", 5, UInt(2)]))

        XCTAssertEqual(typeface1, typeface2)
    }

}
