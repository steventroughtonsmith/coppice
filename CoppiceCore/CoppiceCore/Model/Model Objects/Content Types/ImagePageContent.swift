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
            if image != oldValue, let image = self.image {
                self.cropRect = CGRect(origin: .zero, size: image.size)
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

    @objc dynamic public var cropRect: CGRect {
        didSet {
            guard self.cropRect != oldValue else {
                return
            }
            self.didChange(\.cropRect, oldValue: oldValue)
        }
    }

    public weak var page: Page?

    public private(set) var otherMetadata: [String: Any]?
    enum MetadataKeys: String, CaseIterable {
        case description
        case cropRect
    }

    public init(data: Data? = nil, metadata: [String: Any]? = nil) {
        if let imageData = data, let image = NSImage(data: imageData) {
            self.image = image
        }
        if let metadata = metadata {
            if let description = metadata[MetadataKeys.description.rawValue] as? String {
                self.imageDescription = description
            }

            if let cropRectString = metadata[MetadataKeys.cropRect.rawValue] as? String {
                self.cropRect = NSRectFromString(cropRectString)
            } else {
                self.cropRect = .zero
            }

            let otherKeys = MetadataKeys.allCases.map(\.rawValue)
            self.otherMetadata = metadata.filter { (key, _) in
                return !otherKeys.contains(key)
            }
        } else {
            self.otherMetadata = nil
            self.cropRect = .zero
        }

        if self.cropRect == .zero, let image = self.image {
            self.cropRect = CGRect(origin: .zero, size: image.size)
        }
    }

    public var modelFile: ModelFile {
        let imageData = self.image?.pngData()
        let filename = (self.page != nil) ? "\(self.page!.id.uuid.uuidString).png" : nil
        var metadata: [String: Any] = self.otherMetadata ?? [:]
        if let description = self.imageDescription {
            metadata[MetadataKeys.description.rawValue] = description
        }
        metadata[MetadataKeys.cropRect.rawValue] = NSStringFromRect(self.cropRect)

        return ModelFile(type: self.contentType.rawValue, filename: filename, data: imageData, metadata: metadata)
    }

    public func sizeToFitContent(currentSize: CGSize) -> CGSize {
        return self.image?.size ?? currentSize
    }
}
