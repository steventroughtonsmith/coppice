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

    @objc dynamic let canvas: Canvas
    let modelController: ModelController
    init(canvas: Canvas, modelController: ModelController) {
        self.canvas = canvas
        self.modelController = modelController
        super.init()
    }

    @objc dynamic var title: String {
        return self.canvas.title
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "sortIndex" {
            keyPaths.insert("self.canvas.sortIndex")
        }
        return keyPaths
    }

    @objc dynamic var sortIndex: String {
        return "\(self.canvas.sortIndex)"
    }

    var pages: [DebugCanvasPageItem] {
        return self.canvas.pages
            .sorted(by: {$0.id.uuid.uuidString < $1.id.uuid.uuidString})
            .map { DebugCanvasPageItem(canvasPage: $0) }
    }

    var selectedCanvasPage: DebugCanvasPageItem?

    func addPageWithID(_ pageID: ModelID) {
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
