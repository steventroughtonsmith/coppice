//
//  CanvasSelectionEventContext.swift
//  Canvas Final
//
//  Created by Martin Pilkington on 11/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasSelectionEventContext: CanvasEventContext {
    var startPoint: CGPoint = .zero
    let originalSelection: [LayoutEnginePage]

    init(originalSelection: [LayoutEnginePage]) {
        self.originalSelection = originalSelection
    }

    func downEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        self.startPoint = location
    }

    func draggedEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        guard location != self.startPoint else {
            layout.selectionRect = nil
            return
        }

        let selectionRect = CGRect(x: min(self.startPoint.x, location.x),
                                   y: min(self.startPoint.y, location.y),
                                   width: abs(location.x - self.startPoint.x),
                                   height: abs(location.y - self.startPoint.y))

        layout.selectionRect = selectionRect

        let pagesInRect = layout.pages(inCanvasRect: selectionRect)
        if (modifiers.contains(.shift)) {
            var pagesToReselect = self.originalSelection
            for page in pagesInRect {
                let wasOriginallySelected = self.originalSelection.contains(page)
                page.selected = !wasOriginallySelected
                if let index = pagesToReselect.firstIndex(of: page) {
                    pagesToReselect.remove(at: index)
                }
            }
            pagesToReselect.forEach { $0.selected = true }
        }
        else {
            for page in layout.selectedPages {
                if !pagesInRect.contains(page) {
                    page.selected = false
                }
            }
            pagesInRect.forEach { $0.selected = true }
        }
    }

    func upEvent(at location: CGPoint, modifiers: LayoutEventModifiers, eventCount: Int, in layout: CanvasLayoutEngine) {
        if (location == self.startPoint) {
            layout.deselectAll()
        }
        layout.selectionRect = nil
    }
}
