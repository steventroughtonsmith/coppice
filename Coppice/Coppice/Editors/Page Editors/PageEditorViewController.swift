//
//  PageEditorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 11/10/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

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
        let view = ColourBackgroundView()
        view.backgroundColour = NSColor.pageEditorBackground
        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.contentChanged()
    }

    var enabled: Bool = true {
        didSet {
            self.currentContentEditor?.enabled = self.enabled
            self.inspectorsDidChange()
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


extension PageEditorViewController: LayoutEnginePageView {
    /// Start an editing action with a certain point
    /// - Parameter point: The point in the coordinates of this view controller
    func startEditing(atContentPoint point: CGPoint) {
        //We need to flip the point from the canvas view
        var flippedPoint = point
        flippedPoint.y = self.view.frame.height - flippedPoint.y
        self.currentContentEditor?.startEditing(at: flippedPoint)
    }

    func stopEditing() {
        self.currentContentEditor?.stopEditing()
    }

    func isLink(atContentPoint point: CGPoint) -> Bool {
        //We need to flip the point from the canvas view
        var flippedPoint = point
        flippedPoint.y = self.view.frame.height - flippedPoint.y
        return self.currentContentEditor?.isLink(at: flippedPoint) ?? false
    }

    func openLink(atContentPoint point: CGPoint) {
        //We need to flip the point from the canvas view
        var flippedPoint = point
        flippedPoint.y = self.view.frame.height - flippedPoint.y
        self.currentContentEditor?.openLink(at: flippedPoint)
    }
}
