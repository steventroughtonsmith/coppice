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
            self.didChange(\.text, oldValue: oldValue)
        }
    }
    var contentSize: CGSize? {
        return nil
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

    func isMatchForSearch(_ searchTerm: String?) -> Bool {
        guard let term = searchTerm, term.count > 0 else {
            return true
        }
        return self.text.string.localizedCaseInsensitiveContains(term)
    }
}

