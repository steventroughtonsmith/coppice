//
//  ImagePageContent.swift
//  Bubbles
//
//  Created by Martin Pilkington on 16/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit


class ImagePageContent: NSObject, PageContent {
    let contentType = PageContentType.image
    @objc dynamic var image: NSImage? {
        didSet {
            if oldValue == nil && self.image != nil {
                self.page?.updatePageSizes()
            }
        }
    }
    var contentSize: CGSize? {
        return self.image?.size
    }
    @objc dynamic var imageDescription: String?
    weak var page: Page?

    init(data: Data? = nil, metadata: [String: Any]? = nil) {
        if let imageData = data, let image = NSImage(data: imageData) {
            self.image = image
        }
        if let description = metadata?["description"] as? String {
            self.imageDescription = description
        }
    }

    var modelFile: ModelFile {
        let imageData = self.image?.pngData()
        let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).png" : nil
        var metadata: [String: Any]? = nil
        if let description = self.imageDescription {
            metadata = ["description": description]
        }
        return ModelFile(type: self.contentType.rawValue, filename: filename, data: imageData, metadata: metadata)
    }
}
