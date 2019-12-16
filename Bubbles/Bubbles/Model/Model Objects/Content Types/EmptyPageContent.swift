//
//  EmptyPageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

class EmptyPageContent: NSObject, PageContent {
    let contentType = PageContentType.empty
    var contentSize: CGSize? {
        return nil
    }
    weak var page: Page?

    var modelFile: ModelFile {
        return ModelFile(type: self.contentType.rawValue, filename: nil, data: nil, metadata: nil)
    }
}

