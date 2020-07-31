//
//  CanvasTextView.swift
//  Coppice
//
//  Created by Martin Pilkington on 25/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasTextView: NSTextView {
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

    override func becomeFirstResponder() -> Bool {
        self.flashIfTabFocus()
        return super.becomeFirstResponder()
    }


    private func flashIfTabFocus() {
        guard let event = NSApp.currentEvent else {
            return
        }

        //Apparently calling .specialKey on non key events throws an exception
        guard (event.type == .keyUp) || (event.type == .keyDown) else {
            return
        }

        guard (event.specialKey == .tab) || (event.specialKey == .backTab) else {
            return
        }

        let view = NSView(frame: self.bounds)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.controlAccentColor.cgColor
        view.alphaValue = 0.6
        self.addSubview(view)

        NSView.animate(withDuration: 1.0, timingFunction: CAMediaTimingFunction.init(name: .easeOut), animations: {
            view.alphaValue = 0
        }, completion: {
            view.removeFromSuperview()
        })
    }
}
