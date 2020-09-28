//
//  MultipleSubscriptionsViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 28/09/2020.
//  Copyright © 2020 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Subscriptions

class MultipleSubscriptionsViewController: NSViewController {
    typealias Completion = (M3Subscriptions.Subscription?) -> Void

    let subscriptions: [M3Subscriptions.Subscription]
    let completion: Completion
    init(subscriptions: [M3Subscriptions.Subscription], completion: @escaping Completion) {
        self.subscriptions = subscriptions
        self.completion = completion
        super.init(nibName: "MultipleSubscriptionsView", bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.reloadData()
    }

    @IBOutlet var activateButton: NSButton!
    @IBOutlet var tableView: NSTableView!

    @IBAction func activate(_ sender: Any) {
        self.completion(self.selectedSubscription)
        self.presentingViewController?.dismiss(self)
    }

    @IBAction func cancel(_ sender: Any) {
        self.completion(nil)
        self.presentingViewController?.dismiss(self)
    }

    var selectedSubscription: M3Subscriptions.Subscription? {
        didSet {
            self.reloadData()
        }
    }

    private func reloadData() {
        self.tableView.reloadData()
        self.activateButton.isEnabled = (self.selectedSubscription != nil)
    }
}

extension MultipleSubscriptionsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.subscriptions.count
    }

}

extension MultipleSubscriptionsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cell = tableView.makeView(of: SubscriptionTableCellView.self) else {
            return nil
        }
        let subscription = self.subscriptions[row]
        cell.subscription = subscription
        cell.delegate = self
        cell.radioButton.state = (subscription == self.selectedSubscription) ? .on : .off
        return cell
    }
}


extension MultipleSubscriptionsViewController: SubscriptionTableCellViewDelegate {
    func didSelect(_ tableCell: SubscriptionTableCellView) {
        self.selectedSubscription = tableCell.subscription
    }


}
