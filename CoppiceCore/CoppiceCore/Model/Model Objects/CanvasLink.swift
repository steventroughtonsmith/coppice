//
//  CanvasLink.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 16/07/2022.
//

import Foundation
import M3Data

final public class CanvasLink: NSObject, CollectableModelObject {
    public static let modelType: ModelType = ModelType(rawValue: "CanvasLink")!

    public var id = ModelID(modelType: CanvasLink.modelType)
    public weak var collection: ModelCollection<CanvasLink>?

    //MARK: - Properties
    public var link: PageLink?

    public private(set) var otherProperties = [ModelPlistKey: Any]()

    //MARK: - Relationships
    @ModelObjectReference public var destinationPage: CanvasPage? {
        didSet { self.didChangeRelationship(\.destinationPage, inverseKeyPath: \.linksFrom, oldValue: oldValue) }
    }

    @ModelObjectReference public var sourcePage: CanvasPage? {
        didSet { self.didChangeRelationship(\.sourcePage, inverseKeyPath: \.linksTo, oldValue: oldValue) }
    }

    //MARK: - Plist
    public static var propertyConversions: [ModelPlistKey : ModelPropertyConversion] {
        return [
            .CanvasLink.sourcePage: .modelID,
            .CanvasLink.destinationPage: .modelID,
        ]
    }

    public var plistRepresentation: [ModelPlistKey: Any] {
        var plist = self.otherProperties
        plist[.id] = self.id

        if let link = self.link {
            plist[.CanvasLink.link] = link.url.absoluteString
        }

        if let destinationPage = self.destinationPage {
            plist[.CanvasLink.destinationPage] = destinationPage.id
        }

        if let sourcePage = self.sourcePage {
            plist[.CanvasLink.sourcePage] = sourcePage.id
        }

        return plist
    }

    public func update(fromPlistRepresentation plist: [ModelPlistKey : Any]) throws {
        guard self.id == plist.attribute(withKey: .id) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        if let linkString: String = plist.attribute(withKey: .CanvasLink.link), let linkURL = URL(string: linkString), let link = PageLink(url: linkURL) {
            self.link = link
        }

        if let destinationID: ModelID = plist.attribute(withKey: .CanvasLink.destinationPage) {
            self.$destinationPage.modelID = destinationID
        }

        if let sourceID: ModelID = plist.attribute(withKey: .CanvasLink.sourcePage) {
            self.$sourcePage.modelID = sourceID
        }

        let plistKeys = ModelPlistKey.CanvasLink.all
        self.otherProperties = plist.filter { (key, _) -> Bool in
            return plistKeys.contains(key) == false
        }
    }

    //MARK: - Relationship Setup
    public func objectWasInserted() {
        self.$destinationPage.modelController = self.modelController
        self.$sourcePage.modelController = self.modelController
    }

    public func objectWasDeleted() {
        self.$destinationPage.performCleanUp()
        self.$sourcePage.performCleanUp()
    }
}


extension ModelPlistKey {
    enum CanvasLink {
        static let link = ModelPlistKey(rawValue: "link")!
        static let destinationPage = ModelPlistKey(rawValue: "destinationPage")!
        static let sourcePage = ModelPlistKey(rawValue: "sourcePage")!

        static var all: [ModelPlistKey] {
            return [.id, .CanvasLink.link, .CanvasLink.destinationPage, .CanvasLink.sourcePage]
        }
    }
}
