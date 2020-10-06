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

    var currentContentEditor: (PageContentEditor & NSViewController)? {
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

    @IBAction func linkToPage(_ sender: Any?) {
        if (!HelpTipPresenter.shared.showTip(with: .textPageLink, fromToolbarItemWithIdentifier: .linkToPage)) {
            HelpTipPresenter.shared.showTip(with: .textPageLink, fromView: self.view, preferredEdge: .maxX)
        }
    }


    /// Start an editing action with a certain point
    /// - Parameter point: The point in the coordinates of this view controller
    func startEditing(at point: CGPoint) {
        self.currentContentEditor?.startEditing(at: point)
    }

    func stopEditing() {
        self.currentContentEditor?.stopEditing()
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
