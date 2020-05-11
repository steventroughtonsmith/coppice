//
//  KeyboardMovePageEventContext.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import Carbon.HIToolbox

class KeyboardMovePageEventContext: CanvasEventContext {
    static var acceptedKeyCodes = [UInt16(kVK_LeftArrow), UInt16(kVK_RightArrow), UInt16(kVK_UpArrow), UInt16(kVK_DownArrow)]

    func keyDown(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: CanvasLayoutEngine) {
        guard KeyboardMovePageEventContext.acceptedKeyCodes.contains(keyCode) else {
            return
        }

        let delta = self.delta(forKeyCode: keyCode, modifiers: modifiers)
        for page in layout.selectedPages {
            page.layoutFrame.origin = page.layoutFrame.origin.plus(delta)
        }

        layout.modified(layout.selectedPages)
    }

    func keyUp(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, in layout: CanvasLayoutEngine) {
        guard KeyboardMovePageEventContext.acceptedKeyCodes.contains(keyCode) else {
            return
        }

        layout.finishedModifying(layout.selectedPages)
    }

    private func delta(forKeyCode keyCode: UInt16, modifiers: LayoutEventModifiers) -> CGPoint {
        let offset = modifiers.contains(.shift) ? 10 : 1
        switch Int(keyCode) {
        case kVK_LeftArrow:
            return CGPoint(x: -offset, y: 0)
        case kVK_RightArrow:
            return CGPoint(x: offset, y: 0)
        case kVK_UpArrow:
            return CGPoint(x: 0, y: -offset)
        case kVK_DownArrow:
            return CGPoint(x: 0, y: offset)
        default:
            return .zero
        }
    }
}
