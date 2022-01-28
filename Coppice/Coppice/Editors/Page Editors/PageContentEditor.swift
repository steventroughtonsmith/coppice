//
//  PageContentEditor.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Foundation

protocol PageContentEditor: Editor {
    func startEditing(at point: CGPoint)
    func stopEditing()
    func isLink(at point: CGPoint) -> Bool
    func openLink(at point: CGPoint)
}

extension PageContentEditor {
    func isLink(at point: CGPoint) -> Bool {
        return false
    }

    func openLink(at point: CGPoint) {}

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

    var isInCanvas: Bool {
        return self.pageEditorViewController?.viewModel.isInCanvas ?? false
    }
}
