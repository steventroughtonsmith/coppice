//
//  PageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

enum PageContentType {
    case empty
    case text
    case image

    func createContent() -> PageContent {
        switch self {
        case .empty:
            return EmptyPageContent()
        case .text:
            return TextPageContent()
        case .image:
            return ImagePageContent()
        }
    }
}

protocol PageContent: class {
    var contentType: PageContentType { get }
    var contentSize: CGSize? { get }
    var page: Page? { get set }
}

class EmptyPageContent: PageContent {
    let contentType = PageContentType.empty
    var contentSize: CGSize? {
        return nil
    }
    weak var page: Page?
}

class TextPageContent: PageContent {
    let contentType = PageContentType.text
    var text: NSAttributedString = NSAttributedString()
    var contentSize: CGSize? {
        return nil
    }
    weak var page: Page?
}

class ImagePageContent: PageContent {
    let contentType = PageContentType.image
    var image: NSImage?
    var contentSize: CGSize? {
        return self.image?.size
    }
    weak var page: Page?
}
