//
//  CanvasPage.swift
//  Bubbles
//
//  Created by Martin Pilkington on 22/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasPage: NSObject, ModelObject {
    var id = UUID()
    weak var modelController: ModelController?

    weak var page: Page?
    weak var canvas: Canvas?
    var position: CGPoint = .zero
    var size: CGSize = .zero
    weak var parent: CanvasPage?
    var children = Set<CanvasPage>()
}
