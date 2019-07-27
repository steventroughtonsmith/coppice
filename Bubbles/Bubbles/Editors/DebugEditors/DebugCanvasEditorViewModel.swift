//
//  DebugCanvasEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class DebugCanvasEditorViewModel: NSObject {
    let canvas: Canvas
    let modelController: ModelController
    init(canvas: Canvas, modelController: ModelController) {
        self.canvas = canvas
        self.modelController = modelController
        super.init()
    }

    private var sortedCanvases: [CanvasPage] {
        return self.canvas.pages.sorted(by: {$0.id.uuidString < $1.id.uuidString})
    }

    @objc var pages: [CanvasPage] {
        return self.sortedCanvases
    }

    @objc var selectedCanvasPage: CanvasPage?

    func addPageWithID(_ pageID: UUID) {
        guard let page = self.modelController.pageWithID(pageID) else {
            return
        }
        let canvasPage = CanvasPage()
        canvasPage.page = page
        page.canvases.insert(canvasPage)

        canvasPage.canvas = self.canvas
        self.canvas.pages.insert(canvasPage)
    }

    func removeSelected() {

    }
}
