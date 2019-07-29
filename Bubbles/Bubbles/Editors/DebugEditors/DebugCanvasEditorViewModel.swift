//
//  DebugCanvasEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol DebugCanvasEditorView: class {
    func reloadPage(_ page: CanvasPage)
}

class DebugCanvasEditorViewModel: NSObject {
    weak var view: DebugCanvasEditorView?

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

    @objc dynamic var pages: [CanvasPage] {
        return self.sortedCanvases
    }

    @objc dynamic var selectedCanvasPage: CanvasPage?

    func addPageWithID(_ pageID: UUID) {
        guard let page = self.modelController.pages.objectWithID(pageID) else {
            return
        }
        let canvasPage = self.modelController.canvasPages.newObject()
        canvasPage.page = page
        canvasPage.canvas = self.canvas
    }

    func removeSelected() {

    }

    //MARK: - Observation

    private var observation: ModelCollectionObservation<CanvasPage>?
    func startObservingChanges() {
        self.observation = self.modelController.canvasPages.addObserver { [weak self] (page) in
            self?.view?.reloadPage(page)
        }
    }

    func stopObservingChanges() {
        if let observation = self.observation {
            self.modelController.canvasPages.removeObserver(observation)
        }
    }
}
