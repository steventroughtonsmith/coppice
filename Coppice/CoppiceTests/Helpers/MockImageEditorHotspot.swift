//
//  MockImageEditorHotspot.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 25/02/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit

@testable import Coppice
@testable import CoppiceCore

class MockImageEditorHotspot: ImageEditorHotspot {
    var originOffset: CGPoint = .zero

    var url: URL?

    func hotspotPath(forScale scale: CGFloat) -> NSBezierPath {
        fatalError()
    }

    func editingBoundsPaths(forScale scale: CGFloat) -> [(path: NSBezierPath, phase: CGFloat)] {
        fatalError()
    }

    func editingHandleRects(forScale scale: CGFloat) -> [CGRect] {
        fatalError()
    }

    var mode: ImageEditorHotspotMode = .creating

    var imageHotspot: ImageHotspot?

    var isSelected: Bool = false
    var isHighlighted: Bool = false
    var isClicked: Bool = false

    weak var layoutEngine: ImageEditorHotspotLayoutEngine?

    let hitTestMock = MockDetails<CGPoint, Bool>()
    func hitTest(at point: CGPoint) -> Bool {
        return self.hitTestMock.called(withArguments: point) ?? false
    }

    let downEventMock = MockDetails<(CGPoint, LayoutEventModifiers, Int), Void>()
    func downEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.downEventMock.called(withArguments: (point, modifiers, eventCount))
    }

    let draggedEventMock = MockDetails<(CGPoint, LayoutEventModifiers, Int), Void>()
    func draggedEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) {
        self.draggedEventMock.called(withArguments: (point, modifiers, eventCount))
    }

    let upEventMock = MockDetails<(CGPoint, LayoutEventModifiers, Int), Bool>()
    func upEvent(at point: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int) -> Bool {
        return self.upEventMock.called(withArguments: (point, modifiers, eventCount)) ?? false
    }

    let movedEventMock = MockDetails<CGPoint, Void>()
    func movedEvent(at point: CGPoint) {
        self.movedEventMock.called(withArguments: point)
    }
}
