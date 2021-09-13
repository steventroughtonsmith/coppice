//
//  TextEditorAttributes.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

struct TextEditorFontAttributes: Equatable {
    enum FontSize: Equatable, Hashable {
        case absolute(CGFloat)
        case increase
        case decrease

        func newFontSize(for font: NSFont) -> CGFloat {
            switch self {
            case .absolute(let fontSize):
                return fontSize
            case .increase:
                return font.pointSize + 1
            case .decrease:
                return max(font.pointSize - 1, 1)
            }
        }
    }

    var fontFamily: String? = nil
    var fontPostscriptName: String? = nil
    var fontSize: FontSize? = nil
    var textColour: NSColor? = nil
    var isBold: Bool? = nil
    var isItalic: Bool? = nil
    var isUnderlined: Bool? = nil
    var isStruckthrough: Bool? = nil

    static func withAttributes(_ attributes: [NSAttributedString.Key: Any]) -> Self {
        let font = attributes[.font] as? NSFont
        let fontFamily = font?.familyName
        let fontPostscriptName = font?.fontDescriptor.postscriptName
        let fontSize: FontSize?
        if let size = font?.pointSize {
            fontSize = .absolute(size)
        } else {
            fontSize = nil
        }
        let textColour = attributes[.foregroundColor] as? NSColor
        let underlined = attributes[.underlineStyle] as? Int
        let struckthrough = attributes[.strikethroughStyle] as? Int
        let symbolicTraits = font?.fontDescriptor.symbolicTraits

        return TextEditorFontAttributes(fontFamily: fontFamily,
                                        fontPostscriptName: fontPostscriptName,
                                        fontSize: fontSize,
                                        textColour: textColour,
                                        isBold: symbolicTraits?.contains(.bold),
                                        isItalic: symbolicTraits?.contains(.italic),
                                        isUnderlined: (underlined == 1),
                                        isStruckthrough: (struckthrough == 1))
    }

    static func merge(_ attributes: [TextEditorFontAttributes]) -> TextEditorFontAttributes {
        func merge<Value: Hashable>(_ key: KeyPath<Self, Value?>, of attributes: [TextEditorFontAttributes]) -> Value? {
            let set = Set(attributes.map { $0[keyPath: key] })
            return (set.count == 1) ? set.first! : nil
        }

        return TextEditorFontAttributes(fontFamily: merge(\.fontFamily, of: attributes),
                                        fontPostscriptName: merge(\.fontPostscriptName, of: attributes),
                                        fontSize: merge(\.fontSize, of: attributes),
                                        textColour: merge(\.textColour, of: attributes),
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

        if let postScriptName = self.fontPostscriptName {
            modifiedAttributes[.font] = NSFont(name: postScriptName, size: self.fontSize?.newFontSize(for: font) ?? font.pointSize)
        } else {
            var newFont = font

            if let family = self.fontFamily {
                newFont = NSFontManager.shared.convert(newFont, toFamily: family)
            }

            if let isBold = self.isBold {
                if isBold {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .boldFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(newFont, toNotHaveTrait: .boldFontMask)
                }
            }

            if let isItalic = self.isItalic {
                if isItalic {
                    newFont = NSFontManager.shared.convert(newFont, toHaveTrait: .italicFontMask)
                } else {
                    newFont = NSFontManager.shared.convert(newFont, toNotHaveTrait: .italicFontMask)
                }
            }

            if let fontSize = self.fontSize {
                newFont = NSFontManager.shared.convert(newFont, toSize: fontSize.newFontSize(for: newFont))
            }
            modifiedAttributes[.font] = newFont
        }
        return modifiedAttributes
    }

    private static var symbolicTraitsWeCareAbout: [NSFontDescriptor.SymbolicTraits] = [.bold, .italic]

    private func limitedSymbolicTraits(from fontDescriptor: NSFontDescriptor) -> NSFontDescriptor.SymbolicTraits {
        var symbolicTraits = NSFontDescriptor.SymbolicTraits()
        for trait in Self.symbolicTraitsWeCareAbout {
            if (fontDescriptor.symbolicTraits.contains(trait)) {
                symbolicTraits.insert(trait)
            }
        }
        return symbolicTraits
    }

    private func font(from fontDescriptor: NSFontDescriptor, size: CGFloat, applying symbolicTraits: NSFontDescriptor.SymbolicTraits) -> NSFont? {
        var font: NSFont? = nil
        var mutableTraits = symbolicTraits
        var problematicTraits: [NSFontDescriptor.SymbolicTraits] = Self.symbolicTraitsWeCareAbout
        while (symbolicTraits.rawValue != 0) && (font == nil) && (problematicTraits.count > 0) {
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
    func textEditorFontAttributes(in ranges: [NSRange], typingAttributes: [NSAttributedString.Key: Any]) -> TextEditorFontAttributes {
        var textEditorAttributes = [TextEditorFontAttributes]()
        for range in ranges {
            self.enumerateAttributes(in: range, options: []) { (attributes, _, _) in
                let mergedAttributes = attributes.merging(typingAttributes) { (key1, _) in key1 }
                textEditorAttributes.append(TextEditorFontAttributes.withAttributes(mergedAttributes))
            }
        }
        return TextEditorFontAttributes.merge(textEditorAttributes)
    }

    func apply(_ textEditorAttributes: TextEditorFontAttributes, to ranges: [NSRange]) {
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




