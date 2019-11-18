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


class PageInspectorViewModel: BaseInspectorViewModel {
    weak var view: PageInspectorView?

    @objc dynamic let page: Page
    let modelController: ModelController
    init(page: Page, modelController: ModelController) {
        self.page = page
        self.modelController = modelController
        super.init()
    }

    override var title: String? {
        return NSLocalizedString("Page", comment: "Page inspector title")
    }

    override var collapseIdentifier: String {
        return "inspector.page"
    }

    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if (key == #keyPath(pageTitle)) {
            keyPaths.insert("page.title")
        }
        return keyPaths
    }

    @objc dynamic var pageTitle: String {
        get { self.page.title }
        set { self.page.title = newValue }
    }
}
