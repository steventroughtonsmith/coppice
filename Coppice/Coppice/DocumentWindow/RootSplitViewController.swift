//
//  RootSplitViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit


class RootSplitViewController: NSSplitViewController {
    let sidebarViewController: SidebarViewController
    let editorContainerViewController: EditorContainerViewController
    let inspectorContainerViewController: InspectorContainerViewController

    var toolbarControl: NSSegmentedControl? {
        didSet {
            self.toolbarControl?.target = self
            self.toolbarControl?.action = #selector(toolbarControlChanged(_:))
        }
    }


    //MARK: - Initialisation
    init(sidebarViewController: SidebarViewController,
         canvasListViewController: CanvasListViewController,
         editorContainerViewController: EditorContainerViewController,
         inspectorContainerViewController: InspectorContainerViewController)
    {
        self.sidebarViewController = sidebarViewController
        self.editorContainerViewController = editorContainerViewController
        self.inspectorContainerViewController = inspectorContainerViewController
        super.init(nibName: "RootSplitViewController", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    //MARK: - SplitView Items
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewItems = [
            self.sidebarViewController.createSplitViewItem(),
            self.editorContainerViewController.createSplitViewItem(),
            self.inspectorContainerViewController.createSplitViewItem(),
        ]

        NotificationCenter.default.addObserver(self, selector: #selector(willStartDrag(_:)), name: .nestableSplitViewWillStartDrag, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEndDrag(_:)), name: .nestableSplitViewDidEndDrag, object: nil)
    }

    @objc func willStartDrag(_ notification: Notification) {
        guard let splitView = notification.object as? NSSplitView, splitView != self.splitView else {
            return
        }
        self.splitViewItem(for: self.sidebarViewController)?.holdingPriority = .init(490)
        self.splitViewItem(for: self.inspectorContainerViewController)?.holdingPriority = .init(490)
    }

    @objc func didEndDrag(_ notification: Notification) {
        guard let splitView = notification.object as? NSSplitView, splitView != self.splitView else {
            return
        }
        self.splitViewItem(for: self.sidebarViewController)?.holdingPriority = .init(260)
        self.splitViewItem(for: self.inspectorContainerViewController)?.holdingPriority = .init(260)
    }


    //MARK: - ToolbarControl
    @IBAction func toolbarControlChanged(_ sender: Any) {
        guard let toolbarControl = self.toolbarControl else {
            return
        }
        self.splitViewItem(for: self.sidebarViewController)?.isCollapsed = !toolbarControl.isSelected(forSegment: 0)
        self.splitViewItem(for: self.inspectorContainerViewController)?.isCollapsed = !toolbarControl.isSelected(forSegment: 1)
    }

    private func updateSplitViewControl() {
        self.toolbarControl?.setSelected(!(self.splitViewItem(for: self.sidebarViewController)?.isCollapsed ?? false), forSegment: 0)
        self.toolbarControl?.setSelected(!(self.splitViewItem(for: self.inspectorContainerViewController)?.isCollapsed ?? false), forSegment: 1)
    }

    override func splitViewDidResizeSubviews(_ notification: Notification) {
        super.splitViewDidResizeSubviews(notification)
        self.updateSplitViewControl()
    }


    //MARK: - Menu Actions
    @IBAction func toggleInspectors(_ sender: Any?) {
        NSView.animate(withDuration: 0.3) {
            self.splitViewItem(for: self.inspectorContainerViewController)?.isCollapsed.toggle()
        }
    }
}
