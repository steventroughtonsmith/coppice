//
//  HelpContentViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 23/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa

class HelpContentViewController: NSViewController {
    let helpBook: HelpBook
    init(helpBook: HelpBook) {
        self.helpBook = helpBook
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView()
    }


    //MARK: - Content
    private var currentViewController: NSViewController? {
        didSet {
            guard self.currentViewController != oldValue else {
                return
            }

            oldValue?.removeFromParent()
            oldValue?.view.removeFromSuperview()

            if let newValue = self.currentViewController {
                self.addChild(newValue)
                self.view.addSubview(newValue.view, withInsets: NSEdgeInsetsZero)
            }
        }
    }

    lazy var helpTopicViewController = HelpTopicViewController()

    func show(_ item: NavigationStack.NavigationItem?) {
        guard let item = item else {
            self.currentViewController = nil
            return
        }
        
        switch item {
        case .topic(let topic):
            self.helpTopicViewController.topic = topic
            self.helpTopicViewController.delegate = self.windowController as? HelpTopicViewControllerDelegate
            self.currentViewController = self.helpTopicViewController
        case .search(let search):
            let controller = HelpSearchResultsViewController(topics: self.helpBook.topics(matchingSearchString: search))
            controller.delegate = self.windowController as? HelpSearchResultsViewControllerDelegate
            self.currentViewController = controller
        }
    }
}

