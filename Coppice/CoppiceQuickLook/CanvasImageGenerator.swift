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
            color = NSColor(named: "CanvasBackgroundLight") ?? .lightGray
        case .dark:
            color = NSColor(named: "CanvasBackgroundDark") ?? .darkGray
        case .auto:
            if (NSAppearance.currentDrawing().name == .darkAqua) {
                color = NSColor(named: "CanvasBackgroundDark") ?? .darkGray
            } else {
                color = NSColor(named: "CanvasBackgroundLight") ?? .lightGray
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
            color = NSColor(named: "ArrowColourLight") ?? .darkGray
        case .dark:
            color = NSColor(named: "ArrowColourDark") ?? .white
        case .auto:
            if (NSAppearance.currentDrawing().name == .darkAqua) {
                color = NSColor(named: "ArrowColourDark") ?? .white
            } else {
                color = NSColor(named: "ArrowColourLight") ?? .darkGray
            }
        }
        guard let arrowColour = color else {
            return
        }
        for arrow in self.canvasLayoutEngine.links {
            let image = self.image(for: arrow, colour: arrowColour)
            image.draw(in: arrow.layoutFrame)
        }
    }

    private func image(for arrow: LayoutEngineLink, colour: NSColor) -> NSImage {
        let image = NSImage(size: arrow.layoutFrame.size)
        image.lockFocusFlipped(true)
        self.arrowDrawHelper.draw(arrow, with: colour, borderColor: nil, isConcrete: true)
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
            guard let content = page.content as? Page.Content.Text else {
                return
            }
            self.draw(content, in: rect)
        case .image:
            guard let content = page.content as? Page.Content.Image else {
                return
            }
            self.draw(content, in: rect)
        }
    }

    private func draw(_ textContent: Page.Content.Text, in rect: CGRect) {
        var insets = GlobalConstants.textEditorInsets()
        //NSTextView adds some additional insets so we need to add them ourselves
        insets.left += 5
        insets.right += 5
        textContent.text.draw(in: rect.insetBy(insets))
    }

    private func draw(_ imageContent: Page.Content.Image, in rect: CGRect) {
        imageContent.image?.draw(in: rect)
    }
}
