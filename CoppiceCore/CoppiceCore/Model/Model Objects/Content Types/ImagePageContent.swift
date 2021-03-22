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

    @objc dynamic public var imageDescription: String? {
        didSet {
            guard self.imageDescription != oldValue else {
                return
            }
            self.didChange(\.imageDescription, oldValue: oldValue)
        }
    }

    public weak var page: Page?

    public private(set) var otherMetadata: [String: Any]?
    enum MetadataKeys: String, CaseIterable {
        case description
    }

    public init(data: Data? = nil, metadata: [String: Any]? = nil) {
        if let imageData = data, let image = NSImage(data: imageData) {
            self.image = image
        }
        if let metadata = metadata {
            if let description = metadata[MetadataKeys.description.rawValue] as? String {
                self.imageDescription = description
            }

            let otherKeys = MetadataKeys.allCases.map(\.rawValue)
            self.otherMetadata = metadata.filter { (key, _) in
                return !otherKeys.contains(key)
            }
        } else {
            self.otherMetadata = nil
        }
    }

    public var modelFile: ModelFile {
        let imageData = self.image?.pngData()
        let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).png" : nil
        var metadata: [String: Any]? = self.otherMetadata
        if let description = self.imageDescription {
            if (metadata == nil) {
                metadata = [:]
            }
            metadata?[MetadataKeys.description.rawValue] = description
        }
        return ModelFile(type: self.contentType.rawValue, filename: filename, data: imageData, metadata: metadata)
    }

    public func sizeToFitContent(currentSize: CGSize) -> CGSize {
        return self.image?.size ?? currentSize
    }
}
