//
//  TranslucentSegmentedControl.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit

class TranslucentSegmentedControl: NSSegmentedControl {
    override class var cellClass: AnyClass? {
        get {
            return TranslucentSegmentedCell.self
        }
        set {}
    }

    override var intrinsicContentSize: NSSize {
        var size = super.intrinsicContentSize
        size.height = 40
        return size
    }
}

class TranslucentSegmentedCell: NSSegmentedCell {
    override func draw(withFrame cellFrame: NSRect, in controlView: NSView) {
        NSColor(white: 0, alpha: 0.85).setFill()
        NSBezierPath(roundedRect: cellFrame, xRadius: 8, yRadius: 8).setClip()

        cellFrame.fill()

        var currentX: CGFloat = 0
        let floatingSegmentCount = CGFloat(self.segmentCount)
        (0..<self.segmentCount).forEach { segment in
            let segmentWidth = (cellFrame.width - (floatingSegmentCount - 1)) / floatingSegmentCount

            var frame = cellFrame
            frame.origin.x = currentX
            frame.size.width = segmentWidth
            currentX += segmentWidth + 1

            if self.selectedSegment == segment {
                NSColor(white: 1, alpha: 0.3).setFill()
                var fillFrame = frame
                fillFrame.size.width -= 2
                if segment == (self.segmentCount - 1) {
                    fillFrame.origin.x += 2
                } else if segment > 0 {
                    fillFrame.size.width -= 2
                    fillFrame.origin.x += 2
                }
                fillFrame.fill()
            }

            //Shift icons up a bit
            frame.origin.y -= 1
            self.drawSegment(segment, inFrame: frame, with: controlView)
        }
    }

    override func drawSegment(_ segment: Int, inFrame frame: NSRect, with controlView: NSView) {
        super.drawSegment(segment, inFrame: frame, with: controlView)
    }
}
