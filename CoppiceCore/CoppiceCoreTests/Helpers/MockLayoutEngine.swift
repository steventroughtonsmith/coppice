//
//  MockLayoutEngine.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import Foundation

class MockLayoutEngine: LayoutEngine {
    var editable: Bool = true

    var selectedItems: [LayoutEngineItem] = [] {
        didSet {
            self.selectedItems.forEach { $0.selected = true }
        }
    }

    var pageUnderMouse: LayoutEnginePage?
    var cursorPage: LayoutEnginePage?
    var pages: [LayoutEnginePage] = []

    var canvasSize: CGSize = .zero
    var selectionRect: CGRect?

    let pageWithIDMock = MockDetails<UUID, LayoutEnginePage>()
    func page(withID id: UUID) -> LayoutEnginePage? {
        return self.pageWithIDMock.called(withArguments: id)
    }

    let selectPagesMock = MockDetails<([LayoutEngineItem], Bool), Void>()
    func select(_ items: [LayoutEngineItem], extendingSelection: Bool) {
        self.selectPagesMock.called(withArguments: (items, extendingSelection))
    }

    let deselectPagesMock = MockDetails<[LayoutEngineItem], Void>()
    func deselect(_ items: [LayoutEngineItem]) {
        self.deselectPagesMock.called(withArguments: items)
    }

    let deselectAllMock = MockDetails<Void, Void>()
    func deselectAll() {
        self.deselectAllMock.called()
    }

    let pagesInCanvasRectMock = MockDetails<CGRect, [LayoutEngineItem]>()
    func items(inCanvasRect rect: CGRect) -> [LayoutEngineItem] {
        return self.pagesInCanvasRectMock.called(withArguments: rect) ?? []
    }

    let pageAtCanvasPointMock = MockDetails<CGPoint, LayoutEngineItem?>()
    func item(atCanvasPoint point: CGPoint) -> LayoutEngineItem? {
        return self.pageAtCanvasPointMock.called(withArguments: point) ?? nil
    }

    let movePageToFrontMock = MockDetails<LayoutEnginePage, Void>()
    func movePageToFront(_ page: LayoutEnginePage) {
        self.movePageToFrontMock.called(withArguments: page)
    }

    let modifiedPagesMock = MockDetails<[LayoutEngineItem], Void>()
    func modified(_ items: [LayoutEngineItem]) {
        self.modifiedPagesMock.called(withArguments: items)
    }

    let finishedModifyingMock = MockDetails<[LayoutEngineItem], Void>()
    func finishedModifying(_ items: [LayoutEngineItem]) {
        self.finishedModifyingMock.called(withArguments: items)
    }

    let tellDelegateToRemoveMock = MockDetails<[LayoutEngineItem], Void>()
    func tellDelegateToRemove(_ items: [LayoutEngineItem]) {
        self.tellDelegateToRemoveMock.called(withArguments: items)
    }

    let startEditingMock = MockDetails<(LayoutEnginePage, CGPoint), Void>()
    func startEditing(_ page: LayoutEnginePage, atContentPoint point: CGPoint) {
        self.startEditingMock.called(withArguments: (page, point))
    }

    let stopEditingPagesMock = MockDetails<Void, Void>()
    func stopEditingPages() {
        self.stopEditingPagesMock.called()
    }


    var links: [LayoutEngineLink] = []
    let addLinksMock = MockDetails<[LayoutEngineLink], Void>()
    func add(_ links: [LayoutEngineLink]) {
        self.addLinksMock.called(withArguments: links)
    }

    let removeLinksMock = MockDetails<[LayoutEngineLink], Void>()
    func remove(_ links: [LayoutEngineLink]) {
        self.removeLinksMock.called(withArguments: links)
    }

    var isLinking: Bool = false
    let startLinkingMock = MockDetails<Void, Void>()
    func startLinking() {
        self.startLinkingMock.called()
    }

    let finishLinkingWithDestinationMock = MockDetails<LayoutEnginePage?, Void>()
    func finishLinking(withDestination page: LayoutEnginePage?) {
        self.finishLinkingWithDestinationMock.called(withArguments: page)
    }

    let linksChangedMock = MockDetails<Void, Void>()
    func linksChanged() {
        self.linksChangedMock.called()
    }
}
