//
//  PageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

enum PageContentType {
    case text

    func createContent() -> PageContent {
        switch self {
        case .text:
            return TextPageContent()
        }
    }
}

protocol PageContent: class {
    var contentType: PageContentType { get }
}

class TextPageContent: PageContent {
    let contentType = PageContentType.text
    var text: NSAttributedString = NSAttributedString()
}
