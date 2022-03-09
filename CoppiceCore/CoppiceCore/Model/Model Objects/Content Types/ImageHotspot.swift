//
//  ImageHotspot.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 21/02/2022.
//

import Foundation

enum ImageHotspotErrors: Error, Equatable {
    case attributeNotFound(String)
    case invalidPoint
}

public class ImageHotspot: NSObject {
    public enum Kind: String {
        case rectangle
        case oval
        case polygon
    }

    public let kind: Kind
    public let points: [CGPoint]
    public let link: URL?

    public init(kind: Kind, points: [CGPoint], link: URL? = nil) {
        self.kind = kind
        self.points = points
        self.link = link
    }

    init(dictionaryRepresentation: [String: Any]) throws {
        guard
            let kindString = dictionaryRepresentation["kind"] as? String,
            let kind = Kind(rawValue: kindString)
        else {
            throw ImageHotspotErrors.attributeNotFound("kind")
        }

        guard let pointsArray = dictionaryRepresentation["points"] as? [CFDictionary] else {
            throw ImageHotspotErrors.attributeNotFound("points")
        }

        var points = [CGPoint]()
        for pointDict in pointsArray {
            guard let point = CGPoint(dictionaryRepresentation: pointDict) else {
                throw ImageHotspotErrors.invalidPoint
            }
            points.append(point)
        }

        self.kind = kind
        self.points = points
        self.link = (dictionaryRepresentation["link"] as? URL)
    }

    var dictionaryRepresentation: [String: Any] {
        var dictionaryRepresentation: [String: Any] = [
            "kind": self.kind.rawValue,
            "points": self.points.map(\.dictionaryRepresentation),
        ]

        if let link = self.link {
            dictionaryRepresentation["link"] = link
        }

        return dictionaryRepresentation
    }

    public override func isEqual(_ object: Any?) -> Bool {
        guard let otherHotspot = object as? ImageHotspot else {
            return false
        }
        return (self.kind == otherHotspot.kind) && (self.points == otherHotspot.points) && (self.link == otherHotspot.link)
    }
}
