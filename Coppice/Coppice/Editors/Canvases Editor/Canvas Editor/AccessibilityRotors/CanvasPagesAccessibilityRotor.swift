//
//  CanvasPagesAccessibilityRotor.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/11/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit

import CoppiceCore

class CanvasPagesAccessibilityRotor: CanvasAccessibilityRotor {
    let canvas: Canvas
    init(canvas: Canvas, canvasEditor: CanvasEditorViewController) {
        self.canvas = canvas
        super.init(canvasEditor: canvasEditor)
    }

    override var label: String {
        return "Pages on Canvas"
    }

    private func canvasPage(after: CanvasPage?) -> CanvasPage? {
        let sortedPages = self.canvas.pages.sorted { $0.displayTitle < $1.displayTitle }
        guard
            let after,
            let pageIndex = sortedPages.firstIndex(of: after)
        else {
            return sortedPages.first
        }
        let nextIndex = sortedPages.index(after: pageIndex)
        guard nextIndex != sortedPages.endIndex else {
            return nil
        }

        return sortedPages[nextIndex]
    }

    private func canvasPage(before: CanvasPage?) -> CanvasPage? {
        let sortedPages = self.canvas.pages.sorted { $0.displayTitle < $1.displayTitle }
        guard
            let before,
            let pageIndex = sortedPages.firstIndex(of: before)
        else {
            return sortedPages.first
        }
        let previousIndex = sortedPages.index(before: pageIndex)
        guard previousIndex >= sortedPages.startIndex else {
            return nil
        }

        return sortedPages[previousIndex]
    }

    override func rotor(_ rotor: NSAccessibilityCustomRotor, resultFor searchParameters: NSAccessibilityCustomRotor.SearchParameters) -> NSAccessibilityCustomRotor.ItemResult? {
        let currentPage = (searchParameters.currentItem?.targetElement as? CanvasEditorItem)?.representedObject as? CanvasPage

        let getNext = (searchParameters.searchDirection == .next)
        guard
            let canvasPage = (getNext ? self.canvasPage(after: currentPage) : self.canvasPage(before: currentPage)),
            let accessibilityElement = self.canvasEditor?.pageViewController(for: canvasPage)?.view
        else {
            return nil
        }

        return NSAccessibilityCustomRotor.ItemResult(targetElement: accessibilityElement)
    }
}
