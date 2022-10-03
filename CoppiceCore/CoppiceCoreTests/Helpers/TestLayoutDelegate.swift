//
//  TestLayoutDelegate.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

@testable import CoppiceCore
import Foundation

class TestLayoutDelegate: CanvasLayoutEngineDelegate {
    func reordered(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {}

    var movedPages: [LayoutEnginePage]?
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        self.movedPages = pages
    }

    var removePages: [LayoutEngineItem]?
    func remove(items: [LayoutEngineItem], from layout: CanvasLayoutEngine) {
        self.removePages = items
    }

    func finishLinking(withDestination: LayoutEnginePage?, in layout: CanvasLayoutEngine) {

    }
}
