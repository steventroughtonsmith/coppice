//
//  CanvasLinksAccessibilityRotor.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/11/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit

import CoppiceCore

class CanvasLinksAccessibilityRotor: CanvasAccessibilityRotor {
    let canvas: Canvas
    init(canvas: Canvas, canvasEditor: CanvasEditorViewController) {
        self.canvas = canvas
        super.init(canvasEditor: canvasEditor)
    }

    override var label: String {
        return "Links on Canvas"
    }

    private func canvasLink(after: CanvasLink?) -> CanvasLink? {
        let sortedLinks = self.canvas.links.sorted { ($0.sourcePage?.displayTitle ?? "") < ($1.sourcePage?.displayTitle ?? "") }
        guard
            let after,
            let pageIndex = sortedLinks.firstIndex(of: after)
        else {
            return sortedLinks.first
        }
        let nextIndex = sortedLinks.index(after: pageIndex)
        guard nextIndex != sortedLinks.endIndex else {
            return nil
        }

        return sortedLinks[nextIndex]
    }

    private func canvasLink(before: CanvasLink?) -> CanvasLink? {
        let sortedLinks = self.canvas.links.sorted { ($0.sourcePage?.displayTitle ?? "") < ($1.sourcePage?.displayTitle ?? "") }
        guard
            let before,
            let pageIndex = sortedLinks.firstIndex(of: before)
        else {
            return sortedLinks.first
        }

        let previousIndex = sortedLinks.index(before: pageIndex)
        guard previousIndex >= sortedLinks.startIndex else {
            return nil
        }

        return sortedLinks[previousIndex]
    }

    override func rotor(_ rotor: NSAccessibilityCustomRotor, resultFor searchParameters: NSAccessibilityCustomRotor.SearchParameters) -> NSAccessibilityCustomRotor.ItemResult? {
        let currentLink = (searchParameters.currentItem?.targetElement as? CanvasEditorItem)?.representedObject as? CanvasLink

        let getNext = (searchParameters.searchDirection == .next)
        guard
            let canvasLink = (getNext ? self.canvasLink(after: currentLink) : self.canvasLink(before: currentLink)),
            let accessibilityElement = self.canvasEditor?.arrowView(for: canvasLink)
        else {
            return nil
        }

        return NSAccessibilityCustomRotor.ItemResult(targetElement: accessibilityElement)
    }
}
