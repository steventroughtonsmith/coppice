//
//  RootSplitViewController.swift
//  Bubbles
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit


class RootSplitViewController: NSSplitViewController {
    let sidebarViewController: SidebarViewController
    let editorContainerViewController: EditorContainerViewController
    let inspectorContainerViewController: InspectorContainerViewController


    //MARK: - Initialisation
    init(sidebarViewController: SidebarViewController,
         canvasListViewController: CanvasListViewController,
         editorContainerViewController: EditorContainerViewController,
         inspectorContainerViewController: InspectorContainerViewController)
    {
        self.sidebarViewController = sidebarViewController
        self.editorContainerViewController = editorContainerViewController
        self.inspectorContainerViewController = inspectorContainerViewController
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    //MARK: - SplitView Items
    override func viewDidLoad() {
        super.viewDidLoad()
        self.splitViewItems = [
            self.sidebarViewController.splitViewItem,
            self.editorContainerViewController.splitViewItem,
            self.inspectorContainerViewController.splitViewItem,
        ]

        NotificationCenter.default.addObserver(self, selector: #selector(willStartDrag(_:)), name: .nestableSplitViewWillStartDrag, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didEndDrag(_:)), name: .nestableSplitViewDidEndDrag, object: nil)
    }

    @objc func willStartDrag(_ notification: Notification) {
        guard let splitView = notification.object as? NSSplitView, splitView != self.splitView else {
            return
        }
        self.sidebarViewController.splitViewItem.holdingPriority = .init(490)
        self.inspectorContainerViewController.splitViewItem.holdingPriority = .init(490)
    }

    @objc func didEndDrag(_ notification: Notification) {
        guard let splitView = notification.object as? NSSplitView, splitView != self.splitView else {
            return
        }
        self.sidebarViewController.splitViewItem.holdingPriority = .init(260)
        self.inspectorContainerViewController.splitViewItem.holdingPriority = .init(260)
    }
}


class EditorSplitViewController: NSSplitViewController {
    let canvasListViewController: CanvasListViewController
    let editorContainerViewController: EditorContainerViewController


    //MARK: - Initialisation
    init(canvasListViewController: CanvasListViewController, editorContainerViewController: EditorContainerViewController) {
        self.canvasListViewController = canvasListViewController
        self.editorContainerViewController = editorContainerViewController
        super.init(nibName: nil, bundle: nil)

        let splitView = NestableSplitView()
        splitView.arrangesAllSubviews = false
        splitView.isVertical = true
        splitView.dividerStyle = .thin
        self.splitView = splitView
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var nestableSplitView: NestableSplitView {
        return self.splitView as! NestableSplitView
    }

    override func viewDidLoad() {
        self.splitViewItems = [
            self.canvasListViewController.splitViewItem,
            self.editorContainerViewController.splitViewItem,
        ]
        super.viewDidLoad()
    }

    override func splitView(_ splitView: NSSplitView, constrainSplitPosition proposedPosition: CGFloat, ofSubviewAt dividerIndex: Int) -> CGFloat {
        //If we're getting smaller than the minimum regular size we want to see if we want to switch to compact
        if proposedPosition < CanvasListViewController.regularMinimumSize {
            //We switch to compact if we're over half way towards compact sized
            let crossOverPoint = (CanvasListViewController.regularMinimumSize + CanvasListViewController.compactSize) / 2
            self.canvasListViewController.isCompact = (proposedPosition < crossOverPoint)
            return self.canvasListViewController.splitViewItem.minimumThickness
        }
        return proposedPosition
    }


}
