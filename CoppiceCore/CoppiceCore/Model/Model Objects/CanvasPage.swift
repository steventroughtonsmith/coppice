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
    public static let modelType: ModelType = ModelType(rawValue: "CanvasPage")!

    public var id = ModelID(modelType: CanvasPage.modelType)
    public weak var collection: ModelCollection<CanvasPage>?

    //MARK: - Attributes
    @objc dynamic public var frame: CGRect = .zero {
        didSet { self.didChange(\.frame, oldValue: oldValue) }
    }

    override public class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        var keyPaths = super.keyPathsForValuesAffectingValue(forKey: key)
        if key == "title" {
            keyPaths.insert("self.page.title")
        }
        return keyPaths
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

    public private(set) var otherProperties = [String: Any]()


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
        if let oldSize = oldSize {
            let scaleFactor = self.frame.width / oldSize.width
            newFrame.size = newSize.multiplied(by: scaleFactor)
        } else {
            newFrame.size = newSize
        }

        self.frame = newFrame
    }


    //MARK: - Plists
    enum PlistKeys: String, CaseIterable {
        case id
        case frame
        case zIndex
        case page
        case canvas
        case parent
    }

    public var plistRepresentation: [String: Any] {
        var plist = self.otherProperties

        plist[PlistKeys.id.rawValue] = self.id.stringRepresentation
        plist[PlistKeys.frame.rawValue] = NSStringFromRect(self.frame)
        plist[PlistKeys.zIndex.rawValue] = self.zIndex

        if let page = self.page {
            plist[PlistKeys.page.rawValue] = page.id.stringRepresentation
        }
        if let canvas = self.canvas {
            plist[PlistKeys.canvas.rawValue] = canvas.id.stringRepresentation
        }
        if let parent = self.parent {
            plist[PlistKeys.parent.rawValue] = parent.id.stringRepresentation
        }
        return plist
    }

    public func update(fromPlistRepresentation plist: [String: Any]) throws {
        guard let modelController = self.modelController else {
            throw ModelObjectUpdateErrors.modelControllerNotSet
        }

        guard self.id.stringRepresentation == (plist[PlistKeys.id.rawValue] as? String) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        let frameString: String = try self.attribute(withKey: PlistKeys.frame.rawValue, from: plist)
        self.frame = NSRectFromString(frameString)

        if let parentString = plist[PlistKeys.parent.rawValue] as? String, let parentID = ModelID(string: parentString) {
            self.parent = modelController.collection(for: CanvasPage.self).objectWithID(parentID)
        }

        if let pageString = plist[PlistKeys.page.rawValue] as? String, let pageID = ModelID(string: pageString) {
            self.page = modelController.collection(for: Page.self).objectWithID(pageID)
        }

        if let canvasString = plist[PlistKeys.canvas.rawValue] as? String, let canvasID = ModelID(string: canvasString) {
            self.canvas = modelController.collection(for: Canvas.self).objectWithID(canvasID)
        }

        if let zIndex = plist[PlistKeys.zIndex.rawValue] as? Int {
            self.zIndex = zIndex
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
