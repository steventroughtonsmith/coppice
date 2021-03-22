//
//  TextEditorParagraphAttributes.swift
//  Coppice
//
//  Created by Martin Pilkington on 05/12/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit

struct TextEditorParagraphAttributes {
    var alignment: NSTextAlignment? = nil
    var lineHeightMultiple: CGFloat? = nil
    var paragraphSpacing: CGFloat? = nil

    static func with(_ paragraphStyle: NSParagraphStyle) -> Self {
        var alignment = paragraphStyle.alignment
        if (alignment == .natural) {
            var writingDirection = paragraphStyle.baseWritingDirection
            if (writingDirection == .natural) {
                writingDirection = NSParagraphStyle.defaultWritingDirection(forLanguage: nil)
            }
            if (writingDirection == .leftToRight) {
                alignment = .left
            } else if (writingDirection == .rightToLeft) {
                alignment = .right
            }
        }

        return TextEditorParagraphAttributes(alignment: alignment,
                                             lineHeightMultiple: paragraphStyle.lineHeightMultiple,
                                             paragraphSpacing: paragraphStyle.paragraphSpacing)
    }

    static func merge(_ attributes: [TextEditorParagraphAttributes]) -> TextEditorParagraphAttributes {
        func merge<Value: Hashable>(_ key: KeyPath<Self, Value?>, of attributes: [TextEditorParagraphAttributes]) -> Value? {
            let set = Set(attributes.map { $0[keyPath: key] })
            return (set.count == 1) ? set.first! : nil
        }
        return TextEditorParagraphAttributes(alignment: merge(\.alignment, of: attributes),
                                             lineHeightMultiple: merge(\.lineHeightMultiple, of: attributes),
                                             paragraphSpacing: merge(\.paragraphSpacing, of: attributes))
    }

    func apply(to paragraphStyle: NSParagraphStyle) -> NSParagraphStyle {
        guard let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle else {
            return paragraphStyle
        }
        if let alignment = self.alignment {
            mutableStyle.alignment = alignment
        }
        if let lineHeightMultiple = self.lineHeightMultiple {
            mutableStyle.lineHeightMultiple = lineHeightMultiple
        }
        if let paragraphSpacing = self.paragraphSpacing {
            mutableStyle.paragraphSpacing = paragraphSpacing
        }
        return mutableStyle
    }
}

extension NSMutableAttributedString {
    func textEditorParagraphAttributes(in ranges: [NSRange], typingAttributes: [NSAttributedString.Key: Any]) -> TextEditorParagraphAttributes {
        var textEditorParagraphAttributes = [TextEditorParagraphAttributes]()
        for selectionRange in ranges {
            let paragraphRange = (self.string as NSString).paragraphRange(for: selectionRange)
            enumerateAttribute(.paragraphStyle, in: paragraphRange, options: []) { (attribute, _, _) in
                guard let paragraphStyle = attribute as? NSParagraphStyle else {
                    return
                }
                textEditorParagraphAttributes.append(TextEditorParagraphAttributes.with(paragraphStyle))
            }
        }
        return TextEditorParagraphAttributes.merge(textEditorParagraphAttributes)
    }

    func apply(_ textEditorParagraphAttributes: TextEditorParagraphAttributes, to ranges: [NSRange]) {
        for selectionRange in ranges {
            let paragraphRange = (self.string as NSString).paragraphRange(for: selectionRange)
            self.enumerateAttributes(in: paragraphRange, options: []) { (attributes, range, _) in
                var newAttributes = attributes
                let currentStyle = (newAttributes[.paragraphStyle] as? NSParagraphStyle) ?? NSParagraphStyle()
                newAttributes[.paragraphStyle] = textEditorParagraphAttributes.apply(to: currentStyle)
                self.setAttributes(newAttributes, range: range)
            }
        }
    }
}
