//
//  RootSplitViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 20/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

class RootSplitViewController: NSSplitViewController, NSMenuItemValidation {
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
        super.init(nibName: "RootSplitViewController", bundle: nil)

        //We'll add the split items before the view loads ensure they get restored correctly
        self.splitViewItems = [
            self.sidebarViewController.createSplitViewItem(),
            self.editorContainerViewController.createSplitViewItem(),
            self.inspectorContainerViewController.createSplitViewItem(),
        ]
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }


    //MARK: - SplitView Items
    override func viewDidLoad() {
        super.viewDidLoad()


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

    override func splitViewDidResizeSubviews(_ notification: Notification) {
        super.splitViewDidResizeSubviews(notification)
    }


    //MARK: - Menu Actions
    @IBAction func toggleInspectors(_ sender: Any?) {
        NSView.animate(withDuration: 0.3) {
            self.splitViewItem(for: self.inspectorContainerViewController)?.isCollapsed.toggle()
        }
    }

    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if (menuItem.action == #selector(toggleInspectors(_:))) {
            let containerItemIsCollapsed = self.splitViewItem(for: self.inspectorContainerViewController)?.isCollapsed ?? false
            menuItem.title = containerItemIsCollapsed ? NSLocalizedString("Show Inspector", comment: "Show inspector menu item")
                                                      : NSLocalizedString("Hide Inspector", comment: "Hide inspector menu item")
        }
        if (menuItem.action == #selector(toggleSidebar(_:))) {
            let containerItemIsCollapsed = self.splitViewItem(for: self.sidebarViewController)?.isCollapsed ?? false
            menuItem.title = containerItemIsCollapsed ? NSLocalizedString("Show Sidebar", comment: "Show sidebar menu item")
                                                      : NSLocalizedString("Hide Sidebar", comment: "Hide sidebar menu item")
        }
        return true
    }
}
