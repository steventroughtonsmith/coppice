//
//  PageEditorViewController.swift
//  Coppice
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
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentChanged()
    }

    var enabled: Bool = true {
        didSet {
            self.currentContentEditor?.enabled = self.enabled
        }
    }

    var currentContentEditor: (Editor & NSViewController)? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()

            if let editor = self.currentContentEditor {
                self.view.addSubview(editor.view, withInsets: NSEdgeInsetsZero)
                editor.enabled = self.enabled
                self.addChild(editor)
            }
            self.inspectorsDidChange()
        }
    }

    private lazy var pageInspectorViewController: PageInspectorViewController = {
        return PageInspectorViewController(viewModel: self.viewModel.pageInspectorViewModel)
    }()

    var isInCanvas: Bool {
        return (self.parentEditor is CanvasPageViewController)
    }
}


extension PageEditorViewController: Editor {
    var inspectors: [Inspector] {
        let contentInspectors = self.currentContentEditor?.inspectors ?? []
        return contentInspectors + [self.pageInspectorViewController]
    }
}


extension PageEditorViewController: PageEditorView {
    func contentChanged() {
        self.currentContentEditor = self.viewModel.contentEditor
    }
}
