//
//  ContentSelectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Foundation

protocol ContentSelectorViewModelDelegate: class {
    func selectedType(in viewModel: ContentSelectorViewModel)
}


protocol ContentSelectorView: class {
}

class ContentSelectorViewModel: NSObject {
    weak var view: ContentSelectorView?
    weak var delegate: ContentSelectorViewModelDelegate?

    let page: Page
    let modelController: ModelController
    init(page: Page, modelController: ModelController) {
        self.page = page
        self.modelController = modelController
        super.init()
    }

    var contentTypes: [ContentTypeModel] = [
        ContentTypeModel(type: .text, localizedName: "Text", iconName: "NSMultipleDocuments"),
        ContentTypeModel(type: .image, localizedName: "Image", iconName: "NSColorPanel")
    ]

    func selectType(_ contentType: ContentTypeModel) {
        self.page.content = contentType.type.createContent()
        self.delegate?.selectedType(in: self)
    }

    func canCreateContent(fromFileAt url: URL) -> Bool {
        guard let resourceValues = try? url.resourceValues(forKeys: Set([.typeIdentifierKey])),
            let typeIdentifier = resourceValues.typeIdentifier else {
                return false
        }

        return PageContentType.contentType(forUTI: typeIdentifier) != nil
    }

    func createContent(fromFileAt url: URL) -> Bool {
        guard let resourceValues = try? url.resourceValues(forKeys: Set([.typeIdentifierKey])),
            let typeIdentifier = resourceValues.typeIdentifier else {
                return false
        }
        guard let contentType = PageContentType.contentType(forUTI: typeIdentifier) else {
            return false
        }

        guard let data = try? Data(contentsOf: url) else {
            return false
        }

        self.page.content = contentType.createContent(data: data)
        self.delegate?.selectedType(in: self)
        return true
    }
}


struct ContentTypeModel {
    let type: PageContentType
    let localizedName: String
    let iconName: String
}
