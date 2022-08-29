//
//  PageContentEditor.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import Foundation

import CoppiceCore

enum PageContentEditorViewMode: Equatable {
    case full
    case canvas
    case focus
}

protocol PageContentEditor: Editor {
    func startEditing(at point: CGPoint)
    func stopEditing()

    func link(at point: CGPoint) -> URL?
    func openLink(at point: CGPoint)
    func highlightLinks(matching pageLink: PageLink)
    func unhighlightLinks()

    func enterFocusMode()
    func exitFocusMode()
    func contentEditorForFocusMode() -> (PageContentEditor & NSViewController)?
}

extension PageContentEditor {
    func link(at point: CGPoint) -> URL? {
        return nil
    }

    func openLink(at point: CGPoint) {}

    func highlightLinks(matching pageLink: PageLink) {}
    func unhighlightLinks() {}

    var pageEditorViewController: PageEditorViewController? {
        var currentParent = self.parentEditor
        while currentParent != nil {
            if let pageEditorViewController = currentParent as? PageEditorViewController {
                return pageEditorViewController
            }
            currentParent = currentParent?.parentEditor
        }
        return nil
    }

    var canvasEditorViewController: CanvasEditorViewController? {
        var currentParent = self.parentEditor
        while currentParent != nil {
            if let canvasEditorViewController = currentParent as? CanvasEditorViewController {
                return canvasEditorViewController
            }
            currentParent = currentParent?.parentEditor
        }
        return nil
    }

    var isInCanvas: Bool {
        return self.pageEditorViewController?.viewModel.viewMode == .canvas
    }

    func enterFocusMode() {
        self.canvasEditorViewController?.enterFocusMode(for: self)
    }

    func exitFocusMode() {
        self.canvasEditorViewController?.exitFocusMode()
    }

    func contentEditorForFocusMode() -> (NSViewController & PageContentEditor)? {
        return nil
    }
}
