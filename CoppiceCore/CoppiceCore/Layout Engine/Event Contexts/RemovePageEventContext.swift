//
//  RemovePageEventContext.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Carbon.HIToolbox
import Foundation

class RemovePageEventContext: CanvasKeyEventContext {
    static var acceptedKeyCodes = [UInt16(kVK_Delete), UInt16(kVK_ForwardDelete)]

    let pages: [LayoutEnginePage]
    init(pages: [LayoutEnginePage]) {
        self.pages = pages
    }

    func keyUp(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, in layout: LayoutEngine) {
        guard RemovePageEventContext.acceptedKeyCodes.contains(keyCode), self.pages.count > 0 else {
            return
        }

        layout.tellDelegateToRemove(self.pages)
    }
}
