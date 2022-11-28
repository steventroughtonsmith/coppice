//
//  CanvasAccessibilityRotor.swift
//  Coppice
//
//  Created by Martin Pilkington on 27/11/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit

class CanvasAccessibilityRotor: NSObject, NSAccessibilityCustomRotorItemSearchDelegate {
    weak var canvasEditor: CanvasEditorViewController?
    init(canvasEditor: CanvasEditorViewController) {
        self.canvasEditor = canvasEditor
    }

    lazy var rotor: NSAccessibilityCustomRotor = {
        return NSAccessibilityCustomRotor(label: self.label, itemSearchDelegate: self)
    }()

    var label: String {
        return ""
    }

    func rotor(_ rotor: NSAccessibilityCustomRotor, resultFor searchParameters: NSAccessibilityCustomRotor.SearchParameters) -> NSAccessibilityCustomRotor.ItemResult? {
        return nil
    }
}
