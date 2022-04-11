//
//  ImagePageContent.swift
//  Coppice
//
//  Created by Martin Pilkington on 16/12/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import Combine
import M3Data
import Vision

public class ImagePageContent: NSObject, PageContent {
    public let contentType = PageContentType.image
    @objc dynamic public private(set) var image: NSImage? {
        didSet {
            self.didChange(\.image, oldValue: oldValue)
        }
    }

    public enum ImageOperation {
        case replace
        case rotate(RotationDirection)

        public enum RotationDirection {
            case left
            case right

            var radians: CGFloat {
                switch self {
                case .left:
                    return -Double.pi / 2
                case .right:
                    return Double.pi / 2
                }
            }
        }
    }

    public func setImage(_ newImage: NSImage?, operation: ImageOperation) {
        self.undoManager?.beginUndoGrouping()
        let oldValue = self.image
        if newImage != oldValue, let image = newImage {
            switch operation {
            case .replace:
                self.cropRect = CGRect(origin: .zero, size: image.size)
                if image.size != oldValue?.size {
                    self.hotspots = []
                }
            case .rotate(let direction):
                let rotationPoint = image.size.toRect().midPoint
                self.cropRect = self.cropRect.rotate(byRadians: direction.radians, around: rotationPoint)
                self.hotspots = self.hotspots.map { $0.rotated(byRadians: direction.radians, around: rotationPoint) }
                self.orientation = self.orientation.rotated(by: direction)
            }
            self.page?.contentSizeDidChange(to: image.size, oldSize: oldValue?.size)
        }
        self.image = newImage
        self.undoManager?.endUndoGrouping()
    }

    ///Orientation of the image
    ///
    ///This is not pulled from image data as we never get that
    ///It's also structured weirdly. Up is up and down is down, but left means rotated clockwise and right means rotated anti clockwise
    ///This seems backwards but it's the only way to get Vision framework to work correctly
    public var orientation: CGImagePropertyOrientation = .up

    public var initialContentSize: CGSize? {
        guard self.image != nil else {
            return nil
        }
        return self.cropRect.size
    }

    public var minimumContentSize: CGSize {
        return (self.image != nil) ? CGSize(width: 32, height: 32) : Page.defaultMinimumContentSize
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
            self.undoManager?.beginUndoGrouping()
            self.didChange(\.cropRect, oldValue: oldValue)
            if self.cropRect != .zero {
                self.page?.contentSizeDidChange(to: self.cropRect.size, oldSize: oldValue.size)
            }
            self.undoManager?.endUndoGrouping()
        }
    }

    @objc dynamic public var hotspots: [ImageHotspot] = [] {
        didSet {
            guard self.hotspots != oldValue else {
                return
            }
            self.didChange(\.hotspots, oldValue: oldValue)
        }
    }

    @objc dynamic public var recognizedTexts: [VNRecognizedText] = [] {
        didSet {
            guard self.recognizedTexts != oldValue else {
                return
            }
            self.didChange(\.recognizedTexts, oldValue: oldValue)
        }
    }

    public weak var page: Page?

    public private(set) var otherMetadata: [String: Any]?
    enum MetadataKeys: String, CaseIterable {
        case description
        case cropRect
        case hotspots
        case orientation
    }

    public init(data: Data? = nil) {
        if let imageData = data, let image = NSImage(data: imageData) {
            self.image = image
            self.cropRect = CGRect(origin: .zero, size: image.size)
        } else {
            self.cropRect = .zero
        }
    }

    public init(modelFile: ModelFile) throws {
        if let imageData = modelFile.data, let image = NSImage(data: imageData) {
            self.image = image
        }
        if let metadata = modelFile.metadata {
            if let description = metadata[MetadataKeys.description.rawValue] as? String {
                self.imageDescription = description
            }

            if let cropRectString = metadata[MetadataKeys.cropRect.rawValue] as? String {
                self.cropRect = NSRectFromString(cropRectString)
            } else {
                self.cropRect = .zero
            }

            if let hotspotsArray = metadata[MetadataKeys.hotspots.rawValue] as? [[String: Any]] {
                self.hotspots = try hotspotsArray.map { try ImageHotspot(dictionaryRepresentation: $0) }
            } else {
                self.hotspots = []
            }

            if let rawOrientation = metadata[MetadataKeys.orientation.rawValue] as? UInt32,
               let orientation = CGImagePropertyOrientation(rawValue: rawOrientation)
            {
                self.orientation = orientation
            } else {
                self.orientation = .up
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
        metadata[MetadataKeys.hotspots.rawValue] = self.hotspots.map(\.dictionaryRepresentation)
        metadata[MetadataKeys.orientation.rawValue] = self.orientation.rawValue

        return ModelFile(type: self.contentType.rawValue, filename: filename, data: imageData, metadata: metadata)
    }

    public func firstMatch(forSearchString searchString: String) -> PageContentMatch? {
        for recognizedText in self.recognizedTexts {
            let nsString = (recognizedText.string as NSString)
            let foundRange = nsString.range(of: searchString, options: [.caseInsensitive, .diacriticInsensitive])
            guard (foundRange.location != NSNotFound) else {
                continue
            }
            return Match(range: foundRange, recognisedText: recognizedText)
        }
        return nil
    }

    public func sizeToFitContent(currentSize: CGSize) -> CGSize {
        guard self.image != nil else {
            return currentSize
        }
        return self.cropRect.size
    }
}


extension CGImagePropertyOrientation {
    func rotated(by direction: ImagePageContent.ImageOperation.RotationDirection) -> CGImagePropertyOrientation {
        //Yes right and left are mixed up but apparently that's how directions work in the Vision framework
        switch direction {
        case .left:
            switch self {
            case .up:       return .right
            case .down:     return .left
            case .left:     return .up
            case .right:    return .down
            default:
                return .up
            }
        case .right:
            switch self {
            case .up:       return .left
            case .down:     return .right
            case .left:     return .down
            case .right:    return .up
            default:
                return .up
            }
        }
    }
}


extension ImagePageContent {
    public struct Match: PageContentMatch {
        public var range: NSRange
        public var recognisedText: VNRecognizedText

        public var string: String {
            return self.recognisedText.string
        }
    }
}
