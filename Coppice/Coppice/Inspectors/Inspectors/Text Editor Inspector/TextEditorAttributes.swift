//
//  TextEditorAttributes.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

struct TextEditorAttributes: Equatable {
    let fontFamily: String?
    let fontPostscriptName: String?
    let fontSize: CGFloat?
    let textColour: NSColor?
    let alignment: NSTextAlignment?

    let isBold: Bool?
    let isItalic: Bool?
    let isUnderlined: Bool?
    let isStruckthrough: Bool?

    init(fontFamily: String? = nil, fontPostscriptName: String? = nil, fontSize: CGFloat? = nil, textColour: NSColor? = nil,
         alignment: NSTextAlignment? = nil, isBold: Bool? = nil, isItalic: Bool? = nil, isUnderlined: Bool? = nil, isStruckthrough: Bool? = nil) {
        self.fontFamily = fontFamily
        self.fontPostscriptName = fontPostscriptName
        self.fontSize = fontSize
        self.textColour = textColour
        self.alignment = alignment
        self.isBold = isBold
        self.isItalic = isItalic
        self.isUnderlined = isUnderlined
        self.isStruckthrough = isStruckthrough
    }

    init(attributes: [NSAttributedString.Key: Any]) {
        let font = attributes[.font] as? NSFont
        let fontFamily = font?.familyName
        let fontPostscriptName = font?.fontDescriptor.postscriptName
        let fontSize = font?.pointSize
        let textColour = attributes[.foregroundColor] as? NSColor
        let paragraphStyle = attributes[.paragraphStyle] as? NSParagraphStyle
        let underlined = attributes[.underlineStyle] as? Int
        let struckthrough = attributes[.strikethroughStyle] as? Int
        let symbolicTraits = font?.fontDescriptor.symbolicTraits

        self.init(fontFamily: fontFamily,
                  fontPostscriptName: fontPostscriptName,
                  fontSize: fontSize,
                  textColour: textColour,
                  alignment: paragraphStyle?.alignment,
                  isBold: symbolicTraits?.contains(.bold),
                  isItalic: symbolicTraits?.contains(.italic),
                  isUnderlined: (underlined == 1),
                  isStruckthrough: (struckthrough == 1))
    }

    static func merge(_ attributes: [TextEditorAttributes]) -> TextEditorAttributes {
        func merge<Value: Hashable>(_ key: KeyPath<Self, Value?>, of attributes: [TextEditorAttributes]) -> Value? {
            let set = Set(attributes.map { $0[keyPath: key] })
            return (set.count == 1) ? set.first! : nil
        }

        return TextEditorAttributes(fontFamily: merge(\.fontFamily, of: attributes),
                                    fontPostscriptName: merge(\.fontPostscriptName, of: attributes),
                                    fontSize: merge(\.fontSize, of: attributes),
                                    textColour: merge(\.textColour, of: attributes),
                                    alignment: merge(\.alignment, of: attributes),
                                    isBold: merge(\.isBold, of: attributes),
                                    isItalic: merge(\.isItalic, of: attributes),
                                    isUnderlined: merge(\.isUnderlined, of: attributes),
                                    isStruckthrough: merge(\.isStruckthrough, of: attributes))
    }

    func apply(to attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var modifiedAttributes = attributes
        if let textColour = self.textColour {
            modifiedAttributes[.foregroundColor] = textColour
        }

        if let alignment = self.alignment {
            let paragraphStyle = (modifiedAttributes[.paragraphStyle] as? NSParagraphStyle)
            let paragraphStyleCopy = (paragraphStyle?.mutableCopy() as? NSMutableParagraphStyle) ?? NSMutableParagraphStyle()
            paragraphStyleCopy.alignment = alignment
            modifiedAttributes[.paragraphStyle] = paragraphStyleCopy
        }

        if let underlined = self.isUnderlined {
            modifiedAttributes[.underlineStyle] = (underlined ? 1 : nil)
        }

        if let strikethrough = self.isStruckthrough {
            modifiedAttributes[.strikethroughStyle] = (strikethrough ? 1 : nil)
        }

        return self.applyFont(to: modifiedAttributes)
    }

    private func applyFont(to attributes: [NSAttributedString.Key: Any]) -> [NSAttributedString.Key: Any] {
        var modifiedAttributes = attributes
        guard let font = (modifiedAttributes[.font] as? NSFont) else {
            return modifiedAttributes
        }

        let fontSize = self.fontSize ?? font.pointSize

        if let postScriptName = self.fontPostscriptName {
            modifiedAttributes[.font] = NSFont(name: postScriptName, size: fontSize)
        } else {
            var fontDescriptor = font.fontDescriptor
            var symbolicTraits = self.limitedSymbolicTraits(from: fontDescriptor)

            if let family = self.fontFamily {
                fontDescriptor = fontDescriptor.withFamily(family)
            }

            if let isBold = self.isBold {
                if isBold {
                    symbolicTraits.insert(.bold)
                } else {
                    symbolicTraits.remove(.bold)
                }
            }

            if let isItalic = self.isItalic {
                if isItalic {
                    symbolicTraits.insert(.italic)
                } else {
                    symbolicTraits.remove(.italic)
                }
            }

            modifiedAttributes[.font] = self.font(from: fontDescriptor, size: fontSize, applying: symbolicTraits)
        }
        return modifiedAttributes
    }

    private var symbolicTraitsWeCareAbout: [NSFontDescriptor.SymbolicTraits] = [.bold, .italic]

    private func limitedSymbolicTraits(from fontDescriptor: NSFontDescriptor) -> NSFontDescriptor.SymbolicTraits {
        var symbolicTraits = NSFontDescriptor.SymbolicTraits()
        for trait in self.symbolicTraitsWeCareAbout {
            if (fontDescriptor.symbolicTraits.contains(trait)) {
                symbolicTraits.insert(trait)
            }
        }
        return symbolicTraits
    }

    private func font(from fontDescriptor: NSFontDescriptor, size: CGFloat, applying symbolicTraits: NSFontDescriptor.SymbolicTraits) -> NSFont? {
        var font: NSFont? = nil
        var mutableTraits = symbolicTraits
        var problematicTraits: [NSFontDescriptor.SymbolicTraits] = self.symbolicTraitsWeCareAbout
        while (font == nil) && (problematicTraits.count > 0) {
            let newDescriptor = fontDescriptor.withSymbolicTraits(mutableTraits)
            font = NSFont(descriptor: newDescriptor, size: size)
            if let trait = problematicTraits.last {
                mutableTraits.remove(trait)
                problematicTraits.removeLast()
            }
        }

        if font == nil {
            font = NSFont(descriptor: fontDescriptor, size: size)
        }
        return font
    }
}



extension NSMutableAttributedString {
    func textEditorAttributes(in ranges: [NSRange], typingAttributes: [NSAttributedString.Key: Any]) -> TextEditorAttributes {
        var textEditorAttributes = [TextEditorAttributes]()
        for range in ranges {
            self.enumerateAttributes(in: range, options: []) { (attributes, _, _) in
                let mergedAttributes = attributes.merging(typingAttributes) { (key1, _) in key1 }
                textEditorAttributes.append(TextEditorAttributes(attributes: mergedAttributes))
            }
        }
        return TextEditorAttributes.merge(textEditorAttributes)
    }

    func apply(_ textEditorAttributes: TextEditorAttributes, to ranges: [NSRange]) {
        for selectionRange in ranges {
            self.enumerateAttributes(in: selectionRange, options: []) { (textAttributes, range, _) in
                let newAttributes = textEditorAttributes.apply(to: textAttributes)
                self.setAttributes(newAttributes, range: range)
                //We need to make sure we update the selected font so the font panel syncs up
                if let newFont = newAttributes[.font] as? NSFont {
                    NSFontManager.shared.setSelectedFont(newFont, isMultiple: false)
                }
            }
        }
    }
}




