//
//  ImagePageContent.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit


public class ImagePageContent: NSObject, PageContent {
    public let contentType = PageContentType.image
    @objc dynamic public var image: NSImage? {
        didSet {
            if oldValue == nil && self.image != nil {
                self.page?.updatePageSizes()
            }
            self.didChange(\.image, oldValue: oldValue)
        }
    }

    public var initialContentSize: CGSize? {
        return self.image?.size
    }

    public var maintainAspectRatio: Bool {
        return true
    }

    @objc dynamic public var imageDescription: String?
    public weak var page: Page?

    public init(data: Data? = nil, metadata: [String: Any]? = nil) {
        if let imageData = data, let image = NSImage(data: imageData) {
            self.image = image
        }
        if let description = metadata?["description"] as? String {
            self.imageDescription = description
        }
    }

    public var modelFile: ModelFile {
        let imageData = self.image?.pngData()
        let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).png" : nil
        var metadata: [String: Any]? = nil
        if let description = self.imageDescription {
            metadata = ["description": description]
        }
        return ModelFile(type: self.contentType.rawValue, filename: filename, data: imageData, metadata: metadata)
    }

    public func sizeToFitContent(currentSize: CGSize) -> CGSize {
        return self.image?.size ?? currentSize
    }
}
