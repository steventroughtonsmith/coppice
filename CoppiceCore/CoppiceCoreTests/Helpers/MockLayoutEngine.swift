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

    var canvasSize: CGSize = .zero
    var selectionRect: CGRect?
    var pageUnderMouse: LayoutEnginePage?
    var cursorPage: LayoutEnginePage?

    var pages: [LayoutEnginePage] = []

    let pageWithIDMock = MockDetails<UUID, LayoutEnginePage>()
    func page(withID id: UUID) -> LayoutEnginePage? {
        return self.pageWithIDMock.called(withArguments: id)
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


    let selectItemsMock = MockDetails<([LayoutEngineItem], Bool), Void>()
    func select(_ items: [LayoutEngineItem], extendingSelection: Bool) {
        self.selectItemsMock.called(withArguments: (items, extendingSelection))
    }

    let deselectItemMock = MockDetails<[LayoutEngineItem], Void>()
    func deselect(_ items: [LayoutEngineItem]) {
        self.deselectItemMock.called(withArguments: items)
    }

    let deselectAllMock = MockDetails<Void, Void>()
    func deselectAll() {
        self.deselectAllMock.called()
    }

    let itemsInCanvasRectMock = MockDetails<CGRect, [LayoutEngineItem]>()
    func items(inCanvasRect rect: CGRect) -> [LayoutEngineItem] {
        return self.itemsInCanvasRectMock.called(withArguments: rect) ?? []
    }

    let itemAtCanvasPointMock = MockDetails<CGPoint, LayoutEngineItem?>()
    func item(atCanvasPoint point: CGPoint) -> LayoutEngineItem? {
        return self.itemAtCanvasPointMock.called(withArguments: point) ?? nil
    }


    let modifiedItemsMock = MockDetails<[LayoutEngineItem], Void>()
    func modified(_ items: [LayoutEngineItem]) {
        self.modifiedItemsMock.called(withArguments: items)
    }

    let finishedModifyingMock = MockDetails<[LayoutEngineItem], Void>()
    func finishedModifying(_ items: [LayoutEngineItem]) {
        self.finishedModifyingMock.called(withArguments: items)
    }

    let tellDelegateToRemoveMock = MockDetails<[LayoutEngineItem], Void>()
    func tellDelegateToRemove(_ items: [LayoutEngineItem]) {
        self.tellDelegateToRemoveMock.called(withArguments: items)
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


    let startEditingMock = MockDetails<(LayoutEnginePage, CGPoint), Void>()
    func startEditing(_ page: LayoutEnginePage, atContentPoint point: CGPoint) {
        self.startEditingMock.called(withArguments: (page, point))
    }

    let stopEditingPagesMock = MockDetails<Void, Void>()
    func stopEditingPages() {
        self.stopEditingPagesMock.called()
    }

    let movePageToFrontMock = MockDetails<LayoutEnginePage, Void>()
    func movePageToFront(_ page: LayoutEnginePage) {
        self.movePageToFrontMock.called(withArguments: page)
    }
}
