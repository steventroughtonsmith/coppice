//
//  Canvas.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Data

final public class Canvas: NSObject, CollectableModelObject {
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


    //MARK: - ModelObject Definitions
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
        didSet { self.didChange(\.theme, oldValue: oldValue) }
    }

    public var viewPort: CGRect?

    public var zoomFactor: CGFloat = 1 {
        didSet {
            if self.zoomFactor > 1 {
                self.zoomFactor = 1
            } else if self.zoomFactor < 0.25 {
                self.zoomFactor = 0.25
            }
        }
    }

    @objc dynamic public var thumbnail: NSImage? {
        didSet { self.didChange(\.thumbnail, oldValue: oldValue) }
    }

    lazy var hierarchyRestorer: PageHierarchyRestorer = {
        return PageHierarchyRestorer(canvas: self)
    }()

    ///Added 2021.2
    public var alwaysShowPageTitles: Bool = false {
        didSet { self.didChange(\.alwaysShowPageTitles, oldValue: oldValue) }
    }

    public private(set) var otherProperties = [ModelPlistKey: Any]()


    //MARK: - Relationships
    public var pages: Set<CanvasPage> {
        return self.relationship(for: \.canvas)
    }

    public var sortedPages: [CanvasPage] {
        return self.pages.sorted { $0.zIndex < $1.zIndex }
    }

    public var links: Set<CanvasLink> {
        return self.relationship(for: \.canvas)
    }

    public var pageHierarchies: Set<PageHierarchy> {
        return self.relationship(for: \.canvas)
    }


    //MARK: - Plists
    public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
        return [.Canvas.thumbnail: .modelFile]
    }

    public var plistRepresentation: [ModelPlistKey: Any] {
        var plist = self.otherProperties

        plist[.id] = self.id
        plist[.Canvas.title] = self.title
        plist[.Canvas.dateCreated] = self.dateCreated
        plist[.Canvas.dateModified] = self.dateModified
        plist[.Canvas.sortIndex] = self.sortIndex
        plist[.Canvas.theme] = self.theme.rawValue
        plist[.Canvas.zoomFactor] = self.zoomFactor
        plist[.Canvas.alwaysShowPageTitles] = self.alwaysShowPageTitles

        if let thumbnailData = self.thumbnail?.pngData() {
            plist[.Canvas.thumbnail] = ModelFile(type: "thumbnail", filename: "\(self.id.uuid.uuidString)-thumbnail.png", data: thumbnailData, metadata: [:])
        }
        if let viewPort = self.viewPort  {
            plist[.Canvas.viewPort] = NSStringFromRect(viewPort)
        }

        return plist
    }

    public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
        guard self.id == plist.attribute(withKey: .id) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        let title: String = try plist.requiredAttribute(withKey: .Canvas.title)
        let dateCreated: Date = try plist.requiredAttribute(withKey: .Canvas.dateCreated)
        let dateModified: Date = try plist.requiredAttribute(withKey: .Canvas.dateModified)
        let sortIndex: Int = try plist.requiredAttribute(withKey: .Canvas.sortIndex)

        let rawTheme: String = try plist.requiredAttribute(withKey: .Canvas.theme)
        guard let theme = Theme(rawValue: rawTheme) else {
            throw ModelObjectUpdateErrors.attributeNotFound(ModelPlistKey.Canvas.theme.rawValue)
        }

        self.title = title
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.sortIndex = sortIndex
        self.theme = theme

        if let viewPortString: String = plist.attribute(withKey: .Canvas.viewPort) {
            self.viewPort = NSRectFromString(viewPortString)
        } else {
            self.viewPort = nil
        }

        if let thumbnail: ModelFile = plist.attribute(withKey: .Canvas.thumbnail) {
            if let data = thumbnail.data {
                self.thumbnail = NSImage(data: data)
            }
        } else {
            self.thumbnail = nil
        }

        if let zoomFactor: CGFloat = plist.attribute(withKey: .Canvas.zoomFactor) {
            self.zoomFactor = zoomFactor
        } else {
            self.zoomFactor = 1
        }

        if let alwaysShowPageTitles: Bool = plist.attribute(withKey: .Canvas.alwaysShowPageTitles) {
            self.alwaysShowPageTitles = alwaysShowPageTitles
        }

        let plistKeys = ModelPlistKey.Canvas.all
        self.otherProperties = plist.filter { (key, _) -> Bool in
            return plistKeys.contains(key) == false
        }
    }
}


extension ModelPlistKey {
    enum Canvas {
        static let title = ModelPlistKey(rawValue: "title")
        static let dateCreated = ModelPlistKey(rawValue: "dateCreated")
        static let dateModified = ModelPlistKey(rawValue: "dateModified")
        static let sortIndex = ModelPlistKey(rawValue: "sortIndex")
        static let theme = ModelPlistKey(rawValue: "theme")
        static let zoomFactor = ModelPlistKey(rawValue: "zoomFactor")
        static let thumbnail = ModelPlistKey(rawValue: "thumbnail")
        static let viewPort = ModelPlistKey(rawValue: "viewPort")
        static let alwaysShowPageTitles = ModelPlistKey(rawValue: "alwaysShowPageTitles") ///Added 2021.2

        static var all: [ModelPlistKey] {
            return [.id, .Canvas.title, .Canvas.dateCreated, .Canvas.dateModified, .Canvas.sortIndex, .Canvas.theme, .Canvas.zoomFactor, .Canvas.thumbnail, .Canvas.viewPort, .Canvas.alwaysShowPageTitles]
        }
    }
}
