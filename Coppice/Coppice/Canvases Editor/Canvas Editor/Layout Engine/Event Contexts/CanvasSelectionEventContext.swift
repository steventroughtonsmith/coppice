//
//  CanvasSelectionEventContext.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasSelectionEventContext: CanvasMouseEventContext {
    var startPoint: CGPoint = .zero

    private var originalSelection = [LayoutEnginePage]()

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        self.startPoint = location
        if !modifiers.contains(.shift) {
            layout.deselectAll()
        }
        self.originalSelection = layout.selectedPages
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        guard location != self.startPoint else {
            layout.selectionRect = nil
            return
        }

        let selectionRect = CGRect(x: min(self.startPoint.x, location.x),
                                   y: min(self.startPoint.y, location.y),
                                   width: abs(location.x - self.startPoint.x),
                                   height: abs(location.y - self.startPoint.y))

        layout.selectionRect = selectionRect

        var pagesToSelect = layout.pages(inCanvasRect: selectionRect)
        if (modifiers.contains(.shift)) {
            for page in self.originalSelection {
                guard let index = pagesToSelect.firstIndex(of: page) else {
                    pagesToSelect.append(page)
                    continue
                }
                pagesToSelect.remove(at: index)
            }
        }

        layout.select(pagesToSelect, extendingSelection: false)
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: LayoutEngine) {
        if (location == self.startPoint) {
            layout.deselectAll()
        }
        layout.selectionRect = nil
    }
}
