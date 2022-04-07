//
//  PageLinkManager.swift
//  Coppice
//
//  Created by Martin Pilkington on 03/04/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Foundation

import CoppiceCore
import M3Data

class PageLinkManager: NSObject {
    let pageID: ModelID
    let modelController: ModelController
    init(pageID: ModelID, modelController: ModelController) {
        self.pageID = pageID
        self.modelController = modelController
        super.init()
    }

    var isProEnabled: Bool = false
}
