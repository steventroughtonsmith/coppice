//
//  CanvasView.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasView: NSView {
    override var isFlipped: Bool {
        return true
    }

    var layoutEngine: CanvasLayoutEngine?

    override func mouseDown(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        self.layoutEngine?.downEvent(at: point, modifiers: event.layoutEventModifiers)
    }

    override func mouseDragged(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        self.layoutEngine?.draggedEvent(at: point, modifiers: event.layoutEventModifiers)
    }

    override func mouseUp(with event: NSEvent) {
        let point = self.convert(event.locationInWindow, from: nil)
        self.layoutEngine?.upEvent(at: point, modifiers: event.layoutEventModifiers)
    }


    //MARK: - Selection Rect
    var selectionRect: CGRect? {
        didSet {
            self.updateSelectionRect()
        }
    }

    private var selectionView: NSView?

    private func updateSelectionRect() {
        guard let selectionRect = self.selectionRect else {
            self.selectionView?.removeFromSuperview()
            self.selectionView = nil
            return
        }

        if self.selectionView == nil {
            let selectionView = self.createSelectionView()
            self.addSubview(selectionView)
            self.selectionView = selectionView
        }

        self.selectionView?.frame = selectionRect
    }

    private func createSelectionView() -> NSView {
        let selectionView = NSView()
        selectionView.wantsLayer = true
        selectionView.layer?.backgroundColor = NSColor(white: 0, alpha: 0.3).cgColor
        selectionView.layer?.borderColor = NSColor(white: 0, alpha: 0.5).cgColor
        selectionView.layer?.borderWidth = 1
        selectionView.identifier = NSUserInterfaceItemIdentifier("SelectionView")
        return selectionView
    }


    override func draw(_ dirtyRect: NSRect) {
        NSColor(white: 0.85, alpha: 1).set()
        self.bounds.fill()
    }
}


extension NSEvent {
    var layoutEventModifiers: LayoutEventModifiers {
        var modifiers = [LayoutEventModifiers]()
        if self.modifierFlags.contains(.shift) {
            modifiers.append(.shift)
        }
        if self.modifierFlags.contains(.command) {
            modifiers.append(.command)
        }
        if self.modifierFlags.contains(.option) {
            modifiers.append(.option)
        }
        if self.modifierFlags.contains(.control) {
            modifiers.append(.control)
        }
        return LayoutEventModifiers(modifiers)
    }
}
