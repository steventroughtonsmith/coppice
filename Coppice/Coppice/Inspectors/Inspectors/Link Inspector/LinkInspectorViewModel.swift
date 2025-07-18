//
//  LinkInspectorViewModel.swift
//  Coppice
//
//  Created by Martin Pilkington on 13/06/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Cocoa
import CoppiceCore

import Combine

protocol LinkInspectorView: AnyObject {}


class LinkInspectorViewModel: BaseInspectorViewModel {
    weak var view: LinkInspectorView?

    let linkEditor: LinkEditor
    let page: Page?
    let documentWindowViewModel: DocumentWindowViewModel
    init(linkEditor: LinkEditor, page: Page?, documentWindowViewModel: DocumentWindowViewModel) {
        self.linkEditor = linkEditor
        self.page = page
        self.documentWindowViewModel = documentWindowViewModel

        super.init()

        self.subscribers[.selectedLink] = linkEditor.selectedLinkPublisher.sink { [weak self] newValue in
            self?.updateProperties(with: newValue)
        }
    }

    //MARK: - Inspector overrides
    override var title: String? {
        return NSLocalizedString("Link", comment: "Link inspector title").localizedUppercase
    }

    override var collapseIdentifier: String {
        return "inspector.link"
    }

    //MARK: - Subscribers
    enum SubscriptionKeys {
        case selectedLink
    }

    private var subscribers: [SubscriptionKeys: AnyCancellable] = [:]

    //MARK: - Public properties
    @Published private(set) var textValue = ""
    @Published var icon: NSImage? = nil
    @Published var placeholderValue = ""
    @Published private(set) var linkFieldEnabled = false

    private func updateProperties(with value: LinkEditorValue) {
        self.textValue = value.textValue(with: self.documentWindowViewModel.modelController)
        self.icon = value.icon(with: self.documentWindowViewModel.modelController)
        self.placeholderValue = value.placeholderValue
        self.linkFieldEnabled = (value != .noSelection)
    }

    func link(to result: PageSelectorViewModel.Result) {
        switch result {
        case .page(let page):
            self.linkEditor.updateSelection(with: .pageLink(page.linkToPage(autoGenerated: false)))
        case .url(let url):
            self.linkEditor.updateSelection(with: .url(url))
        }
    }

    func clearLink() {
        self.linkEditor.updateSelection(with: .empty)
    }
}
