//
//  RemovePageEventContext.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import Carbon.HIToolbox

class RemovePageEventContext: CanvasEventContext {
    static var acceptedKeyCodes = [UInt16(kVK_Delete), UInt16(kVK_ForwardDelete)]

    func keyUp(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine) {
        guard RemovePageEventContext.acceptedKeyCodes.contains(keyCode) else {
            return
        }

        guard layout.selectedPages.count > 0 else {
            return
        }

        layout.tellDelegateToRemove(layout.selectedPages)
    }
}
