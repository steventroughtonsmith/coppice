//
//  CanvasPage.swift
//  Coppice
//
//  Created by Martin Pilkington on 22/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import Cocoa
import M3Data

final public class CanvasPage: NSObject, CollectableModelObject {
    //MARK: - ModelObject Definitions
    public static let modelType: ModelType = ModelType(rawValue: "CanvasPage")!
    public var id = ModelID(modelType: CanvasPage.modelType)
    public weak var collection: ModelCollection<CanvasPage>?

    //MARK: - Attributes
    @objc dynamic public var frame: CGRect = .zero {
        didSet { self.didChange(\.frame, oldValue: oldValue) }
    }

    @objc dynamic public var title: String {
        return self.page?.title ?? ""
    }

    public var maintainAspectRatio: Bool {
        return self.page?.content.maintainAspectRatio ?? false
    }

    public var minimumContentSize: CGSize {
        return self.page?.content.minimumContentSize ?? Page.defaultMinimumContentSize
    }

    public var zIndex: Int = -1

    public private(set) var otherProperties = [ModelPlistKey: Any]()


    //MARK: - Relationships
    @ModelObjectReference @objc dynamic public var page: Page? {
        didSet {
            if let page = self.page, self.frame.size == .zero {
                self.frame.size = page.contentSize
            }
            self.willChangeValue(for: \.title)
            self.didChangeRelationship(\.page, inverseKeyPath: \.canvasPages, oldValue: oldValue)
            self.didChangeValue(for: \.title)
        }
    }

    @ModelObjectReference public var canvas: Canvas? {
        didSet { self.didChangeRelationship(\.canvas, inverseKeyPath: \.pages, oldValue: oldValue) }
    }

    public var linksTo: Set<CanvasLink> {
        self.relationship(for: \.sourcePage)
    }

    public var linksFrom: Set<CanvasLink> {
        self.relationship(for: \.destinationPage)
    }


    //MARK: - KVO
    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "title" {
            keyPaths.insert("self.page.title")
        }
        return keyPaths
    }

    //MARK: - Old Relationships
    @ModelObjectReference @objc dynamic public var parent: CanvasPage? {
        didSet {
            self.willChangeValue(for: \.title)
            self.didChangeRelationship(\.parent, inverseKeyPath: \.children, oldValue: oldValue)
            self.didChangeValue(for: \.title)
        }
    }

    public var children: Set<CanvasPage> {
        self.relationship(for: \.parent)
    }

    public func existingCanvasPage(for page: Page) -> CanvasPage? {
        if self.page?.id == page.id {
            return self
        }
        if let child = self.children.first(where: { $0.page?.id == page.id }) {
            return child
        }
        return nil
    }


    //MARK: - Relationship Setup
    public func objectWasInserted() {
        self.$page.modelController = self.modelController
        self.$canvas.modelController = self.modelController
        self.$parent.modelController = self.modelController
    }

    public func objectWasDeleted() {
        self.$page.performCleanUp()
        self.$canvas.performCleanUp()
        self.$parent.performCleanUp()
    }


    //MARK: - Helpers
    func contentSizeDidChange(to newSize: CGSize, oldSize: CGSize?) {
        var newFrame = self.frame
        if let oldSize = oldSize, oldSize != .zero {
            let scaleFactor = self.frame.width / oldSize.width
            newFrame.size = newSize.multiplied(by: scaleFactor)
        } else {
            newFrame.size = newSize
        }

        self.frame = newFrame
    }


    //MARK: - Plists
    public static var propertyConversions: [ModelPlistKey : ModelPropertyConversion] {
        return [
            .CanvasPage.page: .modelID,
            .CanvasPage.canvas: .modelID
        ]
    }

    public var plistRepresentation: [ModelPlistKey: Any] {
        var plist = self.otherProperties

        plist[.id] = self.id
        plist[.CanvasPage.frame] = NSStringFromRect(self.frame)
        plist[.CanvasPage.zIndex] = self.zIndex

        if let page = self.page {
            plist[.CanvasPage.page] = page.id
        }
        if let canvas = self.canvas {
            plist[.CanvasPage.canvas] = canvas.id
        }
        return plist
    }

    public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
        guard let modelController = self.modelController else {
            throw ModelObjectUpdateErrors.modelControllerNotSet
        }

        guard self.id == plist.attribute(withKey: .id) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        let frameString: String = try plist.requiredAttribute(withKey: .CanvasPage.frame)
        self.frame = NSRectFromString(frameString)

        if let pageID: ModelID = plist.attribute(withKey: .CanvasPage.page) {
            self.page = modelController.collection(for: Page.self).objectWithID(pageID)
        }

        if let canvasID: ModelID = plist.attribute(withKey: .CanvasPage.canvas) {
            self.canvas = modelController.collection(for: Canvas.self).objectWithID(canvasID)
        }

        if let zIndex: Int = plist.attribute(withKey: .CanvasPage.zIndex) {
            self.zIndex = zIndex
        }

        let plistKeys = ModelPlistKey.CanvasPage.all
        self.otherProperties = plist.filter { (key, _) -> Bool in
            return plistKeys.contains(key) == false
        }
    }
}

extension ModelPlistKey {
    enum CanvasPage {
        static let frame = ModelPlistKey(rawValue: "frame")!
        static let zIndex = ModelPlistKey(rawValue: "zIndex")!
        static let page = ModelPlistKey(rawValue: "page")!
        static let canvas = ModelPlistKey(rawValue: "canvas")!
        static let parent = ModelPlistKey(rawValue: "parent")!

        static var all: [ModelPlistKey] {
            return [.id, .CanvasPage.frame, .CanvasPage.zIndex, .CanvasPage.page, .CanvasPage.canvas, .CanvasPage.parent]
        }
    }
}
