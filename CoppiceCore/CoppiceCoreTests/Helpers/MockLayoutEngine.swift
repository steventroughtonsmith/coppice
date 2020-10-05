//
//  MockLayoutEngine.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
@testable import CoppiceCore

class MockLayoutEngine: LayoutEngine {
    var editable: Bool = true

    var selectedPages: [LayoutEnginePage] = [] {
        didSet {
            self.selectedPages.forEach { $0.selected = true }
        }
    }
    var canvasSize: CGSize = .zero
    var selectionRect: CGRect?

    let selectPagesMock = MockDetails<([LayoutEnginePage], Bool), Void>()
    func select(_ pages: [LayoutEnginePage], extendingSelection: Bool) {
        self.selectPagesMock.called(withArguments: (pages, extendingSelection))
    }

    let deselectPagesMock = MockDetails<[LayoutEnginePage], Void>()
    func deselect(_ pages: [LayoutEnginePage]) {
        self.deselectPagesMock.called(withArguments: pages)
    }

    let deselectAllMock = MockDetails<Void, Void>()
    func deselectAll() {
        self.deselectAllMock.called()
    }

    let pagesInCanvasRectMock = MockDetails<CGRect, [LayoutEnginePage]>()
    func pages(inCanvasRect rect: CGRect) -> [LayoutEnginePage] {
        return self.pagesInCanvasRectMock.called(withArguments: rect) ?? []
    }

    let pageAtCanvasPointMock = MockDetails<CGPoint, LayoutEnginePage?>()
    func page(atCanvasPoint point: CGPoint) -> LayoutEnginePage? {
        return self.pageAtCanvasPointMock.called(withArguments: point) ?? nil
    }

    let movePageToFrontMock = MockDetails<LayoutEnginePage, Void>()
    func movePageToFront(_ page: LayoutEnginePage) {
        self.movePageToFrontMock.called(withArguments: page)
    }

    let modifiedPagesMock = MockDetails<[LayoutEnginePage], Void>()
    func modified(_ pages: [LayoutEnginePage]) {
        self.modifiedPagesMock.called(withArguments: pages)
    }

    let finishedModifyingMock = MockDetails<[LayoutEnginePage], Void>()
    func finishedModifying(_ pages: [LayoutEnginePage]) {
        self.finishedModifyingMock.called(withArguments: pages)
    }

    let tellDelegateToRemoveMock = MockDetails<[LayoutEnginePage], Void>()
    func tellDelegateToRemove(_ pages: [LayoutEnginePage]) {
        self.tellDelegateToRemoveMock.called(withArguments: pages)
    }
}
