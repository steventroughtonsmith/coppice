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
    @IBInspectable var image: NSImage? {
        didSet { self.invalidateIntrinsicContentSize() }
    }


    //MARK: - Border Style
    @IBInspectable var backgroundColor: NSColor = .black {
        didSet { self.setNeedsDisplay(self.bounds) }
    }

    @IBInspectable var borderColor: NSColor = .white {
        didSet { self.setNeedsDisplay(self.bounds) }
    }

    @IBInspectable var borderWidth: CGFloat = 1 {
        didSet { self.setNeedsDisplay(self.bounds) }
    }

    @IBInspectable var cornerRadius: CGFloat = 3 {
        didSet { self.setNeedsDisplay(self.bounds) }
    }


    //MARK: - Size
    var preferredMaxDimensions = CGSize.zero {
        didSet { self.invalidateIntrinsicContentSize() }
    }


    //MARK: - Drawing
    override func draw(_ dirtyRect: NSRect) {
        let contentPath = NSBezierPath(roundedRect: self.bounds, xRadius: self.cornerRadius, yRadius: self.cornerRadius)

        self.backgroundColor.set()
        contentPath.fill()

        if let image = self.image {
            NSGraphicsContext.saveGraphicsState()
            contentPath.setClip()

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
