//
//  DebugDocumentBuild.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/08/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import AppKit
import CoppiceCore

class DebugDocumentBuilder: NSObject {
    static let shared = DebugDocumentBuilder()

    private func addLinks(from sourcePage: CanvasPage, to destinationPages: [CanvasPage], on canvas: Canvas) {
        let textContent = Page.Content.Text()
        let attributedString = NSMutableAttributedString()
        for destinationPage in destinationPages {
            let pageLink = PageLink(destination: destinationPage.page!.id, source: sourcePage.id)
            attributedString.append(NSAttributedString(string: destinationPage.title, attributes: [
                .link: pageLink.url,
            ]))
            attributedString.append(NSAttributedString(string: "\n"))
            canvas.addLink(pageLink, between: sourcePage, and: destinationPage)
        }
        textContent.text = attributedString
        sourcePage.page!.content = textContent
    }

    @objc func createNewDebugDocument(_ sender: Any) {
        guard
            let docController = (NSApplication.shared.delegate as? AppDelegate)?.documentController,
            let document = try? docController.openUntitledDocumentAndDisplay(true) as? Document
        else {
            return
        }

        let mc = document.modelController
        self.createLinkTypesCanvas(using: mc)
        self.createImageLinkCanvas(using: mc)
    }

    private func createLinkTypesCanvas(using mc: CoppiceModelController) {
        let folder = mc.createFolder(in: mc.rootFolder) { $0.title = "Canvas Link Types" }

        let a = mc.createPage(in: folder) { $0.title = "A"; $0.contentSize = Page.defaultMinimumContentSize }
        let b = mc.createPage(in: folder) { $0.title = "B"; $0.contentSize = Page.defaultMinimumContentSize }
        let c = mc.createPage(in: folder) { $0.title = "C"; $0.contentSize = Page.defaultMinimumContentSize }
        let d = mc.createPage(in: folder) { $0.title = "D"; $0.contentSize = Page.defaultMinimumContentSize }
        let e = mc.createPage(in: folder) { $0.title = "E"; $0.contentSize = Page.defaultMinimumContentSize }
        let f = mc.createPage(in: folder) { $0.title = "F"; $0.contentSize = Page.defaultMinimumContentSize }
        let g = mc.createPage(in: folder) { $0.title = "G"; $0.contentSize = Page.defaultMinimumContentSize }
        let h = mc.createPage(in: folder) { $0.title = "H"; $0.contentSize = Page.defaultMinimumContentSize }
        let i = mc.createPage(in: folder) { $0.title = "I"; $0.contentSize = Page.defaultMinimumContentSize }
        let j = mc.createPage(in: folder) { $0.title = "J"; $0.contentSize = Page.defaultMinimumContentSize }
        let k = mc.createPage(in: folder) { $0.title = "K"; $0.contentSize = Page.defaultMinimumContentSize }
        let l = mc.createPage(in: folder) { $0.title = "L"; $0.contentSize = Page.defaultMinimumContentSize }
        let m = mc.createPage(in: folder) { $0.title = "M"; $0.contentSize = Page.defaultMinimumContentSize }
        let n = mc.createPage(in: folder) { $0.title = "N"; $0.contentSize = Page.defaultMinimumContentSize }
        let o = mc.createPage(in: folder) { $0.title = "O"; $0.contentSize = Page.defaultMinimumContentSize }
        let p = mc.createPage(in: folder) { $0.title = "P"; $0.contentSize = Page.defaultMinimumContentSize }
        let q = mc.createPage(in: folder) { $0.title = "Q"; $0.contentSize = Page.defaultMinimumContentSize }
        let r = mc.createPage(in: folder) { $0.title = "R"; $0.contentSize = Page.defaultMinimumContentSize }
        let s = mc.createPage(in: folder) { $0.title = "S"; $0.contentSize = Page.defaultMinimumContentSize }
        let t = mc.createPage(in: folder) { $0.title = "T"; $0.contentSize = Page.defaultMinimumContentSize }
        let u = mc.createPage(in: folder) { $0.title = "U"; $0.contentSize = Page.defaultMinimumContentSize }
        let v = mc.createPage(in: folder) { $0.title = "V"; $0.contentSize = Page.defaultMinimumContentSize }
        let w = mc.createPage(in: folder) { $0.title = "W"; $0.contentSize = Page.defaultMinimumContentSize }
        _ = mc.createPage(in: folder) { $0.title = "X"; $0.contentSize = Page.defaultMinimumContentSize }
        _ = mc.createPage(in: folder) { $0.title = "Y"; $0.contentSize = Page.defaultMinimumContentSize }
        _ = mc.createPage(in: folder) { $0.title = "Z"; $0.contentSize = Page.defaultMinimumContentSize }

        let grid: CGFloat = 200

        let canvas = mc.createCanvas() {
            $0.alwaysShowPageTitles = true
            $0.title = "Canvas Link Types"
        }
        let cpA = canvas.addPages([a], centredOn: CGPoint(x: 0, y: 0))[0]
        let cpB = canvas.addPages([b], centredOn: CGPoint(x: 1 * grid, y: 0 * grid))[0]
        let cpC = canvas.addPages([c], centredOn: CGPoint(x: 2 * grid, y: 0 * grid))[0]
        let cpD = canvas.addPages([d], centredOn: CGPoint(x: 2 * grid, y: 1 * grid))[0]
        self.addLinks(from: cpA, to: [cpB], on: canvas)
        self.addLinks(from: cpB, to: [cpC, cpD], on: canvas)

        let cpE = canvas.addPages([e], centredOn: CGPoint(x: 0 * grid, y: 2 * grid))[0]
        let cpF = canvas.addPages([f], centredOn: CGPoint(x: 1 * grid, y: 2 * grid))[0]
        let cpG = canvas.addPages([g], centredOn: CGPoint(x: 1 * grid, y: 3 * grid))[0]
        let cpH = canvas.addPages([h], centredOn: CGPoint(x: 0 * grid, y: 3 * grid))[0]
        self.addLinks(from: cpE, to: [cpF], on: canvas)
        self.addLinks(from: cpF, to: [cpG], on: canvas)
        self.addLinks(from: cpG, to: [cpH], on: canvas)
        self.addLinks(from: cpH, to: [cpE], on: canvas)

        let cpI = canvas.addPages([i], centredOn: CGPoint(x: 0 * grid, y: 4 * grid))[0]
        let cpJ = canvas.addPages([j], centredOn: CGPoint(x: 1 * grid, y: 4 * grid))[0]
        let cpK = canvas.addPages([k], centredOn: CGPoint(x: 2 * grid, y: 4 * grid))[0]
        let cpL = canvas.addPages([l], centredOn: CGPoint(x: 2 * grid, y: 5 * grid))[0]
        let cpM = canvas.addPages([m], centredOn: CGPoint(x: 3 * grid, y: 4 * grid))[0]
        let cpN = canvas.addPages([n], centredOn: CGPoint(x: 3 * grid, y: 5 * grid))[0]
        self.addLinks(from: cpI, to: [cpJ], on: canvas)
        self.addLinks(from: cpJ, to: [cpK, cpL], on: canvas)
        self.addLinks(from: cpK, to: [cpM], on: canvas)
        self.addLinks(from: cpL, to: [cpN], on: canvas)
        self.addLinks(from: cpN, to: [cpM], on: canvas)

        let cpO = canvas.addPages([o], centredOn: CGPoint(x: 4 * grid, y: 0 * grid))[0]
        let cpP = canvas.addPages([p], centredOn: CGPoint(x: 5 * grid, y: 0 * grid))[0]
        let cpQ = canvas.addPages([q], centredOn: CGPoint(x: 6 * grid, y: 0 * grid))[0]
        let cpR = canvas.addPages([r], centredOn: CGPoint(x: 5 * grid, y: 1 * grid))[0]
        let cpS = canvas.addPages([s], centredOn: CGPoint(x: 6 * grid, y: 1 * grid))[0]
        self.addLinks(from: cpO, to: [cpP], on: canvas)
        self.addLinks(from: cpP, to: [cpQ, cpS], on: canvas)
        self.addLinks(from: cpR, to: [cpS], on: canvas)

        let cpT = canvas.addPages([t], centredOn: CGPoint(x: 5 * grid, y: 2 * grid))[0]
        let cpU = canvas.addPages([u], centredOn: CGPoint(x: 6 * grid, y: 2 * grid))[0]
        let cpV = canvas.addPages([v], centredOn: CGPoint(x: 5 * grid, y: 3 * grid))[0]
        let cpW = canvas.addPages([w], centredOn: CGPoint(x: 6 * grid, y: 3 * grid))[0]
        self.addLinks(from: cpT, to: [cpU], on: canvas)
        self.addLinks(from: cpU, to: [cpV, cpW], on: canvas)
        self.addLinks(from: cpV, to: [cpT], on: canvas)
    }

    private func createImageLinkCanvas(using mc: CoppiceModelController) {
        let folder = mc.createFolder(in: mc.rootFolder) { $0.title = "Image Links" }

        let textPage = mc.createPage(ofType: .text, in: folder) {
            $0.title = "Text To Image Link"
            $0.contentSize = Page.defaultMinimumContentSize
        }


        let appIcon = NSImage(named: "AppIcon")!
        for representation in appIcon.representations {
            if representation.size != CGSize(width: 128, height: 128) {
                appIcon.removeRepresentation(representation)
            }
        }

        let ovalImagePage = mc.createPage(ofType: .image, in: folder) {
            $0.title = "Oval Image Link"
            if let imageContent = $0.content as? Page.Content.Image {
                imageContent.setImage(appIcon, operation: .replace)

                imageContent.hotspots = [
                    ImageHotspot(kind: .oval, points: [
                        CGPoint(x: 32, y: 32),
                        CGPoint(x: 96, y: 32),
                        CGPoint(x: 96, y: 96),
                        CGPoint(x: 32, y: 96),
                    ], link: textPage.linkToPage().url),
                ]
            }
        }

        let polygonImagePage = mc.createPage(ofType: .image, in: folder) {
            $0.title = "Polygon Image Link"
            if let imageContent = $0.content as? Page.Content.Image {
                imageContent.setImage(appIcon, operation: .replace)

                imageContent.hotspots = [
                    ImageHotspot(kind: .polygon, points: [
                        CGPoint(x: 20, y: 20),
                        CGPoint(x: 100, y: 20),
                        CGPoint(x: 80, y: 80),
                        CGPoint(x: 50, y: 110),
                        CGPoint(x: 30, y: 80),
                    ], link: textPage.linkToPage().url),
                ]
            }
        }


        let rectangleImagePage = mc.createPage(ofType: .image, in: folder) {
            $0.title = "Rectangle Image Link"

            if let imageContent = $0.content as? Page.Content.Image {
                imageContent.setImage(appIcon, operation: .replace)

                imageContent.hotspots = [
                    ImageHotspot(kind: .rectangle, points: [
                        CGPoint(x: 20, y: 20),
                        CGPoint(x: 40, y: 20),
                        CGPoint(x: 40, y: 40),
                        CGPoint(x: 20, y: 40),
                    ], link: textPage.linkToPage().url),
                    ImageHotspot(kind: .rectangle, points: [
                        CGPoint(x: 20, y: 60),
                        CGPoint(x: 40, y: 60),
                        CGPoint(x: 40, y: 80),
                        CGPoint(x: 20, y: 80),
                    ], link: ovalImagePage.linkToPage().url),
                    ImageHotspot(kind: .rectangle, points: [
                        CGPoint(x: 60, y: 60),
                        CGPoint(x: 80, y: 60),
                        CGPoint(x: 80, y: 80),
                        CGPoint(x: 60, y: 80),
                    ], link: textPage.linkToPage().url),
                    ImageHotspot(kind: .rectangle, points: [
                        CGPoint(x: 60, y: 20),
                        CGPoint(x: 80, y: 20),
                        CGPoint(x: 80, y: 40),
                        CGPoint(x: 60, y: 20),
                    ], link: polygonImagePage.linkToPage().url),
                ]
            }
        }


        let grid: CGFloat = 200

        let canvas = mc.createCanvas() { $0.title = "Image Links"; $0.alwaysShowPageTitles = true }

        let textCP = canvas.addPages([textPage], centredOn: CGPoint(x: -1 * grid, y: -1 * grid))[0]
        let rectangleCP = canvas.addPages([rectangleImagePage], centredOn: CGPoint(x: grid, y: -1 * grid))[0]
//        let ovalCP = canvas.addPages([ovalImagePage], centredOn: CGPoint(x: -1 * grid, y: grid))[0]
//        let polygonCP = canvas.addPages([polygonImagePage], centredOn: CGPoint(x: grid, y: grid))[0]

        self.addLinks(from: textCP, to: [rectangleCP], on: canvas)

        //Text page to image page link
        //rectangle image link
        //oval image link
        //polygon image link
    }
}
