//
//  PageEditorViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 11/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

class PageEditorViewController: NSViewController {
    let viewModel: PageEditorViewModel
    init(viewModel: PageEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentChanged()
    }

    var currentContentEditor: NSViewController? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()

            if let editor = self.currentContentEditor {
                self.view.addSubview(editor.view, withInsets: NSEdgeInsetsZero)
                self.addChild(editor)
            }
        }
    }
}


extension PageEditorViewController: Editor {
    var inspector: Any? {
        return nil
    }
}


extension PageEditorViewController: PageEditorView {
    func contentChanged() {
        self.currentContentEditor = self.viewModel.contentEditor
    }
}
