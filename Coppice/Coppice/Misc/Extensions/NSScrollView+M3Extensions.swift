//
//  NSScrollView+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/09/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

extension NSClipView {
    var visualCentre: CGPoint {
        let scrollPoint = self.bounds.origin
        return scrollPoint.plus(CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2))
    }

    func centre(on point: CGPoint) {
        let scrollPoint = point.minus(CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)).rounded()
        self.scroll(to: scrollPoint)
    }
}
