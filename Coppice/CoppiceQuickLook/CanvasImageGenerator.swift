//
//  CanvasImageGenerator.swift
//  CoppiceQuickLook
//
//  Created by Martin Pilkington on 21/07/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class CanvasImageGenerator {
    let canvas: Canvas
    let layoutPages: [LayoutEnginePage]
    let canvasLayoutEngine: CanvasLayoutEngine
    let arrowDrawHelper: ArrowDrawHelper
    init(canvas: Canvas, contentBorder: CGFloat) {
        self.canvas = canvas
        self.layoutPages = LayoutEnginePage.pages(from: Array(self.canvas.pages))
        self.canvasLayoutEngine = CanvasLayoutEngine(configuration: .init(page: .mac, contentBorder: contentBorder, arrow: .standard))
        self.arrowDrawHelper = ArrowDrawHelper(config: .standard)

        self.canvasLayoutEngine.add(self.layoutPages)
    }

    func generateImage() -> NSImage? {
        let image = NSImage(size: self.canvasLayoutEngine.canvasSize)
        image.lockFocusFlipped(true)
        self.drawBackground()
        self.drawArrows()
        self.drawPages()
        image.unlockFocus()
        return image
    }

    private func drawBackground() {
        let color: NSColor?
        switch self.canvas.theme {
        case .light:
            color = NSColor(named: "CanvasBackgroundLight")
        case .dark:
            color = NSColor(named: "CanvasBackgroundDark")
        case .auto:
            if (NSAppearance.current.name == .darkAqua) {
                color = NSColor(named: "CanvasBackgroundDark")
            } else {
                color = NSColor(named: "CanvasBackgroundLight")
            }
        }

        if let backgroundColor = color {
            backgroundColor.set()
            CGRect(origin: .zero, size: self.canvasLayoutEngine.canvasSize).fill()
        }
    }

    private func drawArrows() {
        let color: NSColor?
        switch self.canvas.theme {
        case .light:
            color = NSColor(named: "ArrowColourLight")
        case .dark:
            color = NSColor(named: "ArrowColourDark")
        case .auto:
            if (NSAppearance.current.name == .darkAqua) {
                color = NSColor(named: "ArrowColourDark")
            } else {
                color = NSColor(named: "ArrowColourLight")
            }
        }
        guard let arrowColour = color else {
            return
        }
        for arrow in self.canvasLayoutEngine.arrows {
            let image = self.image(for: arrow, colour: arrowColour)
            image.draw(in: arrow.layoutFrame)
        }
    }

    private func image(for arrow: LayoutEngineArrow, colour: NSColor) -> NSImage {
        let image = NSImage(size: arrow.layoutFrame.size)
        image.lockFocusFlipped(true)
        self.arrowDrawHelper.draw(arrow, with: colour)
        image.unlockFocus()
        return image
    }

    private func drawPages() {
        NSColor.white.set()
        for page in self.layoutPages {
            //We don't want the shadow to carry over
            NSGraphicsContext.current?.saveGraphicsState()
            var visualFrame = page.contentContainerFrame
            visualFrame.origin = visualFrame.origin.plus(page.layoutFrame.origin)
            let path = NSBezierPath(roundedRect: visualFrame, xRadius: 5, yRadius: 5)
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 4
            shadow.shadowOffset = CGSize(width: 0, height: -3)
            shadow.set()
            path.fill()
            NSGraphicsContext.current?.restoreGraphicsState()

            //We don't want the clip to carry over
            NSGraphicsContext.current?.saveGraphicsState()
            path.setClip()
            self.drawContents(of: page, in: visualFrame)
            NSGraphicsContext.current?.restoreGraphicsState()

        }
    }

    private func drawContents(of page: LayoutEnginePage, in rect: CGRect) {
        guard
            let canvasPage = self.canvas.pages.first(where: { $0.id.uuid == page.id }),
            let page = canvasPage.page
        else {
            return
        }

        switch page.content.contentType {
        case .text:
            guard let content = page.content as? TextPageContent else {
                return
            }
            self.draw(content, in: rect)
        case .image:
            guard let content = page.content as? ImagePageContent else {
                return
            }
            self.draw(content, in: rect)
        }
    }

    private func draw(_ textContent: TextPageContent, in rect: CGRect) {
        var insets = GlobalConstants.textEditorInsets
        //NSTextView adds some additional insets so we need to add them ourselves
        insets.left += 5
        insets.right += 5
        textContent.text.draw(in: rect.insetBy(insets))
    }

    private func draw(_ imageContent: ImagePageContent, in rect: CGRect) {
        imageContent.image?.draw(in: rect)
    }
}
