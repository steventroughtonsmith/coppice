//
//  TestLayoutDelegate.swift
//  CoppiceTests
//
//  Created by Martin Pilkington on 02/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation
@testable import Coppice
@testable import CoppiceCore

class TestLayoutDelegate: CanvasLayoutEngineDelegate {
    func reordered(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
    }

    var movedPages: [LayoutEnginePage]?
    func moved(pages: [LayoutEnginePage], in layout: CanvasLayoutEngine) {
        self.movedPages = pages
    }

    var removePages: [LayoutEnginePage]?
    func remove(pages: [LayoutEnginePage], from layout: CanvasLayoutEngine) {
        self.removePages = pages
    }
}
