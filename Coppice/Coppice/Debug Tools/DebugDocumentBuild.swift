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

    @objc func createNewDebugDocument(_ sender: Any) {
        guard
            let docController = (NSApplication.shared.delegate as? AppDelegate)?.documentController,
            let document = try? docController.openUntitledDocumentAndDisplay(true) as? Document
        else {
            return
        }

        let mc = document.modelController

        let a = mc.createPage(in: mc.rootFolder) { $0.title = "A"; $0.contentSize = Page.defaultMinimumContentSize }
        let b = mc.createPage(in: mc.rootFolder) { $0.title = "B"; $0.contentSize = Page.defaultMinimumContentSize }
        let c = mc.createPage(in: mc.rootFolder) { $0.title = "C"; $0.contentSize = Page.defaultMinimumContentSize }
        let d = mc.createPage(in: mc.rootFolder) { $0.title = "D"; $0.contentSize = Page.defaultMinimumContentSize }
        let e = mc.createPage(in: mc.rootFolder) { $0.title = "E"; $0.contentSize = Page.defaultMinimumContentSize }
        let f = mc.createPage(in: mc.rootFolder) { $0.title = "F"; $0.contentSize = Page.defaultMinimumContentSize }
        let g = mc.createPage(in: mc.rootFolder) { $0.title = "G"; $0.contentSize = Page.defaultMinimumContentSize }
        let h = mc.createPage(in: mc.rootFolder) { $0.title = "H"; $0.contentSize = Page.defaultMinimumContentSize }
        let i = mc.createPage(in: mc.rootFolder) { $0.title = "I"; $0.contentSize = Page.defaultMinimumContentSize }
        let j = mc.createPage(in: mc.rootFolder) { $0.title = "J"; $0.contentSize = Page.defaultMinimumContentSize }
        let k = mc.createPage(in: mc.rootFolder) { $0.title = "K"; $0.contentSize = Page.defaultMinimumContentSize }
        let l = mc.createPage(in: mc.rootFolder) { $0.title = "L"; $0.contentSize = Page.defaultMinimumContentSize }
        let m = mc.createPage(in: mc.rootFolder) { $0.title = "M"; $0.contentSize = Page.defaultMinimumContentSize }
        let n = mc.createPage(in: mc.rootFolder) { $0.title = "N"; $0.contentSize = Page.defaultMinimumContentSize }
        let o = mc.createPage(in: mc.rootFolder) { $0.title = "O"; $0.contentSize = Page.defaultMinimumContentSize }
        let p = mc.createPage(in: mc.rootFolder) { $0.title = "P"; $0.contentSize = Page.defaultMinimumContentSize }
        let q = mc.createPage(in: mc.rootFolder) { $0.title = "Q"; $0.contentSize = Page.defaultMinimumContentSize }
        let r = mc.createPage(in: mc.rootFolder) { $0.title = "R"; $0.contentSize = Page.defaultMinimumContentSize }
        let s = mc.createPage(in: mc.rootFolder) { $0.title = "S"; $0.contentSize = Page.defaultMinimumContentSize }
        let t = mc.createPage(in: mc.rootFolder) { $0.title = "T"; $0.contentSize = Page.defaultMinimumContentSize }
        let u = mc.createPage(in: mc.rootFolder) { $0.title = "U"; $0.contentSize = Page.defaultMinimumContentSize }
        let v = mc.createPage(in: mc.rootFolder) { $0.title = "V"; $0.contentSize = Page.defaultMinimumContentSize }
        let w = mc.createPage(in: mc.rootFolder) { $0.title = "W"; $0.contentSize = Page.defaultMinimumContentSize }
        _ = mc.createPage(in: mc.rootFolder) { $0.title = "X"; $0.contentSize = Page.defaultMinimumContentSize }
        _ = mc.createPage(in: mc.rootFolder) { $0.title = "Y"; $0.contentSize = Page.defaultMinimumContentSize }
        _ = mc.createPage(in: mc.rootFolder) { $0.title = "Z"; $0.contentSize = Page.defaultMinimumContentSize }

        let grid: CGFloat = 200;

        let canvas = mc.createCanvas() { $0.alwaysShowPageTitles = true }
        let cpA = canvas.addPages([a], centredOn: CGPoint(x: 0, y: 0))[0]
        let cpB = canvas.addPages([b], centredOn: CGPoint(x: 1 * grid, y: 0 * grid))[0]
        let cpC = canvas.addPages([c], centredOn: CGPoint(x: 2 * grid, y: 0 * grid))[0]
        let cpD = canvas.addPages([d], centredOn: CGPoint(x: 2 * grid, y: 1 * grid))[0]
        canvas.addLink(between: cpA, and: cpB)
        canvas.addLink(between: cpB, and: cpC)
        canvas.addLink(between: cpB, and: cpD)

        let cpE = canvas.addPages([e], centredOn: CGPoint(x: 0 * grid, y: 2 * grid))[0]
        let cpF = canvas.addPages([f], centredOn: CGPoint(x: 1 * grid, y: 2 * grid))[0]
        let cpG = canvas.addPages([g], centredOn: CGPoint(x: 1 * grid, y: 3 * grid))[0]
        let cpH = canvas.addPages([h], centredOn: CGPoint(x: 0 * grid, y: 3 * grid))[0]
        canvas.addLink(between: cpE, and: cpF)
        canvas.addLink(between: cpF, and: cpG)
        canvas.addLink(between: cpG, and: cpH)
        canvas.addLink(between: cpH, and: cpE)

        let cpI = canvas.addPages([i], centredOn: CGPoint(x: 0 * grid, y: 4 * grid))[0]
        let cpJ = canvas.addPages([j], centredOn: CGPoint(x: 1 * grid, y: 4 * grid))[0]
        let cpK = canvas.addPages([k], centredOn: CGPoint(x: 2 * grid, y: 4 * grid))[0]
        let cpL = canvas.addPages([l], centredOn: CGPoint(x: 2 * grid, y: 5 * grid))[0]
        let cpM = canvas.addPages([m], centredOn: CGPoint(x: 3 * grid, y: 4 * grid))[0]
        let cpN = canvas.addPages([n], centredOn: CGPoint(x: 3 * grid, y: 5 * grid))[0]
        canvas.addLink(between: cpI, and: cpJ)
        canvas.addLink(between: cpJ, and: cpK)
        canvas.addLink(between: cpJ, and: cpL)
        canvas.addLink(between: cpK, and: cpM)
        canvas.addLink(between: cpL, and: cpN)
        canvas.addLink(between: cpN, and: cpM)

        let cpO = canvas.addPages([o], centredOn: CGPoint(x: 4 * grid, y: 0 * grid))[0]
        let cpP = canvas.addPages([p], centredOn: CGPoint(x: 5 * grid, y: 0 * grid))[0]
        let cpQ = canvas.addPages([q], centredOn: CGPoint(x: 6 * grid, y: 0 * grid))[0]
        let cpR = canvas.addPages([r], centredOn: CGPoint(x: 5 * grid, y: 1 * grid))[0]
        let cpS = canvas.addPages([s], centredOn: CGPoint(x: 6 * grid, y: 1 * grid))[0]
        canvas.addLink(between: cpO, and: cpP)
        canvas.addLink(between: cpP, and: cpQ)
        canvas.addLink(between: cpP, and: cpS)
        canvas.addLink(between: cpR, and: cpS)

        let cpT = canvas.addPages([t], centredOn: CGPoint(x: 5 * grid, y: 2 * grid))[0]
        let cpU = canvas.addPages([u], centredOn: CGPoint(x: 6 * grid, y: 2 * grid))[0]
        let cpV = canvas.addPages([v], centredOn: CGPoint(x: 5 * grid, y: 3 * grid))[0]
        let cpW = canvas.addPages([w], centredOn: CGPoint(x: 6 * grid, y: 3 * grid))[0]
        canvas.addLink(between: cpT, and: cpU)
        canvas.addLink(between: cpU, and: cpV)
        canvas.addLink(between: cpV, and: cpT)
        canvas.addLink(between: cpU, and: cpW)

        print("links: \(canvas.links)")
    }
}
