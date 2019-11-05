//
//  CanvasPage.swift
//  Bubbles
//
//  Created by Martin Pilkington on 22/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa

final class CanvasPage: NSObject, CollectableModelObject {
    static let modelType: ModelType = ModelType(rawValue: "CanvasPage")!

    var id = ModelID(modelType: CanvasPage.modelType)
    weak var collection: ModelCollection<CanvasPage>?

    //MARK: - Attributes
    var frame: CGRect = .zero {
        didSet { self.didChange(\.frame, oldValue: oldValue) }
    }

    
    //MARK: - Relationships
    weak var page: Page? {
        didSet {
            if let page = self.page {
                self.frame.size = page.contentSize
            }
            self.didChangeRelationship(\.page, oldValue: oldValue, inverseKeyPath: \.canvases)
        }
    }
    weak var canvas: Canvas? {
        didSet { self.didChangeRelationship(\.canvas, oldValue: oldValue, inverseKeyPath: \.pages) }
    }

    weak var parent: CanvasPage?
    var children: Set<CanvasPage> {
        self.relationship(for: \.parent)
    }

    func objectWillBeDeleted() {
        self.page = nil
        self.canvas = nil
        self.parent = nil
    }


    //MARK: - Plists
    var plistRepresentation: [String : Any] {
        var plist: [String: Any] = [
            "id": self.id.stringRepresentation,
            "frame": NSStringFromRect(self.frame)
        ]

        if let page = self.page {
            plist["page"] = page.id.stringRepresentation
        }
        if let canvas = self.canvas {
            plist["canvas"] = canvas.id.stringRepresentation
        }
        if let parent = self.parent {
            plist["parent"] = parent.id.stringRepresentation
        }
        return plist
    }

    func update(fromPlistRepresentation plist: [String : Any]) throws {
        guard let modelController = self.modelController else {
            throw ModelObjectUpdateErrors.modelControllerNotSet
        }

        guard self.id.stringRepresentation == (plist["id"] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        let frameString: String = try self.attribute(withKey: "frame", from: plist)
        self.frame = NSRectFromString(frameString)

        if let parentString = plist["parent"] as? String, let parentID = ModelID(string: parentString) {
            self.parent = modelController.collection(for: CanvasPage.self).objectWithID(parentID)
        }

        if let pageString = plist["page"] as? String, let pageID = ModelID(string: pageString) {
            self.page = modelController.collection(for: Page.self).objectWithID(pageID)
        }

        if let canvasString = plist["canvas"] as? String, let canvasID = ModelID(string: canvasString) {
            self.canvas = modelController.collection(for: Canvas.self).objectWithID(canvasID)
        }
    }

    private func attribute<T>(withKey key: String, from plist: [String: Any]) throws -> T {
        guard let value = plist[key] as? T else {
            throw ModelObjectUpdateErrors.attributeNotFound(key)
        }
        return value
    }
}
