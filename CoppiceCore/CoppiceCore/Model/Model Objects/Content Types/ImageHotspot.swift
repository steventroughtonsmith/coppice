//
//  ImageHotspot.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 21/02/2022.
//

import CoreGraphics
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
        if let linkString = dictionaryRepresentation["link"] as? String,
           let link = URL(string: linkString)
        {
            self.link = link
        } else {
            self.link = nil
        }
    }

    var dictionaryRepresentation: [String: Any] {
        var dictionaryRepresentation: [String: Any] = [
            "kind": self.kind.rawValue,
            "points": self.points.map(\.dictionaryRepresentation),
        ]

        if let link = self.link {
            dictionaryRepresentation["link"] = link.absoluteString
        }

        return dictionaryRepresentation
    }

    override public func isEqual(_ object: Any?) -> Bool {
        guard let otherHotspot = object as? ImageHotspot else {
            return false
        }
        return (self.kind == otherHotspot.kind) && (self.points == otherHotspot.points) && (self.link == otherHotspot.link)
    }

    func rotated(byRadians radians: CGFloat, around rotationPoint: CGPoint) -> ImageHotspot {
        return ImageHotspot(kind: self.kind,
                            points: self.points.map { $0.rotate(byRadians: radians, around: rotationPoint) },
                            link: self.link)
    }
}

extension ImageHotspot {
    public static func rectangle(centredInImageOfSize size: CGSize) -> ImageHotspot {
        return self.hotspot(.rectangle, centredInImageOfSize: size)
    }

    public static func oval(centredInImageOfSize size: CGSize) -> ImageHotspot {
        return self.hotspot(.oval, centredInImageOfSize: size)
    }

    private static func hotspot(_ kind: Kind, centredInImageOfSize size: CGSize) -> ImageHotspot {
        let hotspotSize = CGSize(width: 50, height: 50)
        let rect = hotspotSize.centred(in: size.toRect())

        return ImageHotspot(kind: kind, points: [
            rect.point(atX: .min, y: .min),
            rect.point(atX: .max, y: .min),
            rect.point(atX: .max, y: .max),
            rect.point(atX: .min, y: .max),
        ])
    }

    public static func polygon(withSides sides: Int, centredInImageOfSize size: CGSize) -> ImageHotspot {
        var points = [CGPoint]()

        let centre = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius: CGFloat = 25

        let initialAngle = -Double.pi / 2
        let angleStep = (2 * Double.pi) / Double(sides)

        (0..<sides).forEach {
            let angle = initialAngle + Double($0) * angleStep
            let x = centre.x + radius * cos(angle)
            let y = centre.y + radius * sin(angle)

            points.append(CGPoint(x: x.toDecimalPlaces(2), y: y.toDecimalPlaces(2)))
        }

        return ImageHotspot(kind: .polygon, points: points)
    }
}

extension CGFloat {
    func toDecimalPlaces(_ decimalPlaces: Int) -> CGFloat {
        let factor = pow(10, CGFloat(decimalPlaces))
        return (self * factor).rounded() / factor
    }
}
