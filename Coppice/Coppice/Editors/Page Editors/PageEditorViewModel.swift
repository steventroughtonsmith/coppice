//
//  PageEditorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 11/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

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

    var contentEditor: (PageContentEditor & NSViewController) {
        switch self.page.content.contentType {
        case .text:
            let viewModel = TextEditorViewModel(textContent: (self.page.content as! TextPageContent),
                                                documentWindowViewModel: self.documentWindowViewModel,
                                                pageLinkManager: self.documentWindowViewModel.pageLinkController.pageLinkManager(for: self.page))
            return TextEditorViewController(viewModel: viewModel)
        case .image:
            let viewModel = ImageEditorViewModel(imageContent: (self.page.content as! ImagePageContent),
                                                 documentWindowViewModel: self.documentWindowViewModel )
            return ImageEditorViewController(viewModel: viewModel)
        }
    }


    var pageInspectorViewModel: PageInspectorViewModel {
        return PageInspectorViewModel(page: self.page, modelController: self.modelController)
    }
}
