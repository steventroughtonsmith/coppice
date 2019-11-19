//
//  CanvasPageViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol CanvasPageView: class {
}

class CanvasPageViewModel: NSObject {
    weak var view: CanvasPageView?

    let canvasPage: CanvasPage
    let modelController: ModelController
    let documentWindowState: DocumentWindowState
    init(canvasPage: CanvasPage, modelController: ModelController, documentWindowState: DocumentWindowState) {
        self.canvasPage = canvasPage
        self.modelController = modelController
        self.documentWindowState = documentWindowState
        super.init()
    }

    var title: String {
        var title = self.canvasPage.page?.title ?? "Untitled"
        var currentPage = self.canvasPage.parent
        while currentPage != nil {
            title += " : \(currentPage?.page?.title ?? "Untitled")"
            currentPage = currentPage?.parent
        }
        return title
    }


    lazy var pageEditor: PageEditorViewController? = {
        guard let page = self.canvasPage.page else {
            return nil
        }

        let viewModel = PageEditorViewModel(page: page,
                                            modelController: self.modelController,
                                            documentWindowState: self.documentWindowState)
        return PageEditorViewController(viewModel: viewModel)
    }()

    var canvasPageInspectorViewModel: CanvasPageInspectorViewModel {
        return CanvasPageInspectorViewModel(canvasPage: self.canvasPage, modelController: self.modelController)
    }
}

