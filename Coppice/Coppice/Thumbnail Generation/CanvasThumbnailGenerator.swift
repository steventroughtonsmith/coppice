//
//  CanvasThumbnailGenerator.swift
//  Coppice
//
//  Created by Martin Pilkington on 06/01/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

class CanvasThumbnailGenerator: NSObject {
    let canvas: Canvas
    init(canvas: Canvas) {
        self.canvas = canvas
        super.init()
    }

    func generateThumbnail(of size: CGSize, theme: Canvas.Theme? = nil) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocusFlipped(true)

        self.drawPageRects(forImageOfSize: size)

        image.unlockFocus()
        return image
    }

    struct Context {
        let xScale: CGFloat
        let yScale: CGFloat
        let dryRun: Bool
        let scaledOffset: CGPoint
    }


    private let imageInset: CGFloat = 5

    private func drawPageRects(forImageOfSize size: CGSize) {
        let pageFrames = self.pageFramesInCanvasSpace()
        guard let canvasSize = self.canvasFrame(fromPageFrames: pageFrames)?.size else {
            return
        }
        var pageRectsByID = [ModelID: CGRect]()
        var rootCanvasPages = [CanvasPage]()
        let insetImageSize = size.minus(width: self.imageInset * 2, height: self.imageInset * 2)
        let (xScale, yScale) = self.scaleFactor(fromCanvasSize: canvasSize, toImageSize: insetImageSize)
        let scaledOffset = self.offset(forCanvasSize: canvasSize, inImageOfSize: insetImageSize, xScale: xScale, yScale: yScale)

        let layoutContext = Context(xScale: xScale, yScale: yScale, dryRun: true, scaledOffset: scaledOffset)
        for (canvasPage, frame) in pageFrames {
            guard let page = canvasPage.page else {
                continue
            }
            let pageRect = self.draw(page, with: frame, context: layoutContext)
            pageRectsByID[canvasPage.id] = pageRect
            if canvasPage.parent == nil {
                rootCanvasPages.append(canvasPage)
            }
        }

        let drawContext = Context(xScale: xScale, yScale: yScale, dryRun: false, scaledOffset: scaledOffset)
        for canvasPage in rootCanvasPages {
            self.drawArrows(from: canvasPage, pageRects: pageRectsByID, context: drawContext)
        }

        for (canvasPage, frame) in pageFrames {
            guard let page = canvasPage.page else {
                continue
            }
            self.draw(page, with: frame, context: drawContext)
        }
    }

    private func pageFramesInCanvasSpace() -> [(CanvasPage, CGRect)] {
        let framesInPageSpace = self.canvas.sortedPages.compactMap { ($0, $0.frame) }
        guard let canvasFrame = self.canvasFrame(fromPageFrames: framesInPageSpace) else {
            return []
        }

        return framesInPageSpace.map { ($0, CGRect(origin: $1.origin.minus(x: canvasFrame.minX, y: canvasFrame.minY), size: $1.size)) }
    }

    private func canvasFrame(fromPageFrames pageFrames: [(CanvasPage, CGRect)]) -> CGRect? {
        var canvasFrame: CGRect? = nil
        for (_, frame) in pageFrames {
            guard let currentFrame = canvasFrame else {
                canvasFrame = frame
                continue
            }
            canvasFrame = currentFrame.union(frame)
        }
        return canvasFrame
    }

    private func scaleFactor(fromCanvasSize canvasSize: CGSize, toImageSize imageSize: CGSize) -> (CGFloat, CGFloat) {
        let scaledCanvasSize = canvasSize.scaleDownToFit(width: imageSize.width, height: imageSize.height).rounded()

        let xScale = scaledCanvasSize.width / canvasSize.width
        let yScale = scaledCanvasSize.height / canvasSize.height
        return (xScale, yScale)
    }

    private func offset(forCanvasSize canvasSize: CGSize, inImageOfSize imageSize: CGSize, xScale: CGFloat, yScale: CGFloat) -> CGPoint {
        let scaledWidth = canvasSize.width * xScale
        let scaledHeight = canvasSize.height * xScale

        let xOffset = (imageSize.width - scaledWidth) / 2
        let yOffset = (imageSize.height - scaledHeight) / 2
        return CGPoint(x: xOffset + self.imageInset, y: yOffset + self.imageInset)
    }


    //MARK: - Drawing
    @discardableResult private func draw(_ page: Page, with rect: CGRect, context: Context) -> CGRect {
        switch page.content.contentType {
        case .text:
            return self.drawTextPage(page, with: rect, context: context)
        case .image:
            return self.drawImagePage(page, with: rect, context: context)
        }
    }


    //MARK: - Text Page
    private func drawTextPage(_ page: Page, with rect: CGRect, context: Context) -> CGRect {
        let plainPageRect = self.drawPlainPage(withBackgroundColour: .white, with: rect, context: context)
        guard
            let textContent = page.content as? TextPageContent,
            context.dryRun == false
        else {
            return plainPageRect
        }

        self.drawText(using: textContent.text, with: rect, context: context)
        return plainPageRect
    }

    private func drawText(using attributedString: NSAttributedString, with rect: CGRect, context: Context) {
        //We want to get the bounding rect and use that as the basis to scroll down
        let boundingRect = attributedString.boundingRect(with: NSSize(width: rect.width, height: 5000), options: .usesLineFragmentOrigin)
        let scaledBoundingRect = CGRect(x: rect.origin.x * context.xScale + context.scaledOffset.x,
                                        y: rect.origin.y * context.yScale + context.scaledOffset.y,
                                        width: rect.width * context.xScale,
                                        height: min(boundingRect.height, rect.height) * context.yScale).rounded()

        //We'll scale down from the base height, so we can have an appropriate line height
        let baseHeight: CGFloat = {
            if (context.yScale > 0.1) {
                return 10
            }
            if context.yScale > 0.07 {
                return 20
            }
            return 30
        }()
        let textHeight = max((baseHeight * context.yScale).rounded(.up), 1)

        //We'll inset by the text height, so again it adjusts by page size
        let insetRect = scaledBoundingRect.insetBy(dx: textHeight + 1, dy: textHeight + 1)

        //Our seed is based off the width and the length, as those are the things that cause text to re-layout
        let seed = Int(rect.width * rect.width * CGFloat(attributedString.length))

        //We'll now calculate the lines and draw them
        let lineRects = self.calculateLinesRects(in: insetRect, seed: seed, textHeight: textHeight)
        NSColor(white: 0.6, alpha: 1).set()
        for lineRect in lineRects {
            let path = NSBezierPath(roundedRect: lineRect, xRadius: textHeight / 2, yRadius: textHeight / 2)
            path.fill()
        }
    }

    private func calculateLinesRects(in rect: CGRect, seed: Int, textHeight: CGFloat) -> [CGRect] {
        var lineRects = [CGRect]()

        var currentY = rect.minY
        var currentLine = 0
        while (currentY < rect.maxY) {
            //Lets get some info on what our size should be
            let (widthPercentage, isSmallWidth) = self.lineInfo(forSeed: seed, forLine: currentLine)
            lineRects.append(CGRect(x: rect.minX, y: currentY, width: (rect.width * widthPercentage), height: textHeight).rounded())
            currentY += (textHeight * 2)
            //If we have a small width, we're at the end of a 'paragraph', so add an empty line
            if (isSmallWidth) {
                currentY += textHeight
            }
            currentLine += 1
        }

        return lineRects
    }

    private func lineInfo(forSeed seed: Int, forLine line: Int) -> (CGFloat, Bool) {
        //We'll make our paragraphs every 4-5 lines
        let smallLines = 4 + (seed % 2)
        let isSmallLine = (line % smallLines == 0) && (line > 0)

        //As the lines go on we'll cycle the values from right to left to work out our line size (looping through)
        //We'll then use this to work out what percentage of the flexible part (max - base) this line should have
        let seedComponent = self.component(fromSeed: seed, forLine: line)
        let baseWidth = isSmallLine ? CGFloat(0.2) : CGFloat(0.8)
        let maxWidth = isSmallLine ? CGFloat(0.6) : CGFloat(1.0)
        let offsetWidth = (maxWidth - baseWidth) * (CGFloat(seedComponent) / 10.0)
        return (baseWidth + offsetWidth, isSmallLine)
    }

    private func component(fromSeed seed: Int, forLine line: Int) -> Int {
        var seedString = "\(seed)"
        seedString.removeFirst(1)

        let offset = line % seedString.count
        let character = String(seedString[seedString.index(seedString.startIndex, offsetBy: offset)])

        return Int(character) ?? seedString.count
    }


    //MARK: - Image Page
    private func drawImagePage(_ page: Page, with rect: CGRect, context: Context) -> CGRect {
        guard
            let imageContent = page.content as? ImagePageContent,
            let image = imageContent.image
        else {
                return self.drawPlainPage(withBackgroundColour: NSColor(white: 0.4, alpha: 1), with: rect, context: context)
        }


        let scaledRect = CGRect(x: rect.origin.x * context.xScale + context.scaledOffset.x,
                                y: rect.origin.y * context.yScale + context.scaledOffset.y,
                                width: max(rect.size.width * context.xScale, 2),
                                height: max(rect.size.height * context.yScale, 2)).rounded()
        guard context.dryRun == false else {
            return scaledRect
        }

        NSGraphicsContext.saveGraphicsState()
        let radius: CGFloat = (context.xScale < 0.1) ? 1 : 2
        let page = NSBezierPath(roundedRect: scaledRect.insetBy(dx: 1, dy: 1), xRadius: radius, yRadius: radius)
        page.setClip()

        image.draw(in: scaledRect, from: imageContent.cropRect.flipped(in: CGRect(origin: .zero, size: image.size)), operation: .sourceOver, fraction: 1, respectFlipped: true, hints: nil)
        NSGraphicsContext.restoreGraphicsState()
        return scaledRect
    }


    //MARK: - Empty page
    private func drawPlainPage(withBackgroundColour colour: NSColor, with rect: CGRect, context: Context) -> CGRect {
        let scaledRect = CGRect(x: rect.origin.x * context.xScale + context.scaledOffset.x,
                                y: rect.origin.y * context.yScale + context.scaledOffset.y,
                                width: max(rect.size.width * context.xScale, 2),
                                height: max(rect.size.height * context.yScale, 2)).rounded()
        guard context.dryRun == false else {
            return scaledRect
        }

        let radius: CGFloat = (context.xScale < 0.1) ? 1 : 2
        let page = NSBezierPath(roundedRect: scaledRect.insetBy(dx: 1, dy: 1), xRadius: radius, yRadius: radius)
        colour.set()
        page.fill()

        let pageStroke = NSBezierPath(roundedRect: scaledRect.insetBy(dx: 0.5, dy: 0.5), xRadius: radius, yRadius: radius)
        NSColor(white: 0, alpha: 0.3).set()
        pageStroke.lineWidth = 1
        pageStroke.stroke()
        return scaledRect
    }


    //MARK: - Arrows
    private func drawArrows(from rootPage: CanvasPage, pageRects: [ModelID: CGRect], context: Context) {
        NSColor.white.set()
        guard let rootRect = pageRects[rootPage.id] else {
            return
        }

        for childPage in rootPage.children {
            guard let childRect = pageRects[childPage.id] else {
                continue
            }

            var startPoint: CGPoint = rootRect.midPoint.rounded()
            var endPoint: CGPoint = childRect.midPoint.rounded()

            let deltaY = startPoint.y - endPoint.y
            let deltaX = startPoint.x - endPoint.x

            let control1: CGPoint
            let control2: CGPoint

            //Horizontal
            if (abs(deltaY) < abs(deltaX)) {
                //Start to right
                if (deltaX) > 0 {
                    startPoint.x = rootRect.minX
                    endPoint.x = childRect.maxX
                }
                //Start to left
                else {
                    startPoint.x = rootRect.maxX
                    endPoint.x = childRect.minX
                }
                control1 = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: startPoint.y)
                control2 = CGPoint(x: (startPoint.x + endPoint.x) / 2, y: endPoint.y)
            }
            //Vertical
            else {
                //Start above
                if (deltaY) > 0 {
                    startPoint.y = rootRect.minY
                    endPoint.y = childRect.maxY
                }
                //Start below
                else {
                    startPoint.y = rootRect.maxY
                    endPoint.y = childRect.minY
                }
                control1 = CGPoint(x: startPoint.x, y: (startPoint.y + endPoint.y) / 2)
                control2 = CGPoint(x: endPoint.x, y: (startPoint.y + endPoint.y) / 2)
            }

            let bezierPath = NSBezierPath()
            bezierPath.move(to: startPoint)
            bezierPath.curve(to: endPoint, controlPoint1: control1, controlPoint2: control2)
            bezierPath.lineWidth = (context.xScale < 0.1) ? 1 : 2
            bezierPath.stroke()

            if childPage.children.count > 0 {
                self.drawArrows(from: childPage, pageRects: pageRects, context: context)
            }
        }
    }
}
