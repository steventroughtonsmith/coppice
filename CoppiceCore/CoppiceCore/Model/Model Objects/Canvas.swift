//
//  Canvas.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

public final class Canvas: NSObject, CollectableModelObject {
    public enum Theme: String, CaseIterable {
        case auto
        case dark
        case light

        public var localizedName: String {
            switch self {
            case .auto: return NSLocalizedString("Automatic", comment: "Automatic theme name")
            case .dark: return NSLocalizedString("Dark", comment: "Dark theme name")
            case .light: return NSLocalizedString("Light", comment: "Light theme name")
            }
        }
    }



    public static let modelType: ModelType = ModelType(rawValue: "Canvas")!

    public var id = ModelID(modelType: Canvas.modelType)
    public weak var collection: ModelCollection<Canvas>?

    public func objectWasInserted() {
        self.sortIndex = self.collection?.all.count ?? 0
    }

    
    //MARK: - Attributes
    @objc dynamic public var title: String = "New Canvas" {
        didSet { self.didChange(\.title, oldValue: oldValue) }
    }
    public var dateCreated = Date()
    public var dateModified = Date()
    @objc dynamic public var sortIndex = 0 {
        didSet { self.didChange(\.sortIndex, oldValue: oldValue) }
    }

    public var theme: Theme = Canvas.defaultTheme {
        didSet { self.didChange(\.theme, oldValue: oldValue)}
    }

    public var viewPort: CGRect?

    public var zoomFactor: CGFloat = 1 {
        didSet {
            if self.zoomFactor > 1 {
                self.zoomFactor = 1
            }
            else if self.zoomFactor < 0.25 {
                self.zoomFactor = 0.25
            }
        }
    }

    @objc dynamic public var thumbnail: NSImage? {
        didSet { self.didChange(\.thumbnail, oldValue: oldValue) }
    }

    public var closedPageHierarchies: [ModelID: [ModelID: PageHierarchy]] = [:]


    //MARK: - Relationships
    public var pages: Set<CanvasPage> {
        return self.relationship(for: \.canvas)
    }

    public var sortedPages: [CanvasPage] {
        return self.pages.sorted { $0.zIndex < $1.zIndex }
    }


    //MARK: - Plists
    public static var modelFileProperties: [String] {
        return ["thumbnail"]
    }

    public var plistRepresentation: [String : Any] {
        var plist: [String: Any] = [
            "id": self.id.stringRepresentation,
            "title": self.title,
            "dateCreated": self.dateCreated,
            "dateModified": self.dateModified,
            "sortIndex": self.sortIndex,
            "theme": self.theme.rawValue,
            "zoomFactor": self.zoomFactor
        ]
        if let thumbnailData = self.thumbnail?.pngData() {
            plist["thumbnail"] = ModelFile(type: "thumbnail", filename: "\(self.id.uuid.uuidString)-thumbnail.png", data: thumbnailData, metadata: [:])
        }
        if let viewPort = self.viewPort  {
            plist["viewPort"] = NSStringFromRect(viewPort)
        }

        
        let plistableHierarchy = Dictionary(uniqueKeysWithValues: self.closedPageHierarchies.map { key, value in
            return (key.stringRepresentation, Dictionary(uniqueKeysWithValues: value.map { key, value in
                return (key.stringRepresentation, value.plistRepresentation)
            }))
        })
        plist["closedPageHierarchies"] = plistableHierarchy

        return plist
    }

    public func update(fromPlistRepresentation plist: [String : Any]) throws {
        guard self.id.stringRepresentation == (plist["id"] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        self.title = try self.attribute(withKey: "title", from: plist)
        self.dateCreated = try self.attribute(withKey: "dateCreated", from: plist)
        self.dateModified = try self.attribute(withKey: "dateModified", from: plist)
        self.sortIndex = try self.attribute(withKey: "sortIndex", from: plist)

        let rawTheme: String = try self.attribute(withKey: "theme", from: plist)
        guard let theme = Theme(rawValue: rawTheme) else {
            throw ModelObjectUpdateErrors.attributeNotFound("theme")
        }
        self.theme = theme

        if let viewPortString = plist["viewPort"] as? String {
            self.viewPort = NSRectFromString(viewPortString)
        } else {
            self.viewPort = nil
        }

        if let thumbnail = plist["thumbnail"] as? ModelFile {
            if let data = thumbnail.data {
                self.thumbnail = NSImage(data: data)
            }
        } else {
            self.thumbnail = nil
        }

        if let zoomFactor = plist["zoomFactor"] as? CGFloat {
            self.zoomFactor = zoomFactor
        } else {
            self.zoomFactor = 1
        }

        if let plistableHierarchy = plist["closedPageHierarchies"] as? [String: [String: [String: Any]]] {
            let hierarchy = plistableHierarchy.compactMap { key, value -> (ModelID, [ModelID: PageHierarchy])? in
                guard let canvasPageID = ModelID(string: key) else {
                    return nil
                }
                let pageList = value.compactMap { key, value -> (ModelID, PageHierarchy)? in
                    guard let pageID = ModelID(string: key), let pageHierarchy = PageHierarchy(plistRepresentation: value) else {
                        return nil
                    }
                    return (pageID, pageHierarchy)
                }
                return (canvasPageID, Dictionary(uniqueKeysWithValues: pageList))
            }
            self.closedPageHierarchies = Dictionary(uniqueKeysWithValues: hierarchy)
        } else {
            self.closedPageHierarchies = [:]
        }
    }

    private func attribute<T>(withKey key: String, from plist: [String: Any]) throws -> T {
        guard let value = plist[key] as? T else {
            throw ModelObjectUpdateErrors.attributeNotFound(key)
        }
        return value
    }
}
