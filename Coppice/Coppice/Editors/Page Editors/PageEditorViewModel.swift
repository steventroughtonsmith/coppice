//
//  PageEditorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 11/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

protocol PageEditorView: AnyObject {
    func contentChanged()
}

class PageEditorViewModel: ViewModel {
    weak var view: PageEditorView?

    let page: Page
    let viewMode: PageContentEditorViewMode
    private var contentObserver: NSObjectProtocol?
    init(page: Page, viewMode: PageContentEditorViewMode, documentWindowViewModel: DocumentWindowViewModel) {
        self.page = page
        self.viewMode = viewMode
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    override func setup() {
        //TODO: Do we need to remove this?
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
            let viewModel = TextEditorViewModel(textContent: (self.page.content as! Page.Content.Text),
                                                viewMode: self.viewMode,
                                                documentWindowViewModel: self.documentWindowViewModel,
                                                pageLinkManager: self.documentWindowViewModel.pageLinkController.pageLinkManager(for: self.page) as? TextPageLinkManager)
            return TextEditorViewController(viewModel: viewModel)
        case .image:
            let viewModel = ImageEditorViewModel(imageContent: (self.page.content as! Page.Content.Image),
                                                 viewMode: self.viewMode,
                                                 documentWindowViewModel: self.documentWindowViewModel,
                                                 pageLinkManager: self.documentWindowViewModel.pageLinkController.pageLinkManager(for: self.page) as? ImagePageLinkManager)
            return ImageEditorViewController(viewModel: viewModel)
        }
    }


    var pageInspectorViewModel: PageInspectorViewModel {
        return PageInspectorViewModel(page: self.page, modelController: self.modelController)
    }
}
