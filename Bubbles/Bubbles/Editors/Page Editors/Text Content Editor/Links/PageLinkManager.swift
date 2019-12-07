//
//  TextAutoLinker.swift
//  Bubbles
//
//  Created by Martin Pilkington on 05/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

protocol PageLinkManagerDelegate: class {
    func shouldChangeText(in ranges: [NSRange], manager: PageLinkManager) -> Bool
    func textDidChange(in manager: PageLinkManager)
}

class PageLinkManager: NSObject {
    let modelController: ModelController
    init(modelController: ModelController) {
        self.modelController = modelController
    }

    weak var textStorage: NSTextStorage?
    weak var delegate: PageLinkManagerDelegate?

    /*
     Auto linker needs to take a page and a model controller
     It will then vend any changes to a delegate while it's awake
     Any auto links will have a special tag on the URL
     */

    //Adds all links when string has no links
    //Removes all links when there are no pages
    //Adds missing links and removes stale links

    //Adds links if new page added
    //Removes links if page deleted
    //Adds links if existing page title changes
    //Removes links if existing page title changes
    //Adds and removes links if page title changes to other text that appears

    //Matches longest page name over shorter names
    //Removes link for shorter page name if longer page name added
    //Updates links when typing

    //Doesn't update manual links if page title change
    //Doesn't remove manual links if page title changes
    //Removes manual links if page is removed

    //Ignores "Untitled Page"
}

extension PageLinkManager: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {

    }
}
