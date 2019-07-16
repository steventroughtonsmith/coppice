//
//  DebugCanvasEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DebugCanvasEditorViewModel: NSObject {
    let canvas: Canvas
    init(canvas: Canvas) {
        self.canvas = canvas
        super.init()
    }
}
