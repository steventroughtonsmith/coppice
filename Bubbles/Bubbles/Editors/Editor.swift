//
//  Editor.swift
//  Bubbles
//
//  Created by Martin Pilkington on 13/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

protocol Editor {
    var inspectors: [Any] { get }
    var parentEditor: Editor? { get }
    var childEditors: [Editor] { get }

    func inspectorsDidChange()
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
}
