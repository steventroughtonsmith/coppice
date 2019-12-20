//
//  MockPageContent.swift
//  BubblesTests
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
@testable import Bubbles

class MockPageContent: PageContent {
    var contentType: PageContentType {
        return .empty
    }

    var contentSize: CGSize?

    var page: Page?

    var modelFile: ModelFile {
        return ModelFile(type: self.contentType.rawValue, filename: nil, data: nil, metadata: nil)
    }


    var isMatchReturn = false
    func isMatchForSearch(_ searchTerm: String?) -> Bool {
        return self.isMatchReturn
    }
}
