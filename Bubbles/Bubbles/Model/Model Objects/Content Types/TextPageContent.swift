//
//  TextPageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class TextPageContent: NSObject, PageContent {
    let contentType = PageContentType.text
    @objc dynamic var text: NSAttributedString = NSAttributedString() {
        didSet {
            guard self.text != oldValue else {
                return
            }
            self.didChange(\.text, oldValue: oldValue)
        }
    }

    var maintainAspectRatio: Bool {
        return false
    }
    weak var page: Page?

    init(data: Data? = nil) {
        if let textData = data,
            let text = try? NSAttributedString(data: textData, options: [:], documentAttributes: nil) {
            self.text = text
        }
    }

    var modelFile: ModelFile {
        let textData = try? self.text.data(from: NSMakeRange(0, self.text.length),
                                           documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).rtf" : nil
        return ModelFile(type: self.contentType.rawValue, filename: filename, data: textData, metadata: nil)
    }

    func firstRangeOf(_ searchTerm: String) -> NSRange {
        return (self.text.string as NSString).range(of: searchTerm, options: [.caseInsensitive, .diacriticInsensitive])
    }


    //MARK: - Sizing
    var initialContentSize: CGSize? {
        return self.contentSize(insideBounds: GlobalConstants.maxAutomaticTextSize)
    }

    func sizeToFitContent(currentSize: CGSize) -> CGSize {
        var newContentSize = self.contentSize(insideBounds: CGSize(width: currentSize.width, height: 20000))
        newContentSize.width = currentSize.width
        return newContentSize
    }

    private func contentSize(insideBounds bounds: CGSize) -> CGSize {
        var contentSize = self.text.boundingRect(with: bounds, options: [.usesLineFragmentOrigin]).size
        let insets = GlobalConstants.textEditorInsets

        let adjustedContentSize = contentSize.rounded().plus(width: insets.horizontalInsets, height: insets.verticalInsets)

        //Not sure why but we need to add an additional space to get the size correct
        contentSize.width = max(adjustedContentSize.width + 10, Page.standardSize.width)
        contentSize.height = max(adjustedContentSize.height + 20, Page.standardSize.height)
        return contentSize
    }
}

