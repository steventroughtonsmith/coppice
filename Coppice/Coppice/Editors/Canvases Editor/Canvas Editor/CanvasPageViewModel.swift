//
//  CanvasPageViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 21/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation
import CoppiceCore

protocol CanvasPageView: class {
}

class CanvasPageViewModel: ViewModel {
    weak var view: CanvasPageView?

    @objc dynamic let canvasPage: CanvasPage
    init(canvasPage: CanvasPage, documentWindowViewModel: DocumentWindowViewModel) {
        self.canvasPage = canvasPage
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(title)) {
            keyPaths.insert("self.canvasPage.title")
        }
        if (key == #keyPath(accessibilityDescription)) {
            keyPaths.insert("self.canvasPage.parent.title")
        }
        return keyPaths
    }

    @objc dynamic var title: String {
        get { return self.canvasPage.title }
        set { self.canvasPage.page?.title = newValue }
    }


    lazy var pageEditor: PageEditorViewController? = {
        guard let page = self.canvasPage.page else {
            return nil
        }

        let viewModel = PageEditorViewModel(page: page, documentWindowViewModel: self.documentWindowViewModel)
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

        if let parentTitle = self.canvasPage.parent?.title {
            let localizedLinkedTitle = NSLocalizedString("Linked from %@", comment: "Canvas Page 'Linked From {Parent}' Accessibility Description")
            let title = String(format: localizedLinkedTitle, (parentTitle.count > 0) ? parentTitle : Page.localizedDefaultTitle)
            description.append("\(title). ")
        }

        return (description.count > 0) ? description : nil
    }
}

