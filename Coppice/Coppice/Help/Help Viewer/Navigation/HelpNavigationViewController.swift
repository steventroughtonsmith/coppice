//
//  HelpNavigationViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/10/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

protocol HelpNavigationViewControllerDelegate: AnyObject {
    func didSelect(_ topic: HelpBook.Topic, in helpNavigationViewController: HelpNavigationViewController)
}

class HelpNavigationViewController: NSViewController {
    weak var delegate: HelpNavigationViewControllerDelegate?

    let helpBook: HelpBook
    init(helpBook: HelpBook) {
        self.helpBook = helpBook
        super.init(nibName: "HelpNavigationViewController", bundle: nil)
        self.setupNavigationNodes()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @IBOutlet var outlineView: NSOutlineView!
    override func viewDidLoad() {
        super.viewDidLoad()

        for item in self.rootNodes {
        	self.outlineView.expandItem(item, expandChildren: true)
        }
    }

    private var rootNodes: [NavigationNode] = []
    private var allNodes: [NavigationNode] = []

    private func setupNavigationNodes() {
        var rootNodes = [NavigationNode]()
        var allNodes = [NavigationNode]()
        for group in self.helpBook.allGroups {
            let topicItems = group.topicIDs
                .compactMap { self.helpBook.topic(withID: $0) }
                .map { NavigationNode(item: .topic($0)) }
            allNodes.append(contentsOf: topicItems)

            let groupNode = NavigationNode(item: .group(group), children: topicItems)
            allNodes.append(groupNode)
            rootNodes.append(groupNode)
        }

        self.rootNodes = rootNodes
        self.allNodes = allNodes
    }

    private var isSelecting = false
    func select(_ topic: HelpBook.Topic) {
        guard let node = self.allNodes.first(where: { $0.item == .topic(topic) }) else {
            return
        }

        self.isSelecting = true
        let row = self.outlineView.row(forItem: node)
        self.outlineView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
        self.isSelecting = false
    }
}


extension HelpNavigationViewController: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        guard let item = item else {
            return self.rootNodes.count
        }

        guard let navigationItem = item as? NavigationNode else {
            preconditionFailure("All outline view items should be NavigationItems")
        }

        return navigationItem.children.count
    }

    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        guard let item = item else {
            return self.rootNodes[index]
        }

        guard let node = item as? NavigationNode else {
            preconditionFailure("All outline view items should be NavigationItems")
        }

        return node.children[index]
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? NavigationNode else {
            preconditionFailure("All outline view items should be NavigationItems")
        }
        return (node.children.count > 0)
    }

    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
        return item
    }
}

extension HelpNavigationViewController: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let node = item as? NavigationNode else {
            return nil
        }
        if node.item.isGroup {
            return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self)
        }
        return outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self)
    }

    func outlineView(_ outlineView: NSOutlineView, isGroupItem item: Any) -> Bool {
        guard let navigationNode = item as? NavigationNode else {
            preconditionFailure("All outline view items should be NavigationItems")
        }
        return navigationNode.item.isGroup
    }

    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        guard let node = item as? NavigationNode else {
            return false
        }
        return (node.item.isGroup == false)
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        guard
            (self.isSelecting == false),
            (self.outlineView.selectedRow != -1),
            let node = self.outlineView.item(atRow: self.outlineView.selectedRow) as? NavigationNode,
            case .topic(let topic) = node.item
        else {
            return
        }

        self.delegate?.didSelect(topic, in: self)
    }
}



extension HelpNavigationViewController {
    enum NavigationItem: Equatable {
        case group(HelpBook.Group)
        case topic(HelpBook.Topic)

        var title: String {
            switch self {
            case .group(let group):     return group.title
            case .topic(let topic):     return topic.title
            }
        }

        var isGroup: Bool {
            switch self {
            case .group(_): return true
            default: return false
            }
        }
    }

    class NavigationNode {
        let item: NavigationItem
        let children: [NavigationNode]

        init(item: NavigationItem, children: [NavigationNode] = []) {
            self.item = item
            self.children = children
        }
    }
}
