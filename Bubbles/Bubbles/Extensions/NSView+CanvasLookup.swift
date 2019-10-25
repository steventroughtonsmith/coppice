//
//  NSView+CanvasLookup.swift
//  Bubbles
//
//  Created by Martin Pilkington on 25/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

extension NSView {
    var canvasView: CanvasView? {
        var view = self.superview
        while (view != nil) {
            if let canvasView = view as? CanvasView {
                return canvasView
            }
            view = view?.superview
        }
        return nil
    }
}
