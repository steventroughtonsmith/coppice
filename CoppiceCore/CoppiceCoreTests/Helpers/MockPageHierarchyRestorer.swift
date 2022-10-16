//
//  MockPageHierarchyRestorer.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 10/10/2022.
//

import Foundation
@testable import CoppiceCore

class MockPageHierarchyRestorer: PageHierarchyRestorer {
    var mockRestoreHierarchy = MockDetails<(PageHierarchy, CanvasPage, PageLink), [CanvasPage]>()
    override func restore(_ pageHierarchy: PageHierarchy, from source: CanvasPage, for link: PageLink) -> [CanvasPage] {
        if let canvasPages = self.mockRestoreHierarchy.called(withArguments: (pageHierarchy, source, link)) {
            return canvasPages
        }
        return super.restore(pageHierarchy, from: source, for: link)
    }
}
