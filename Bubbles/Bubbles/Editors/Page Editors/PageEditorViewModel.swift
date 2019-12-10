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

class PageEditorViewModel: ViewModel {
    weak var view: PageEditorView?
    
    let page: Page
    private var contentObserver: NSObjectProtocol?
    init(page: Page, documentWindowViewModel: DocumentWindowViewModel) {
        self.page = page
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    override func setup() {
        self.contentObserver = NotificationCenter.default.addObserver(forName: Page.contentChangedNotification, object: self.page, queue: .main) { [weak self] (_) in
            self?.view?.contentChanged()
        }
    }

    deinit {
        if let observer = self.contentObserver {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    var contentEditor: (Editor & NSViewController) {
        switch self.page.content.contentType {
        case .empty:
            let viewModel = ContentSelectorViewModel(page: self.page, documentWindowViewModel: self.documentWindowViewModel)
            viewModel.delegate = self
            return ContentSelectorViewController(viewModel: viewModel)
        case .text:
            let viewModel = TextEditorViewModel(textContent: (self.page.content as! TextPageContent),
                                                documentWindowViewModel: self.documentWindowViewModel)
            return TextEditorViewController(viewModel: viewModel)
        case .image:
            let viewModel = ImageEditorViewModel(imageContent: (self.page.content as! ImagePageContent),
                                                 documentWindowViewModel: self.documentWindowViewModel)
            return ImageEditorViewController(viewModel: viewModel)
        }
    }


    var pageInspectorViewModel: PageInspectorViewModel {
        return PageInspectorViewModel(page: self.page, modelController: self.modelController)
    }
}


extension PageEditorViewModel: ContentSelectorViewModelDelegate {
    func selectedType(in viewModel: ContentSelectorViewModel) {
        self.view?.contentChanged()
    }
}
