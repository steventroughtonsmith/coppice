//
//  DebugCanvasEditorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine
import CoppiceCore
import M3Data

protocol DebugCanvasEditorView: AnyObject {
    func reloadPage(_ page: CanvasPage)
}

class DebugCanvasEditorViewModel: NSObject {
    weak var view: DebugCanvasEditorView?

    @objc dynamic let canvas: Canvas
    let modelController: CoppiceModelController
    init(canvas: Canvas, modelController: CoppiceModelController) {
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
            .sorted(by: { $0.id.uuid.uuidString < $1.id.uuid.uuidString })
            .map { DebugCanvasPageItem(canvasPage: $0) }
    }

    var selectedCanvasPage: DebugCanvasPageItem?

    func addPageWithID(_ pageID: ModelID) {
        guard let page = self.modelController.collection(for: Page.self).objectWithID(pageID) else {
            return
        }
        self.modelController.collection(for: CanvasPage.self).newObject() { canvasPage in
            canvasPage.page = page
            canvasPage.canvas = self.canvas
        }
    }

    func removeSelected() {}


    //MARK: - Observation
    func startObservingChanges() {
        self.subscribers[.canvasPage] = self.modelController.canvasPageCollection.changePublisher.sink { [weak self] change in
            self?.view?.reloadPage(change.object)
        }
    }

    func stopObservingChanges() {
        self.subscribers = [:]
    }


    //MARK: - Subscribers
    private enum SubscriberKey {
        case canvasPage
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}
