//
//  MovableHandleAccessibilityElement.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/05/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

protocol MovableHandleAccessibilityElementDelegate: AnyObject {
    func didMove(_ handle: MovableHandleAccessibilityElement, byDelta delta: CGPoint) -> CGPoint
}

class MovableHandleAccessibilityElement: NSAccessibilityElement, NSAccessibilityElementProtocol {
    private var previousOrigin: CGPoint?
    weak var delegate: MovableHandleAccessibilityElementDelegate?

	var context: Any?

    override func setAccessibilityFrame(_ accessibilityFrame: NSRect) {
        self.setAccessibilityFrame(accessibilityFrame, callingDelegate: true)
    }

    func setAccessibilityFrame(_ accessibilityFrame: NSRect, callingDelegate: Bool = true) {
        var frame = accessibilityFrame

        if callingDelegate, let previousOrigin = self.previousOrigin, let delegate = self.delegate {
            var delta = frame.origin.minus(previousOrigin)
            delta.y *= -1 //We need to flip this as the layout engine has a top-left origin
            var finalDelta = delegate.didMove(self, byDelta: delta)
            finalDelta.y *= -1 //We need to flip this back as accessibility has a bottom-left origin
            frame.origin = previousOrigin.plus(finalDelta)
        }

        self.previousOrigin = frame.origin

        super.setAccessibilityFrame(frame)
    }


	override func accessibilityIdentifier() -> String {
		return super.accessibilityIdentifier() ?? "ResizeHandle"
	}
}

