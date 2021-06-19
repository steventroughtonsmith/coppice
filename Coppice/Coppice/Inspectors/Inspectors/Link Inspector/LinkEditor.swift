//
//  LinkEditor.swift
//  Coppice
//
//  Created by Martin Pilkington on 17/06/2021.
//  Copyright © 2021 M Cubed Software. All rights reserved.
//

import Foundation

import CoppiceCore

protocol LinkEditor {
    var selectedLink: LinkEditorValue { get }
    var selectedLinkPublisher: Published<LinkEditorValue>.Publisher { get }

    func updateSelection(with link: LinkEditorValue)
}

enum LinkEditorValue {
    case noSelection
    case empty
    case multipleSelection
    case pageLink(PageLink)
    case url(URL)
}
