//
//  NSTextView+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 26/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSTextView {
    func modifyText(in ranges: [NSRange], _ block: (NSTextStorage) -> Void) {
        guard let textStorage = self.textStorage else {
            return
        }

        guard self.shouldChangeText(inRanges: ranges.map { NSValue(range: $0)}, replacementStrings: nil) else {
            return
        }

        textStorage.beginEditing()
        block(textStorage)
        textStorage.endEditing()
        self.didChangeText()
    }

    var isTextSelected: Bool {
        let ranges = self.selectedRanges
        if (ranges.count > 1) {
            return true
        }
        if ((ranges.first?.rangeValue.length ?? 0) > 0) {
            return true
        }
        return false
    }
}
