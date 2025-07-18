//
//  SidebarViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 02/04/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class SidebarViewController: NSViewController, SplitViewContainable {
    let viewModel: SidebarViewModel
    init(viewModel: SidebarViewModel) {
        self.viewModel = viewModel
        super.init(nibName: "SidebarView", bundle: nil)
        self.viewModel.view = self
    }

    required init?(coder: NSCoder) {
        preconditionFailure("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        self.viewModel.updateSidebar()
    }

    func performNewDocumentSetup() {
        self.sourceListViewController.performNewDocumentSetup()
    }


    //MARK: - RootViewController

    func createSplitViewItem() -> NSSplitViewItem {
        let item = NSSplitViewItem(sidebarWithViewController: self)
        item.maximumThickness = 650 //Just what seems reasonable, as the default is "as big as you want"
        item.minimumThickness = 155
        return item
    }


    //MARK: - Sidebars
    lazy var sourceListViewController: SourceListViewController = {
        return SourceListViewController(viewModel: .init(documentWindowViewModel: self.viewModel.documentWindowViewModel))
    }()

    lazy var searchResultsViewController: SearchResultsViewController = {
        return SearchResultsViewController(viewModel: .init(documentWindowViewModel: self.viewModel.documentWindowViewModel))
    }()


    //MARK: - Current View Controller
    var currentSidebarViewController: NSViewController? {
        didSet {
            guard oldValue != self.currentSidebarViewController else {
                return
            }

            oldValue?.removeFromParent()
            oldValue?.view.removeFromSuperview()

            if let newValue = self.currentSidebarViewController {
                self.addChild(newValue)
                self.view.addSubview(newValue.view, withInsets: NSEdgeInsetsZero)
            }
            self.view.window?.recalculateKeyViewLoop()
        }
    }

    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if (self.sourceListViewController.responds(to: action)) {
            return self.sourceListViewController
        }
        return super.supplementalTarget(forAction: action, sender: sender)
    }
}


extension SidebarViewController: SidebarView {
    func displaySourceList() {
        self.currentSidebarViewController = self.sourceListViewController
    }

    func displaySearchResults(forSearchString searchString: String) {
        self.currentSidebarViewController = self.searchResultsViewController
        self.searchResultsViewController.viewModel.searchString = searchString
    }
}
