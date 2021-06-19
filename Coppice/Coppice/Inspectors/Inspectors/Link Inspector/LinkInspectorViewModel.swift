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
    let documentWindowViewModel: DocumentWindowViewModel
    init(linkEditor: LinkEditor, documentWindowViewModel: DocumentWindowViewModel) {
        self.linkEditor = linkEditor
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
        var textValue = ""
        var icon: NSImage? = nil
        var placeholderValue = NSLocalizedString("No link", comment: "Link field: no link placeholder")
        var linkFieldEnabled = true
        switch value {
        case .noSelection:
            placeholderValue = NSLocalizedString("No selection", comment: "Link field: no selection placeholder")
            linkFieldEnabled = false
        case .empty:
            break
        case .multipleSelection:
            placeholderValue = NSLocalizedString("Multiple selection", comment: "Link field: multiple selection placeholder")
        case .pageLink(let pageLink):
            guard let page = self.documentWindowViewModel.modelController.pageCollection.objectWithID(pageLink.destination) else {
                textValue = NSLocalizedString("Invalid", comment: "Link field: invalid link")
                break
            }
            textValue = page.title
            icon = page.content.contentType.icon(.small)
        case .url(let url):
            textValue = url.absoluteString
        }

        self.textValue = textValue
        self.icon = icon
        self.placeholderValue = placeholderValue
        self.linkFieldEnabled = linkFieldEnabled
    }

    func link(to url: URL) {
        //TODO: Implement
    }
}
