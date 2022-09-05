//
//  RemovePageEventContext.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Carbon.HIToolbox
import Foundation

class RemoveItemEventContext: CanvasKeyEventContext {
    static var acceptedKeyCodes = [UInt16(kVK_Delete), UInt16(kVK_ForwardDelete)]

    let items: [LayoutEngineItem]
    init(items: [LayoutEngineItem]) {
        self.items = items
    }

    func keyUp(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, in layout: LayoutEngine) {
        guard RemoveItemEventContext.acceptedKeyCodes.contains(keyCode), self.items.count > 0 else {
            return
        }

        layout.tellDelegateToRemove(self.items)
    }
}
