//
//  PageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

enum PageContentType: String {
    case empty
    case text
    case image

    func createContent(data: Data? = nil) -> PageContent {
        switch self {
        case .empty:
            return EmptyPageContent()
        case .text:
            return TextPageContent(data: data)
        case .image:
            return ImagePageContent(data: data)
        }
    }
}

protocol PageContent: class {
    var contentType: PageContentType { get }
    var contentSize: CGSize? { get }
    var page: Page? { get set }
    var modelFile: ModelFile { get }
}

class EmptyPageContent: NSObject, PageContent {
    let contentType = PageContentType.empty
    var contentSize: CGSize? {
        return nil
    }
    weak var page: Page?

    var modelFile: ModelFile {
        return ModelFile(type: self.contentType.rawValue, filename: nil, data: nil)
    }
}

class TextPageContent: NSObject, PageContent {
    let contentType = PageContentType.text
    @objc dynamic var text: NSAttributedString = NSAttributedString()
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
        return ModelFile(type: self.contentType.rawValue, filename: filename, data: textData)
    }
}

class ImagePageContent: NSObject, PageContent {
    let contentType = PageContentType.image
    @objc dynamic var image: NSImage? {
        didSet {
            if oldValue == nil && self.image != nil {
                self.page?.updatePageSizes()
            }
        }
    }
    var contentSize: CGSize? {
        return self.image?.size
    }
    weak var page: Page?

    init(data: Data? = nil) {
        if let imageData = data, let image = NSImage(data: imageData) {
            self.image = image
        }
    }

    var modelFile: ModelFile {
        let imageData = self.image?.pngData()
        let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).png" : nil
        return ModelFile(type: self.contentType.rawValue, filename: filename, data: imageData)
    }
}
