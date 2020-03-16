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
    private var observer: ModelCollection<Page>.Observation!
    init(modelController: ModelController) {
        self.modelController = modelController

        super.init()

        self.observer = self.modelController.collection(for: Page.self).addObserver { (_, changeType) in
            self.reparseLinks()
        }
    }

    deinit {
        if let observer = self.observer {
            self.modelController.collection(for: Page.self).removeObserver(observer)
        }
    }

    weak var textStorage: NSTextStorage? {
        didSet {
            self.reparseLinks()
        }
    }
    weak var delegate: PageLinkManagerDelegate?

    //Observer for page changes
    //Observe for page title changes
    //Observe for text storage changes

    //Update on all of them

    private func reparseLinks() {
        guard let storage = self.textStorage else {
            return
        }

        let pages = Array(self.modelController.collection(for: Page.self).all)
        let links = TextLinkFinder().findLinkChanges(in: storage, using: pages)

        guard (links.linksToAdd.count > 0) || (links.linksToRemove.count > 0) else {
            return
        }

        let shouldChange = self.delegate?.shouldChangeText(in: [NSRange(location:0, length: storage.length)], manager: self) ?? true
        guard shouldChange else {
            return
        }

        storage.beginEditing()
        for link in links.linksToRemove {
            storage.removeAttribute(.link, range: link.range)
        }
        for link in links.linksToAdd {
            if let url = link.url {
                storage.addAttribute(.link, value: url, range: link.range)
            }
        }
        storage.endEditing()


        self.delegate?.textDidChange(in: self)
    }
}

extension PageLinkManager: NSTextStorageDelegate {
    func textStorage(_ textStorage: NSTextStorage, didProcessEditing editedMask: NSTextStorageEditActions, range editedRange: NSRange, changeInLength delta: Int) {
        self.reparseLinks()
    }
}
