//
//  Canvas.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class Canvas: NSObject {
    var id = UUID()
    @objc var title: String = "New Canvas"
    var dateCreated = Date()
    var dateModified = Date()
    var pages = Set<CanvasPage>()
}
