//
//  TextEditorInspectorTypes.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import Combine

class Typeface: NSObject {
    let fontName: String
    @objc dynamic let displayName: String
    let traits: NSFontTraitMask
    let weight: Int

    init?(memberInfo: [Any]) {
        guard memberInfo.count == 4,
            let fontName = memberInfo[0] as? String,
            let displayName = memberInfo[1] as? String,
            let weight = memberInfo[2] as? Int,
            let rawTraits = memberInfo[3] as? UInt else {
                return nil
        }
        self.fontName = fontName
        self.displayName = displayName
        self.traits = NSFontTraitMask(rawValue: rawTraits)
        self.weight = weight
        super.init()
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let otherTypeface = object as? Typeface else {
            return false
        }
        return self.fontName == otherTypeface.fontName
    }
}

class TextColourList: NSObject {
    private(set) var colours = [TextColour]()
    func add(_ textColour: TextColour) {
        colours.append(textColour)
    }

    var selectedColour: NSColor?
}


class TextColour: NSObject {
    let name: String
    let colour: NSColor
    init(name: String = "", colour: NSColor) {
        self.name = name
        self.colour = colour
        super.init()
    }

    var identifier: String {
        return self.colour.identifier ?? self.name
    }

    override func isEqual(_ object: Any?) -> Bool {
        guard let otherColour = object as? TextColour else {
            return false
        }
        return self.identifier == otherColour.identifier
    }
}



protocol InspectableTextEditor {
    var selectionAttributes: TextEditorAttributes? { get }
    var selectionAttributesDidChange: AnyPublisher<TextEditorAttributes?, Never> { get }

    func updateSelection(with attributes: TextEditorAttributes)
}
