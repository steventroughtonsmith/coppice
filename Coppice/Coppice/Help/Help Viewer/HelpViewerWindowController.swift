//
//  HelpViewerWindowController.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

class HelpViewerWindowController: NSWindowController {
    let helpBook: HelpBook
    init(helpBook: HelpBook) {
        self.helpBook = helpBook
        super.init(window: nil)
        self.setupNavigationObservation()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var windowNibName: NSNib.Name? {
        return "HelpViewerWindowController"
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        self.splitViewController.view.frame.size = CGSize(width: 900, height: 600)

        self.contentViewController = self.splitViewController
        self.setupToolbar()

        self.navigationStack.navigate(to: .home)
    }



    //MARK: - Toolbar
    lazy var toolbarDelegate: HelpViewerToolbarDelegate = {
        return HelpViewerToolbarDelegate(searchField: self.searchField,
                                         splitView: self.splitViewController.splitView)
    }()

    private func setupToolbar() {
        let toolbar = NSToolbar(identifier: "HelpToolbar")
        toolbar.allowsUserCustomization = false
        toolbar.displayMode = .iconOnly
        toolbar.delegate = self.toolbarDelegate
        self.window?.toolbar = toolbar
    }


    //MARK: - View Controllers
    lazy var navigationViewController: HelpNavigationViewController = {
        let controller = HelpNavigationViewController(helpBook: self.helpBook)
        controller.delegate = self
        return controller
    }()

    lazy var helpContentViewController: HelpContentViewController = {
        let controller = HelpContentViewController(helpBook: self.helpBook)
        return controller
    }()

    lazy var splitViewController: NSSplitViewController = {
        let controller = NSSplitViewController()
        let contentSplitItem = NSSplitViewItem(viewController: self.helpContentViewController)
        contentSplitItem.minimumThickness = 500
        controller.splitViewItems = [
            NSSplitViewItem(sidebarWithViewController: self.navigationViewController),
            contentSplitItem,
        ]
        return controller
    }()


    //MARK: - Navigation
    let navigationStack = NavigationStack()

    var navigationObservation: AnyCancellable?
    private func setupNavigationObservation() {
        self.navigationObservation = self.navigationStack.$currentNavigationItem.sink { [weak self] (item) in
            if let item = item, case .topic(let topic) = item {
                self?.navigationViewController.select(topic)
            }
            self?.helpContentViewController.show(item)
        }
    }

    func navigate(to navigationItem: NavigationStack.NavigationItem) {
        if case .search(let search) = navigationItem {
            self.searchField.stringValue = search
        }
        self.navigationStack.navigate(to: navigationItem)
    }

    //MARK: - Actions
    @IBOutlet var searchField: NSSearchField!
    @IBAction func performSearch(_ sender: Any) {
        guard self.searchField.stringValue.count > 0 else {
            self.navigationStack.back(sender)
            return
        }
        self.navigationStack.navigate(to: .search(self.searchField.stringValue))
    }

    @IBAction func toggleSidebar(_ sender: Any?) {
        self.splitViewController.splitViewItem(for: self.navigationViewController)?.isCollapsed.toggle()
    }

    override func supplementalTarget(forAction action: Selector, sender: Any?) -> Any? {
        if (action == #selector(NavigationStack.back(_:)))
            || (action == #selector(NavigationStack.forward(_:))
            || (action == #selector(NavigationStack.home(_:))))
        {
            return self.navigationStack
        }
        return nil
    }
}

extension HelpViewerWindowController: HelpNavigationViewControllerDelegate {
    func didSelect(_ topic: HelpBook.Topic, in helpNavigationViewController: HelpNavigationViewController) {
        self.navigationStack.navigate(to: .topic(topic))
    }
}

extension HelpViewerWindowController: HelpSearchResultsViewControllerDelegate {
    func open(_ topic: HelpBook.Topic, from helpSearchResultsViewController: HelpSearchResultsViewController) {
        self.navigationStack.navigate(to: .topic(topic))
    }
}

extension HelpViewerWindowController: HelpTopicViewControllerDelegate {
    func openTopic(withIdentifier identifier: String, from helpTopicViewController: HelpTopicViewController) {
        if let topic = self.helpBook.topic(withID: identifier) {
            self.navigationStack.navigate(to: .topic(topic))
        }
    }
}
