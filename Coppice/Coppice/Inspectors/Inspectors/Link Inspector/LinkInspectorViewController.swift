//
//  LinkInspectorViewController.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/06/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa
import Combine

import CoppiceCore

class LinkInspectorViewController: BaseInspectorViewController {
    override var contentViewNibName: NSNib.Name? {
        return "LinkInspectorContentView"
    }

    override var ranking: InspectorRanking { return .link }

    var typedViewModel: LinkInspectorViewModel {
        return self.viewModel as! LinkInspectorViewModel
    }

    @IBOutlet var linkControl: LinkControl!


    //MARK: - Subscribers
    enum SubscriptionKeys {
        case textValue
        case icon
        case placeholderValue
        case linkControlEnabled
    }

    private var subscribers: [SubscriptionKeys: AnyCancellable] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let linkControl = self.linkControl else {
            return
        }

        self.subscribers[.textValue] = self.typedViewModel.$textValue.assign(to: \.textValue, on: self.linkControl)
        self.subscribers[.icon] = self.typedViewModel.$icon.assign(to: \.icon, on: self.linkControl)
        self.subscribers[.placeholderValue] = self.typedViewModel.$placeholderValue.compactMap { $0 }.assign(to: \.placeholderString, on: self.linkControl)
        self.subscribers[.linkControlEnabled] = self.typedViewModel.$linkFieldEnabled.assign(to: \.isEnabled, on: self.linkControl)

        linkControl.textField.delegate = self

        linkControl.clearButton.target = self
        linkControl.clearButton.action = #selector(self.clearLink(_:))
    }

    private var pageSelector: PageSelectorWindowController?

    @IBAction func clearLink(_ sender: NSButton) {
        self.typedViewModel.clearLink()
    }

    func startEditingLink() {
        self.view.window?.makeFirstResponder(self.linkControl.textField)
    }

    func clearLink() {
        self.typedViewModel.clearLink()
    }
}

extension LinkInspectorViewController: NSSearchFieldDelegate {
    func controlTextDidBeginEditing(_ obj: Notification) {
        let viewModel = PageSelectorViewModel(title: "", documentWindowViewModel: self.typedViewModel.documentWindowViewModel) { result in
            //We may get an actual page back but if the text field is empty then there's no selector, so assume the user wants to remove the link
            guard self.linkControl.textValue.count > 0 else {
                self.typedViewModel.clearLink()
                return
            }

            self.typedViewModel.link(to: result)
        }
        viewModel.allowsExternalLinks = true
        self.pageSelector = PageSelectorWindowController(viewModel: viewModel)
        self.pageSelector?.show(from: self.linkControl, preferredEdge: .minY)
    }

    func controlTextDidChange(_ obj: Notification) {
        guard self.linkControl.textValue.count > 0 else {
            self.pageSelector?.close()
            return
        }
        if self.pageSelector?.window?.isVisible == false {
            self.pageSelector?.show(from: self.linkControl, preferredEdge: .minY)
        }
        self.pageSelector?.viewModel.searchTerm = self.linkControl.textValue
    }

    func controlTextDidEndEditing(_ obj: Notification) {
        self.pageSelector?.close()
        self.pageSelector = nil
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard let pageSelector = self.pageSelector else {
            return false
        }
        return pageSelector.viewController.control(control, textView: textView, doCommandBy: commandSelector)
    }
}
