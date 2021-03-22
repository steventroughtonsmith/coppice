//
//  KeyboardMovePageEventContext.swift
//  Coppice
//
//  Created by Martin Pilkington on 18/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Carbon.HIToolbox
import Foundation

class KeyboardMovePageEventContext: CanvasKeyEventContext {
    static var acceptedKeyCodes = [UInt16(kVK_LeftArrow), UInt16(kVK_RightArrow), UInt16(kVK_UpArrow), UInt16(kVK_DownArrow)]

    let pages: [LayoutEnginePage]
    init(pages: [LayoutEnginePage]) {
        self.pages = pages
    }

    func keyDown(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, isARepeat: Bool, in layout: LayoutEngine) {
        guard KeyboardMovePageEventContext.acceptedKeyCodes.contains(keyCode) else {
            return
        }

        let delta = self.delta(forKeyCode: keyCode, modifiers: modifiers)
        for page in self.pages {
            page.layoutFrame.origin = page.layoutFrame.origin.plus(delta)
        }

        layout.modified(self.pages)
    }

    func keyUp(withCode keyCode: UInt16, modifiers: LayoutEventModifiers, in layout: LayoutEngine) {
        guard KeyboardMovePageEventContext.acceptedKeyCodes.contains(keyCode) else {
            return
        }

        layout.finishedModifying(self.pages)
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
