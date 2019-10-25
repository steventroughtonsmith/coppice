//
//  CanvasTextView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 25/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasTextView: NSTextView {

    

//    override func mouseEntered(with event: NSEvent) {
//        print("entered")
//    }
//
//    override func mouseExited(with event: NSEvent) {
//    }

    override func mouseMoved(with event: NSEvent) {
        guard let canvasView = self.canvasView else {
            super.mouseMoved(with: event)
            return
        }
        let location = canvasView.convert(event.locationInWindow, from: nil)
        let hitView = canvasView.hitTest(location)
        if (hitView == self) && (canvasView.draggingCursor == nil) {
            super.mouseMoved(with: event)
        }
    }
}
