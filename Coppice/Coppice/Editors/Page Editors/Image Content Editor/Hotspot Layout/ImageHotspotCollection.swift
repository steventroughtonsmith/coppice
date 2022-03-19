//
//  ImageHotspotCollection.swift
//  Coppice
//
//  Created by Martin Pilkington on 14/03/2022.
//  Copyright © 2022 M Cubed Software. All rights reserved.
//

import Combine
import Foundation

import CoppiceCore

class ImageHotspotCollection {
    let imageContent: ImagePageContent
    init(imageContent: ImagePageContent) {
        self.imageContent = imageContent

        self.subscribers[.imageHotspots] = self.imageContent.publisher(for: \.hotspots).sink { hotspots in
            self.reloadImageEditorHotspots(using: hotspots)
        }
        self.reloadImageEditorHotspots(using: self.imageContent.hotspots)
    }

    //MARK: - Subscribers
    private enum SubscriberKey {
        case imageHotspots
    }

    private var subscribers: [SubscriberKey: AnyCancellable] = [:]

    //MARK: - Image Editor Hotspots

    @Published private(set) var imageEditorHotspots: [ImageEditorHotspot] = []

    var selectedHotspots: [ImageEditorHotspot] {
        return self.imageEditorHotspots.filter(\.isSelected)
    }

    private func reloadImageEditorHotspots(using hotspots: [ImageHotspot]) {
        self.imageEditorHotspots = hotspots.map { self.imageEditorHotspot(for: $0) }
    }

    private func imageEditorHotspot(for imageHotspot: ImageHotspot) -> ImageEditorHotspot {
        switch imageHotspot.kind {
        case .rectangle:
            return ImageEditorRectangleHotspot(shape: .rectangle, rect: CGRect(points: imageHotspot.points) ?? .zero, url: imageHotspot.link, imageSize: self.imageContent.image?.size ?? .zero)
        case .oval:
            return ImageEditorRectangleHotspot(shape: .oval, rect: CGRect(points: imageHotspot.points) ?? .zero, url: imageHotspot.link, imageSize: self.imageContent.image?.size ?? .zero)
        case .polygon:
            fatalError()
        }
    }
}
