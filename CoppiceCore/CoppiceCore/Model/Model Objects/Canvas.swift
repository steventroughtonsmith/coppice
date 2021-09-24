//
//  Canvas.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

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

    public var closedPageHierarchies: [ModelID: [ModelID: PageHierarchy]] = [:]

    ///Added 2021.2
    public var alwaysShowPageTitles: Bool = false {
        didSet { self.didChange(\.alwaysShowPageTitles, oldValue: oldValue) }
    }

    public private(set) var otherProperties = [String: Any]()


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

    enum PlistKeys: String, CaseIterable {
        case id
        case title
        case dateCreated
        case dateModified
        case sortIndex
        case theme
        case zoomFactor
        case thumbnail
        case viewPort
        case closedPageHierarchies
        case alwaysShowPageTitles ///Added 2021.2
    }

    public var plistRepresentation: [String: Any] {
        var plist = self.otherProperties

        plist[PlistKeys.id.rawValue] = self.id.stringRepresentation
        plist[PlistKeys.title.rawValue] = self.title
        plist[PlistKeys.dateCreated.rawValue] = self.dateCreated
        plist[PlistKeys.dateModified.rawValue] = self.dateModified
        plist[PlistKeys.sortIndex.rawValue] = self.sortIndex
        plist[PlistKeys.theme.rawValue] = self.theme.rawValue
        plist[PlistKeys.zoomFactor.rawValue] = self.zoomFactor
        plist[PlistKeys.alwaysShowPageTitles.rawValue] = self.alwaysShowPageTitles

        if let thumbnailData = self.thumbnail?.pngData() {
            plist[PlistKeys.thumbnail.rawValue] = ModelFile(type: "thumbnail", filename: "\(self.id.uuid.uuidString)-thumbnail.png", data: thumbnailData, metadata: [:])
        }
        if let viewPort = self.viewPort  {
            plist[PlistKeys.viewPort.rawValue] = NSStringFromRect(viewPort)
        }


        let plistableHierarchy = Dictionary(uniqueKeysWithValues: self.closedPageHierarchies.map { key, value in
            return (key.stringRepresentation, Dictionary(uniqueKeysWithValues: value.map { key, value in
                return (key.stringRepresentation, value.plistRepresentation)
            }))
        })
        plist[PlistKeys.closedPageHierarchies.rawValue] = plistableHierarchy

        return plist
    }

    public func update(fromPlistRepresentation plist: [String: Any]) throws {
        guard self.id.stringRepresentation == (plist["id"] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        let title: String = try self.attribute(withKey: PlistKeys.title.rawValue, from: plist)
        let dateCreated: Date = try self.attribute(withKey: PlistKeys.dateCreated.rawValue, from: plist)
        let dateModified: Date = try self.attribute(withKey: PlistKeys.dateModified.rawValue, from: plist)
        let sortIndex: Int = try self.attribute(withKey: PlistKeys.sortIndex.rawValue, from: plist)

        let rawTheme: String = try self.attribute(withKey: PlistKeys.theme.rawValue, from: plist)
        guard let theme = Theme(rawValue: rawTheme) else {
            throw ModelObjectUpdateErrors.attributeNotFound(PlistKeys.theme.rawValue)
        }

        self.title = title
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.sortIndex = sortIndex
        self.theme = theme

        if let viewPortString = plist[PlistKeys.viewPort.rawValue] as? String {
            self.viewPort = NSRectFromString(viewPortString)
        } else {
            self.viewPort = nil
        }

        if let thumbnail = plist[PlistKeys.thumbnail.rawValue] as? ModelFile {
            if let data = thumbnail.data {
                self.thumbnail = NSImage(data: data)
            }
        } else {
            self.thumbnail = nil
        }

        if let zoomFactor = plist[PlistKeys.zoomFactor.rawValue] as? CGFloat {
            self.zoomFactor = zoomFactor
        } else {
            self.zoomFactor = 1
        }

        if let plistableHierarchy = plist[PlistKeys.closedPageHierarchies.rawValue] as? [String: [String: [String: Any]]] {
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

        if let alwaysShowPageTitles = plist[PlistKeys.alwaysShowPageTitles.rawValue] as? Bool {
            self.alwaysShowPageTitles = alwaysShowPageTitles
        }

        let plistKeys = PlistKeys.allCases.map(\.rawValue)
        self.otherProperties = plist.filter { (key, _) -> Bool in
            return plistKeys.contains(key) == false
        }
    }

    private func attribute<T>(withKey key: String, from plist: [String: Any]) throws -> T {
        guard let value = plist[key] as? T else {
            throw ModelObjectUpdateErrors.attributeNotFound(key)
        }
        return value
    }
}
