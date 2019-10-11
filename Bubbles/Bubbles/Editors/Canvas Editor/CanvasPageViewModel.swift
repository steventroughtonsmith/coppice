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
    init(canvasPage: CanvasPage, modelController: ModelController) {
        self.canvasPage = canvasPage
        self.modelController = modelController
        super.init()
    }


    lazy var pageEditor: PageEditorViewController? = {
        guard let page = self.canvasPage.page else {
            return nil
        }

        let viewModel = PageEditorViewModel(page: page, modelController: self.modelController)
        return PageEditorViewController(viewModel: viewModel)
    }()
}

