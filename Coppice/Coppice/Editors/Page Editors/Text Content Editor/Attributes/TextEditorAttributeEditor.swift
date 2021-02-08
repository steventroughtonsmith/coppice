//
//  TextEditorAttributeEditor.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/01/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import AppKit
import Combine

class TextEditorAttributeEditor {
    var textView: CanvasTextView? {
        didSet {
            self.update()
        }
    }

    func update() {
        self.updateSelectedFontAttributes()
        self.updateSelectedParagraphAttributes()
        self.updateListTypes()
    }


    //MARK: - Font Attributes
    @Published var selectedFontAttributes: TextEditorFontAttributes?


    /// Update the current selection in the text editor with the supplied font attributes
    /// - Parameter editorAttributes: The attributes to apply to the selection, or set at the typing attributes
    func updateSelection(with editorAttributes: TextEditorFontAttributes) {
        guard let textView = self.textView else {
            return
        }

        //If nothing is selected then the user wants to change what they'll be typing next
        guard textView.isTextSelected else {
            textView.typingAttributes = editorAttributes.apply(to: textView.typingAttributes)
            self.updateSelectedFontAttributes()
            return
        }

        //Otherwise the user wants to update the attributes of the current selection
        let ranges = textView.selectedRanges.compactMap { $0.rangeValue }
        textView.modifyText(in: ranges) { (textStorage) in
            textStorage.apply(editorAttributes, to: ranges)
        }
        self.updateSelectedFontAttributes()
    }

    private func updateSelectedFontAttributes() {
        guard let textView = self.textView else {
            return
        }

        var baseAttributes = textView.typingAttributes
        baseAttributes.merge(textView.selectedTextAttributes) { (key1, _) in key1 }

        //If nothing is selected then we just want what is at the cursor point, which will be the typing attributes
        guard textView.isTextSelected else {
            self.selectedFontAttributes = TextEditorFontAttributes.withAttributes(baseAttributes)
            return
        }

        guard let textStorage = textView.textStorage else {
            return
        }
        //Otherwise lets look at all selection (which could be non-continguous)
        let ranges = textView.selectedRanges.compactMap { $0.rangeValue }.filter { ($0.lowerBound < textStorage.length) && ($0.upperBound <= textStorage.length) }
        self.selectedFontAttributes = textStorage.textEditorFontAttributes(in: ranges, typingAttributes: baseAttributes)
    }


    //MARK: - Paragraph Attributes
    @Published var selectedParagraphAttributes: TextEditorParagraphAttributes?

    /// Update the paragraph attributes of any paragraphs in the text view's selection
    /// - Parameter paragraphAttributes: The attributes to apply to the selection
    func updateSelection(with paragraphAttributes: TextEditorParagraphAttributes) {
        guard let textView = self.textView else {
            return
        }

        //Regardless of selection we always update the full paragraph
        let ranges = textView.selectedRanges.compactMap { $0.rangeValue }
        textView.modifyText(in: ranges) { (textStorage) in
            textStorage.apply(paragraphAttributes, to: ranges)
        }
        self.updateSelectedParagraphAttributes()
    }

    private func updateSelectedParagraphAttributes() {
        guard
            let textView = self.textView,
            let textStorage = textView.textStorage
        else {
            return
        }

        var baseAttributes = textView.typingAttributes
        baseAttributes.merge(textView.selectedTextAttributes) { (key1, _) in key1 }

        let ranges = textView.selectedRanges.compactMap { $0.rangeValue }.filter { ($0.lowerBound <= textStorage.length) && ($0.upperBound <= textStorage.length) }
        self.selectedParagraphAttributes = textStorage.textEditorParagraphAttributes(in: ranges, typingAttributes: baseAttributes)
    }


    //MARK: - Lists
    @Published var selectedListTypes: [NSTextList]?

    func updateSelection(withListType listType: NSTextList?) {
        guard let textView = self.textView else {
            return
        }

        let (range, level) = ListCalculator().calculateListRangeAndLevel(in: textView)
        guard let editingRange = range else {
            return
        }

        var selectedLocation = textView.selectedRange().location

        textView.modifyText(in: [editingRange]) { (textStorage) in
            //The end of the text view is a special case, where we just append
            guard editingRange.location < textStorage.length else {
                if let list = listType {
                    self.add(list, toEndOf: textStorage)
                }
                return
            }

            //We want an copy of the old string as we need it to calculate the ranges of the old list markers to replace
            let oldString = textStorage.copy() as! NSAttributedString
            var replacements: [(NSRange, String, NSParagraphStyle)] = []
            textStorage.enumerateAttribute(.paragraphStyle, in: editingRange, options: []) { (attribute, effectiveRange, _) in
                guard
                    let oldParagraphStyle = attribute as? NSParagraphStyle,
                    let newParagraphStyle = oldParagraphStyle.mutableCopy() as? NSMutableParagraphStyle
                else {
                    return
                }

                var textLists = newParagraphStyle.textLists
                //If we're setting a list then we want to replace the list at the desired level
                if let listType = listType {
                    if (textLists.count > level) {
                        textLists[level] = listType
                    } else {
                        textLists = [listType]
                    }
                } else {
                    //If we have no list then we're removing all lists
                    textLists = []
                }
                newParagraphStyle.textLists = textLists

                //Update the paragraph style on the text storage
                textStorage.removeAttribute(.paragraphStyle, range: effectiveRange)
                textStorage.addAttribute(.paragraphStyle, value: newParagraphStyle, range: effectiveRange)

                //Enumerate the lines of the old attribute string to find our replacement ranges
                (oldString.string as NSString).enumerateSubstrings(in: effectiveRange, options: .byLines) { (substring, substringRange, effectiveRange, _) in
                    var existingRange = NSRange(location: substringRange.location, length: 0)
                    //If we had an old list then we want to calculate the marker so we can get its range for replacement
                    if let oldList = oldParagraphStyle.textLists.last {
                        var itemNumber = oldString.itemNumber(in: oldList, at: substringRange.location)
                        //We need to manually handle the startingItemNumber as itemNumber(in:at:) doesn't (despite being giving the list)
                        if (oldList.startingItemNumber > 1) {
                            itemNumber = oldList.startingItemNumber + (itemNumber - 1)
                        }
                        //We just need the length of the marker as the location is always the start of the line
                        //We also add 2 as we always have a tab before and after
                        existingRange.length = oldList.marker(forItemNumber: itemNumber).count + 2
                    }

                    //Add the range and text to replace. We don't actually replace here as we don't want to mess up enumerateAttributes()
                    if let list = textLists.last {
                        replacements.append((existingRange, "\t\(list.marker(forItemNumber: textStorage.itemNumber(in: list, at: substringRange.location)))\t", newParagraphStyle))
                    } else {
                        replacements.append((existingRange, "", newParagraphStyle))
                    }
                }
            }

            //Going from back to front (so the ranges remain valid) apply all the list replacements
            for (range, string, paragraphStyle) in replacements.reversed() {
                textStorage.replaceCharacters(in: range, with: string)
                //If we're adding a list then we need to make absolutely sure what is added has the paragraph style
                //This is especially true for the earliest range we're adding as it may use the attributes of the text before
                if (range.length == 0) {
                    let addedRange = NSRange(location: range.location, length: string.count)
                    textStorage.removeAttribute(.paragraphStyle, range: addedRange)
                    textStorage.addAttribute(.paragraphStyle, value: paragraphStyle, range: addedRange)
                }
                //We also want to update the selectionLocation so the cursor goes back to the start of the location, which may have shifted due to other list items changing above
                if (range.location < selectedLocation) {
                    selectedLocation += (string.count - range.length)
                }
            }
        }

        textView.selectedRanges = [NSValue(range: NSRange(location: selectedLocation, length: 0))]

        self.updateListTypes()
    }

    private func add(_ list: NSTextList, toEndOf textStorage: NSTextStorage) {
        guard let textView = self.textView else {
            return
        }

        let string = "\t\(list.marker(forItemNumber: 0))\t"
        var attributes = textView.typingAttributes
        let paragraphStyle = (attributes[.paragraphStyle] as? NSParagraphStyle) ?? textView.defaultParagraphStyle ?? NSParagraphStyle()
        if let mutableStyle = paragraphStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutableStyle.textLists = [list]
            attributes[.paragraphStyle] = mutableStyle.copy()
        }

        textStorage.append(NSAttributedString(string: string, attributes: attributes))
    }

    private func updateListTypes() {
        guard
            let textView = self.textView,
            let textStorage = textView.textStorage
        else {
            return
        }

        //Ensure we have valid ranges
        guard
            textStorage.length > NSMaxRange(textView.selectedRange()),
            let ranges = textView.rangesForUserParagraphAttributeChange
        else {
            self.selectedListTypes = []
            return
        }

        //Fetch all the list types in the selection
        var selectionListTypes = [[NSTextList]]()
        for range in ranges.map(\.rangeValue) {
            guard range.location < textStorage.length else {
                continue
            }

            textStorage.enumerateAttribute(.paragraphStyle, in: range, options: []) { (attribute, range, stop) in
                guard let paragraphStyle = attribute as? NSParagraphStyle else {
                    return
                }
                selectionListTypes.append(paragraphStyle.textLists)
            }
        }

        //Calculate if the list types match, or if we have a multiple selection situation
        var currentListTypes: [NSTextList]? = nil
        for types in selectionListTypes {
            if (currentListTypes == nil) {
                currentListTypes = types
            } else if (currentListTypes != types) {
                currentListTypes = nil
                break
            }
        }

        self.selectedListTypes = currentListTypes
    }

    /// Show the build in advanced list editor
    func showCustomListPanel() {
        self.textView?.orderFrontListPanel(self)
    }
}

extension TextEditorAttributeEditor {
    private class ListCalculator {
        private var level: Int? = nil
        private var editingRange: NSRange? = nil


        /// Calculate the total range of lists to edit in a textView, and (in the case of nested lists) the level of list we'll change
        /// - Parameter textView: The text view to calculate on
        /// - Returns: A tuple with the range (or nil if invalid), and the level of list (which should match the index to edit in all NSParagraphStyle.textLists in the range)
        func calculateListRangeAndLevel(in textView: CanvasTextView) -> (NSRange?, Int) {
            guard let textStorage = textView.textStorage else {
                return (nil, 0)
            }

            let selectedRanges = textView.selectedRanges.compactMap { $0.rangeValue }.filter { ($0.lowerBound <= textStorage.length) && ($0.upperBound <= textStorage.length) }
            //For an empty text view, the editing range is (0,0)
            if textStorage.length == 0, selectedRanges.count == 1, selectedRanges[0] == NSRange(location: 0, length: 0) {
                return (NSRange(location: 0, length: 0), 0)
            }

            for range in selectedRanges {
                guard range.length > 0 else {
                    self.handleZeroLengthRange(range, in: textStorage, defaultStyle: textView.defaultParagraphStyle)
                    continue
                }

                textStorage.enumerateAttribute(.paragraphStyle, in: range, options: []) { (attribute, effectiveRange, _) in
                    guard let paragraphStyle = attribute as? NSParagraphStyle else {
                        return
                    }
                    self.updateLevelAndRange(using: paragraphStyle, effectiveRange: effectiveRange, in: textStorage)
                }
            }
            return (self.editingRange, self.level ?? 0)
        }


        /// Zero length ranges require special treatment, as we can't use NSAttributedString.enumerateAttribute()
        private func handleZeroLengthRange(_ range: NSRange, in textStorage: NSTextStorage, defaultStyle: NSParagraphStyle?) {
            var effectiveRange = NSRange(location: NSNotFound, length: 0)

            var attribute: Any? = defaultStyle
            if (textStorage.length > 0) {
                var actualRange = range
                //If the cursor is at the end of the text view, we have to shift forward when fetching the attribute to avoid an out of bounds exception
                if (actualRange.location == textStorage.length) {
                    actualRange.location = max(actualRange.location - 1, 0)
                }
                attribute = textStorage.attribute(.paragraphStyle, at: actualRange.location, effectiveRange: &effectiveRange)
                //If there are currently no text lists, then the paragraph style will actually cover multiple paragraphs. In this case we only want the current paragraph
                if let attribute = attribute as? NSParagraphStyle {
                    if attribute.textLists.count == 0 {
                        effectiveRange = (textStorage.string as NSString).paragraphRange(for: range)
                    }
                }
            }
            //Perform the update calculation
            if let paragraphStyle = attribute as? NSParagraphStyle {
                self.updateLevelAndRange(using: paragraphStyle, effectiveRange: effectiveRange, in: textStorage)
            }
        }


        /// Actually update the level and range
        private func updateLevelAndRange(using paragraphStyle: NSParagraphStyle, effectiveRange: NSRange, in textStorage: NSTextStorage) {
            var newRange = effectiveRange
            //The level is the index of NSParagraphStyle.textLists we need to edit. This is always the list with the lowest indentation in the selection
            //This should be zero indexed so it maps to the .textLists array
            if let currentLevel = self.level {
                self.level = min(currentLevel, max(paragraphStyle.textLists.count - 1, 0))
            } else {
                self.level = max(paragraphStyle.textLists.count - 1, 0)
            }

            //If we're in a list then we need to get the full range of the list, which may be outside the selection range
            if let list = paragraphStyle.textLists.last {
                let listRange = textStorage.range(of: list, at: effectiveRange.location)
                if (listRange.location != NSNotFound) {
                    newRange = listRange
                }
            } else {
                //If we're outside of a list then we just want the current paragraph
                newRange = (textStorage.string as NSString).paragraphRange(for: effectiveRange)
            }

            //Merge the ranges
            guard let editRange = self.editingRange else {
                self.editingRange = newRange
                return
            }
            self.editingRange = editRange.union(newRange)
        }
    }
}
