//
//  ContentSelectorViewModel.swift
//  Bubbles
//
//  Created by Martin Pilkington on 12/08/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit

protocol ContentSelectorViewModelDelegate: class {
    func selectedType(in viewModel: ContentSelectorViewModel)
}


protocol ContentSelectorView: class {
}

class ContentSelectorViewModel: ViewModel {
    weak var view: ContentSelectorView?
    weak var delegate: ContentSelectorViewModelDelegate?

    let page: Page
    init(page: Page, documentWindowViewModel: DocumentWindowViewModel) {
        self.page = page
        super.init(documentWindowViewModel: documentWindowViewModel)
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
        self.page.title = url.lastPathComponent
        self.delegate?.selectedType(in: self)
        return true
    }


    func createContentFromPasteboard() -> Bool {
        let pb = NSPasteboard.general
        if let type = pb.availableType(from: [.fileURL]) {
            guard let data = pb.data(forType: type),
                let url = URL(dataRepresentation: data, relativeTo: nil) else {
                    return false
            }
            return self.createContent(fromFileAt: url)
        }
        if let type = pb.availableType(from: [.rtf, .tabularText, .string]) {
            guard let data = pb.data(forType: type),
                let attributedString = try? NSAttributedString(data: data, options: [:], documentAttributes: nil) else {
                    return false
            }
            let content = TextPageContent()
            content.text = attributedString
            self.page.content = content
            return true
        }
        if let type = pb.availableType(from: [.png, .tiff]) {
            guard let data = pb.data(forType: type), let image = NSImage(data: data) else {
                return false
            }
            let content = ImagePageContent()
            content.image = image
            self.page.content = content
            return true
        }
        return false
    }
}


struct ContentTypeModel {
    let type: PageContentType
    let localizedName: String
    let iconName: String
}
