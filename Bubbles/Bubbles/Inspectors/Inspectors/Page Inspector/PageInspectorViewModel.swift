//
//  PageInspectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/11/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol PageInspectorView: class {

}


class PageInspectorViewModel: NSObject {
    weak var view: PageInspectorView?

    let page: Page
    let modelController: ModelController
    init(page: Page, modelController: ModelController) {
        self.page = page
        self.modelController = modelController
        super.init()
    }
}
