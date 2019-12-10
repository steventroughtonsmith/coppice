//
//  EditorContainerViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol EditorContainerViewControllerDelegate: class {
    func open(_ page: PageLink, from viewController: EditorContainerViewController)
}

class EditorContainerViewController: NSViewController {
    weak var delegate: EditorContainerViewControllerDelegate?

    let viewModel: EditorContainerViewModel
    init(viewModel: EditorContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "EditorContainerViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var enabled: Bool = true


    private(set) var mainEditor: (Editor & NSViewController)? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()
            if let newEditor = self.mainEditor {
                self.addChild(newEditor)
                self.view.addSubview(newEditor.view, withInsets: NSEdgeInsetsZero)
            }
            self.inspectorsDidChange()
        }
    }


    //MARK: - Editor Generation
    func createEditor() -> (Editor & NSViewController)? {
        if let canvas = self.viewModel.currentObject as? Canvas {
            return canvas.createEditor(with: self.viewModel.documentWindowViewModel)
        }
        if let page = self.viewModel.currentObject as? Page {
            return page.createEditor(with: self.viewModel.documentWindowViewModel)
        }
        return nil
    }
}

extension EditorContainerViewController: Editor {
    var inspectors: [Inspector] {
        return self.mainEditor?.inspectors ?? []
    }

    func inspectorsDidChange() {
        self.viewModel.documentWindowViewModel.currentInspectors = self.inspectors
    }

    func open(_ page: PageLink) {
        self.delegate?.open(page, from: self)
    }
}

extension EditorContainerViewController: EditorContainerView {
    func editorChanged() {
        self.mainEditor = self.createEditor()
    }
}
