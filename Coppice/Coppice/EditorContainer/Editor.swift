//
//  Editor.swift
//  Bubbles
//
//  Created by Martin Pilkington on 13/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

enum EditorMode: Equatable {
    case editing
    case preview
}

protocol Editor: class {
    var inspectors: [Inspector] { get }
    var parentEditor: Editor? { get }
    var childEditors: [Editor] { get }

    func inspectorsDidChange()
    func open(_ link: PageLink)

    var enabled: Bool { get set }
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
}
