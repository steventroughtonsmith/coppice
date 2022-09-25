//
//  CreateLinkKeyEventContext.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 25/09/2022.
//

import Carbon.HIToolbox
import Foundation

class CreateLinkKeyEventContext: CanvasKeyEventContext {
    static var acceptedKeyCodes = [UInt16(kVK_Escape)]

    let layoutEngine: LayoutEngine
    init(layoutEngine: LayoutEngine) {
        self.layoutEngine = layoutEngine
    }

    func keyDown(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: LayoutEngine) {
        guard Self.acceptedKeyCodes.contains(keyCode) else {
            return
        }

        self.layoutEngine.finishLinking(withDestination: nil)
    }
}
