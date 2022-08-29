//
//  MockLayoutEnginePageView.swift
//  CoppiceCoreTests
//
//  Created by Martin Pilkington on 10/01/2022.
//

import CoppiceCore
import Foundation

class MockLayoutEnginePageView: LayoutEnginePageView {
    let startEditingMock = MockDetails<CGPoint, Void>()
    func startEditing(atContentPoint point: CGPoint) {
        self.startEditingMock.called(withArguments: point)
    }

    let stopEditingMock = MockDetails<Void, Void>()
    func stopEditing() {
        self.stopEditingMock.called()
    }

    let isLinkMock = MockDetails<CGPoint, Bool>()
    func link(atContentPoint point: CGPoint) -> Bool {
        return self.isLinkMock.called(withArguments: point) ?? false
    }

    let openLinkMock = MockDetails<CGPoint, Void>()
    func openLink(atContentPoint point: CGPoint) {
        self.openLinkMock.called(withArguments: point)
    }
}
