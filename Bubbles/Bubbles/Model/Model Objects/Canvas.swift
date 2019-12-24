//
//  Canvas.swift
//  Bubbles
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

final class Canvas: NSObject, CollectableModelObject {
    static let modelType: ModelType = ModelType(rawValue: "Canvas")!

    var id = ModelID(modelType: Canvas.modelType)
    weak var collection: ModelCollection<Canvas>?

    func objectWasInserted() {
        self.sortIndex = self.collection?.all.count ?? 0
    }

    
    //MARK: - Attributes
    @objc var title: String = "New Canvas" {
        didSet { self.didChange(\.title, oldValue: oldValue) }
    }
    var dateCreated = Date()
    var dateModified = Date()
    @objc dynamic var sortIndex = 0 {
        didSet { self.didChange(\.sortIndex, oldValue: oldValue) }
    }

    var viewPort: CGRect?


    //MARK: - Relationships
    var pages: Set<CanvasPage> {
        return self.relationship(for: \.canvas)
    }


    //MARK: - Plists
    var plistRepresentation: [String : Any] {
        var plist: [String: Any] = [
            "id": self.id.stringRepresentation,
            "title": self.title,
            "dateCreated": self.dateCreated,
            "dateModified": self.dateModified,
            "sortIndex": self.sortIndex
        ]
        if let viewPort = self.viewPort  {
            plist["viewPort"] = NSStringFromRect(viewPort)
        }
        return plist
    }

    func update(fromPlistRepresentation plist: [String : Any]) throws {
        guard self.id.stringRepresentation == (plist["id"] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        self.title = try self.attribute(withKey: "title", from: plist)
        self.dateCreated = try self.attribute(withKey: "dateCreated", from: plist)
        self.dateModified = try self.attribute(withKey: "dateModified", from: plist)
        self.sortIndex = try self.attribute(withKey: "sortIndex", from: plist)

        if let viewPortString = plist["viewPort"] as? String {
            self.viewPort = NSRectFromString(viewPortString)
        } else {
            self.viewPort = nil
        }
    }

    private func attribute<T>(withKey key: String, from plist: [String: Any]) throws -> T {
        guard let value = plist[key] as? T else {
            throw ModelObjectUpdateErrors.attributeNotFound(key)
        }
        return value
    }


    //MARK: - Searching

    func isMatchForSearch(_ searchTerm: String?) -> Bool {
        guard let term = searchTerm, term.count > 0 else {
            return true
        }

        if self.title.localizedCaseInsensitiveContains(term) {
            return true
        }

        for page in self.pages {
            if page.page?.isMatchForSearch(term) == true {
                return true
            }
        }
        return false
    }
}
