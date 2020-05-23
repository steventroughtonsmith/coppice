//
//  EditorContainerViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa


class EditorContainerViewController: NSViewController, SplitViewContainable {

    let viewModel: EditorContainerViewModel
    init(viewModel: EditorContainerViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "EditorContainerViewController", bundle: nil)
        self.identifier = NSUserInterfaceItemIdentifier(rawValue: "EditorContainer")
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    var enabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
//        self.view.widthAnchor.constraint(greaterThanOrEqualToConstant: 300).isActive = true
    }


    //MARK: - Editor Generation
    private(set) var mainEditor: (Editor & NSViewController)? {
        didSet {
            oldValue?.view.removeFromSuperview()
            oldValue?.removeFromParent()
            if let newEditor = self.mainEditor {
                self.addChild(newEditor)
                self.view.addSubview(newEditor.view, withInsets: NSEdgeInsetsZero)
            }
            self.inspectorsDidChange()
            self.view.window?.recalculateKeyViewLoop()
        }
    }

    func createEditor() -> (Editor & NSViewController)? {
        switch self.viewModel.currentEditor {
        case .canvas:
            return CanvasesViewController(viewModel: .init(documentWindowViewModel: self.viewModel.documentWindowViewModel))
        case .page(let page):
            return page.createEditor(with: self.viewModel.documentWindowViewModel)
        case .none:
            return NoEditorViewController()
        }
    }


    //MARK: - RootViewController
    func createSplitViewItem() -> NSSplitViewItem {
        let item = NSSplitViewItem(viewController: self)
        item.holdingPriority = NSLayoutConstraint.Priority(249)
        item.preferredThicknessFraction = 0.8
        return item
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
        self.viewModel.documentWindowViewModel.openPage(at: page)
    }
}

extension EditorContainerViewController: EditorContainerView {
    func editorChanged() {
        self.mainEditor = self.createEditor()
    }
}
