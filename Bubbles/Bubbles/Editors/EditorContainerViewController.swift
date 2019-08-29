//
//  EditorContainerViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class EditorContainerViewController: NSViewController {
    let viewModel: EditorContainerViewModel
    init(viewModel: EditorContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "EditorContainerViewController", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }



    private(set) var currentEditor: NSViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()
            if let newEditor = self.currentEditor {
                self.addChild(newEditor)
                self.view.addSubview(newEditor.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }
}

extension EditorContainerViewController: EditorContainerView {
    func editorChanged() {
        self.currentEditor = self.viewModel.editor
    }
}
