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

class CanvasPageViewModel: ViewModel {
    weak var view: CanvasPageView?

    @objc dynamic let canvasPage: CanvasPage
    let mode: EditorMode
    init(canvasPage: CanvasPage, documentWindowViewModel: DocumentWindowViewModel, mode: EditorMode = .editing) {
        self.canvasPage = canvasPage
        self.mode = mode
        super.init(documentWindowViewModel: documentWindowViewModel)
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(title)) {
            keyPaths.insert("self.canvasPage.title")
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

        let viewModel = PageEditorViewModel(page: page, documentWindowViewModel: self.documentWindowViewModel, mode: self.mode)
        return PageEditorViewController(viewModel: viewModel)
    }()

    var canvasPageInspectorViewModel: CanvasPageInspectorViewModel {
        return CanvasPageInspectorViewModel(canvasPage: self.canvasPage, modelController: self.modelController)
    }
}

