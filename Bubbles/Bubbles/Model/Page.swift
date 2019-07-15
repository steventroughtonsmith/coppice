//
//  Page.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

struct Tag {
    let name: String
}

class Page: NSObject {
    var id = UUID()
    var title: String = "Untitled Page"
    var tags: [Tag] = []
    var dateCreated = Date()
    var dateModified = Date()

    var content: PageContent?
}

protocol PageContent: class {

}
