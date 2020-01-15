//
//  CanvasPreviewView.swift
//  ImageViewTest
//
//  Created by Martin Pilkington on 10/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

@IBDesignable
class CanvasPreviewView: NSView {
    //MARK: - Content
    @IBInspectable var previewImage: NSImage? {
        didSet { self.invalidateIntrinsicContentSize() }
    }


    //MARK: - Border Style
    @IBInspectable var borderColor: NSColor = .white {
        didSet { self.setNeedsDisplay(self.bounds)}
    }
    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet { self.setNeedsDisplay(self.bounds)}
    }
    @IBInspectable var cornerRadius: CGFloat = 3 {
        didSet { self.setNeedsDisplay(self.bounds)}
    }


    //MARK: - Size
    var preferredMaxDimensions = CGSize.zero {
        didSet { self.invalidateIntrinsicContentSize() }
    }

    override var intrinsicContentSize: NSSize {
        guard var size = self.previewImage?.size else {
            return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
        }

        let maxSize = self.preferredMaxDimensions

        if (maxSize.width > 0) && (size.width > maxSize.width) {
            size.height = (size.height / size.width) * maxSize.width
            size.width = maxSize.width
        }

        if (maxSize.height > 0) && (size.height > maxSize.height) {
            size.width = (size.width / size.height) * maxSize.height
            size.height = maxSize.height
        }

        return size
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        if let image = self.previewImage {
            NSGraphicsContext.saveGraphicsState()
            let clipPath = NSBezierPath(roundedRect: self.bounds, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
            clipPath.setClip()
            image.draw(in: self.bounds)
            NSGraphicsContext.restoreGraphicsState()
        }

        let strokeBounds = self.bounds.insetBy(dx: 0.5, dy: 0.5)
        let strokePath = NSBezierPath(roundedRect: strokeBounds, xRadius: self.cornerRadius, yRadius: self.cornerRadius)
        strokePath.lineWidth = self.borderWidth

        self.borderColor.set()
        strokePath.stroke()
    }
}
