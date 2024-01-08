//
//  CanvasPageViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Combine
import CoppiceCore
import Foundation

protocol CanvasPageView: AnyObject {}

class CanvasPageViewModel: ViewModel {
    weak var view: CanvasPageView?

    let canvasPage: CanvasPage
    /*
            We need to store the page as well, as when a canvas page is closed its page is set to nil.
            This prevents any observation from being able to be correctly removed
         */
    let page: Page?
    init(canvasPage: CanvasPage, documentWindowViewModel: DocumentWindowViewModel) {
        self.canvasPage = canvasPage
        self.page = canvasPage.page
        super.init(documentWindowViewModel: documentWindowViewModel)
        self.subscribers[.pageTitle] = canvasPage.page?.changePublisher(for: \.title)?.sink { [weak self] _ in
            self?.notifyOfChange(to: \.title)
            self?.notifyOfChange(to: \.accessibilityDescription)
        }
    }

    @objc dynamic var title: String {
        get { return self.canvasPage.title }
        set { self.page?.title = newValue }
    }


    lazy var pageEditor: PageEditorViewController? = {
        guard let page = self.page else {
            return nil
        }

        let viewModel = PageEditorViewModel(page: page, viewMode: .canvas, documentWindowViewModel: self.documentWindowViewModel)
        return PageEditorViewController(viewModel: viewModel)
    }()

    var canvasPageInspectorViewModel: CanvasPageInspectorViewModel {
        return CanvasPageInspectorViewModel(canvasPage: self.canvasPage, modelController: self.modelController)
    }

    @objc dynamic var accessibilityDescription: String? {
        var description = ""
        if let contentType = self.canvasPage.page?.content.contentType {
            description.append("\(contentType.localizedName). ")
        }

        let linksIn = self.canvasPage.linksIn
        if linksIn.count == 1, let parentTitle = linksIn.first?.sourcePage?.title {
            let localizedLinkedTitle = NSLocalizedString("Linked from %@", comment: "Canvas Page 'Linked From {Parent}' Accessibility Description")
            let title = String(format: localizedLinkedTitle, (parentTitle.count > 0) ? parentTitle : Page.localizedDefaultTitle)
            description.append("\(title). ")
        } else if linksIn.count > 1 {
            let localizedLinkedTitle = NSLocalizedString("Linked from %ld pages", comment: "Canvas Page 'Linked From {Number} pages' Accessibility Description")
            let title = String(format: localizedLinkedTitle, linksIn.count)
            description.append("\(title). ")
        }

        return (description.count > 0) ? description : nil
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case pageTitle
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]
}

