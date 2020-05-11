//
//  NSSegmentedControl+M3Extensions.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

extension NSSegmentedControl {
    func segment(forTag tag: Int) -> Int {
        for segment in (0..<self.segmentCount) {
            if self.tag(forSegment: segment) == tag {
                return segment
            }
        }
        return -1
    }
}
