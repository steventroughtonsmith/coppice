//
//  Editor.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

enum EditorMode: Equatable {
    case editing
    case readOnly
}

protocol Editor: class {
    var inspectors: [Inspector] { get }
    var parentEditor: Editor? { get }
    var childEditors: [Editor] { get }

    func inspectorsDidChange()
    func open(_ link: PageLink)

    var enabled: Bool { get set }
    
    
    /// We don't get safe areas until we've been added to the window, but this can be too late to do some setup without drawing artefacts.
    ///
    /// - Parameter safeAreaInsets: The safe area insets to apply
    func prepareForDisplay(withSafeAreaInsets safeAreaInsets: NSEdgeInsets)
}


extension Editor where Self: NSViewController {
    var parentEditor: Editor? {
        var parent = self.parent
        while parent != nil {
            if let parentEditor = parent as? Editor {
                return parentEditor
            }

            parent = parent?.parent
        }
        return nil
    }

    var childEditors: [Editor] {
        return self.children.compactMap { $0 as? Editor }
    }

    func inspectorsDidChange() {
        self.parentEditor?.inspectorsDidChange()
    }

    func open(_ link: PageLink) {
        self.parentEditor?.open(link)
    }
    
    func prepareForDisplay(withSafeAreaInsets safeAreaInsets: NSEdgeInsets) {
        self.childEditors.forEach { $0.prepareForDisplay(withSafeAreaInsets: safeAreaInsets) }
    }
}
