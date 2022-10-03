//
//  LinkEditor.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import AppKit

import CoppiceCore

protocol LinkEditor {
    var selectedLink: LinkEditorValue { get }
    var selectedLinkPublisher: Published<LinkEditorValue>.Publisher { get }

    func updateSelection(with link: LinkEditorValue)
}

enum LinkEditorValue: Equatable {
    case noSelection
    case empty
    case multipleSelection
    case pageLink(PageLink)
    case url(URL)

    func icon(with modelController: CoppiceModelController) -> NSImage? {
        switch self {
        case .noSelection, .empty, .multipleSelection:
            return NSImage(named: "link-small")
        case .pageLink(let pageLink):
            guard let page = modelController.pageCollection.objectWithID(pageLink.destination) else {
                return NSImage(named: "invalid-link")
            }
            return page.content.contentType.icon(.small)
        case .url:
            return NSImage(named: "external-link")
        }
    }

    func textValue(with modelController: CoppiceModelController) -> String {
        switch self {
        case .noSelection, .empty, .multipleSelection:
            return ""
        case .pageLink(let pageLink):
            guard let page = modelController.pageCollection.objectWithID(pageLink.destination) else {
                return NSLocalizedString("Invalid Link", comment: "Link field: invalid link")
            }
            guard page.title.count > 0 else {
                return Page.localizedDefaultTitle
            }
            return page.title
        case .url(let url):
            return url.absoluteString
        }
    }

    var placeholderValue: String {
        switch self {
        case .noSelection:
            return NSLocalizedString("No selection", comment: "Link field: no selection placeholder")
        case .multipleSelection:
            return NSLocalizedString("Multiple selection", comment: "Link field: multiple selection placeholder")
        case .empty, .pageLink, .url:
            return NSLocalizedString("Click to add link", comment: "Link field: no link placeholder")
        }
    }
}
