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
    var contentSize: CGSize? {
        var contentSize = self.text.boundingRect(with: NSSize(width: Page.standardSize.width * 1.5, height: Page.standardSize.height * 3), options: [.usesLineFragmentOrigin]).size
        let insets = GlobalConstants.textEditorInsets
        //Not sure why but we need to add an additional 10 pt to get the size correct
        contentSize.width = max(contentSize.width.rounded(.up) + insets.left + insets.right + 10, Page.standardSize.width)
        contentSize.height = max(contentSize.height.rounded(.up) + insets.top + insets.bottom + 10, Page.standardSize.height)
        return contentSize
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
}

