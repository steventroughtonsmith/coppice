//
//  MockPageHierarchyBuilder.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 24/10/2022.
//

import Foundation

@testable import CoppiceCore

class MockPageHierarchyBuilder: PageHierarchyBuilder {
    let mockAddPage = MockDetails<CanvasPage, Void>()
    override func add(_ canvasPage: CanvasPage) {
        self.mockAddPage.called(withArguments: canvasPage)
        super.add(canvasPage)
    }

    let mockBuildHierarchy = MockDetails<CoppiceModelController, PageHierarchy>()
    override func buildHierarchy(in modelController: CoppiceModelController) -> PageHierarchy {
        if let hierarchy = self.mockBuildHierarchy.called(withArguments: modelController) {
            return hierarchy
        }
        return super.buildHierarchy(in: modelController)
    }
}
