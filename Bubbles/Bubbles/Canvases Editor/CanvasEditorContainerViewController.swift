//
//  CanvasesViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/03/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class CanvasesViewController: NSSplitViewController {
    let viewModel: CanvasesViewModel
    init(viewModel: CanvasesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "CanvasEditorContainerView", bundle: nil)
        viewModel.view = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var canvasListViewController: CanvasListViewController = {
        let viewModel = CanvasListViewModel(documentWindowViewModel: self.viewModel.documentWindowViewModel)
        return CanvasListViewController(viewModel: viewModel)
    }()

    let noCanvasViewController = NoCanvasViewController()

    var enabled: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()

        self.updateSplitViewItems()
    }

    override func viewDidAppear() {
        super.viewDidAppear()
        self.viewModel.startObserving()
    }

    override func viewDidDisappear() {
        super.viewDidDisappear()
        self.viewModel.stopObserving()
    }


    private func updateSplitViewItems() {
        var splitViewItems = [NSSplitViewItem]()
        if self.viewModel.showCanvasList {
            splitViewItems.append(self.canvasListViewController.splitViewItem)
        }

        if let canvasEditor = self.currentCanvasEditor {
            splitViewItems.append(canvasEditor.splitViewItem)
        } else {
            splitViewItems.append(self.noCanvasViewController.splitViewItem)
        }

        self.splitViewItems = splitViewItems
        self.inspectorsDidChange()
    }

    var currentCanvasEditor: CanvasEditorViewController? {
        didSet {
            self.updateSplitViewItems()
        }
    }

    private func updateCanvasEditor() {
        guard let canvas = self.viewModel.currentCanvas else {
            self.currentCanvasEditor = nil
            return
        }
        guard self.currentCanvasEditor?.viewModel.canvas != canvas else {
            return
        }
        self.currentCanvasEditor = canvas.createEditor(with: self.viewModel.documentWindowViewModel) as? CanvasEditorViewController
    }


    var isSidebarCompact: Bool {
        get { UserDefaults.standard.bool(forKey: .canvasListIsCompact) }
        set { UserDefaults.standard.set(newValue, forKey: .canvasListIsCompact) }
    }


    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if self.canvasListViewController.responds(to: action) {
            return self.canvasListViewController
        }
        if let editor = self.currentCanvasEditor, editor.responds(to: action) {
            return editor
        }
        return super.supplementalTarget(forAction: action, sender: sender)
    }

    //MARK: - SplitViewDelegate
    override func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        //If we're getting smaller than the minimum regular size we want to see if we want to switch to compact
        if proposedPosition < CanvasListViewController.regularMinimumSize {
            //We switch to compact if we're over half way towards compact sized
            let crossOverPoint = (CanvasListViewController.regularMinimumSize + CanvasListViewController.compactSize) / 2
            self.isSidebarCompact = (proposedPosition < crossOverPoint)
            return self.canvasListViewController.splitViewItem.minimumThickness
        }
        return proposedPosition
    }
}


extension CanvasesViewController: CanvasesView {
    func currentCanvasChanged() {
        self.updateCanvasEditor()
    }

    func canvasListStateChanged() {
        self.updateSplitViewItems()
    }
}


extension CanvasesViewController: Editor {
    var inspectors: [Inspector] {
        return self.currentCanvasEditor?.inspectors ?? []
    }
}

