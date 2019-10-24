//
//  PageEditorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 11/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol PageEditorView: class {
    func contentChanged()
}

class PageEditorViewModel: NSObject {
    weak var view: PageEditorView?
    
    let page: Page
    let modelController: ModelController
    private var contentObserver: NSObjectProtocol?
    init(page: Page, modelController: ModelController) {
        self.page = page
        self.modelController = modelController
        super.init()

        self.contentObserver = NotificationCenter.default.addObserver(forName: Page.contentChangedNotification, object: self.page, queue: .main) { [weak self] (_) in
            self?.view?.contentChanged()
        }
    }

    deinit {
        if let observer = self.contentObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var contentEditor: NSViewController {
        switch self.page.content.contentType {
        case .empty:
            let viewModel = ContentSelectorViewModel(page: self.page, modelController: self.modelController)
            viewModel.delegate = self
            return ContentSelectorViewController(viewModel: viewModel)
        case .text:
            let viewModel = TextEditorViewModel(textContent: (self.page.content as! TextPageContent),
                                                modelController: self.modelController)
            return TextEditorViewController(viewModel: viewModel)
        case .image:
            let viewModel = ImageEditorViewModel(imageContent: (self.page.content as! ImagePageContent),
                                                 modelController: self.modelController)
            return ImageEditorViewController(viewModel: viewModel)
        }
    }
}


extension PageEditorViewModel: ContentSelectorViewModelDelegate {
    func selectedType(in viewModel: ContentSelectorViewModel) {
        self.view?.contentChanged()
    }
}
