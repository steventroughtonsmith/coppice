//
//  PageHierarchy.swift
//  CoppiceCore
//
//  Created by Martin Pilkington on 15/08/2022.
//

import Foundation
import M3Data

final public class PageHierarchy: NSObject, CollectableModelObject {
    //MARK: - ModelObject Definitions
    public static var modelType: ModelType = ModelType(rawValue: "PageHierarchy")!
    public var id = ModelID(modelType: PageHierarchy.modelType)
    public weak var collection: ModelCollection<PageHierarchy>?

    //MARK: - Attributes
    public var rootPageID: ModelID?
    public var entryPoints: [EntryPoint] = []
    public var pages: [PageRef] = []
    public var links: [LinkRef] = []

    public static var propertyConversions: [ModelPlistKey: ModelPropertyConversion] {
        return [
            .PageHiearchy.rootPageID: .modelID,
            .PageHiearchy.pages: .array(.dictionary([
                .PageHiearchy.PageRef.canvasPageID: .modelID,
                .PageHiearchy.PageRef.pageID: .modelID,
            ])),
            .PageHiearchy.links: .array(.dictionary([
                .PageHiearchy.LinkRef.sourceID: .modelID,
                .PageHiearchy.LinkRef.destinationID: .modelID,
            ])),
        ]
    }

    public var otherProperties = [ModelPlistKey: Any]()


    //MARK: - Relationships
    @ModelObjectReference public var canvas: Canvas? {
        didSet { self.didChangeRelationship(\.canvas, inverseKeyPath: \.pageHierarchies, oldValue: oldValue) }
    }


    //MARK: - Plist
    public var plistRepresentation: [ModelPlistKey: Any] {
        var plist = self.otherProperties
        plist[.id] = self.id
        plist[.PageHiearchy.rootPageID] = self.rootPageID
        plist[.PageHiearchy.entryPoints] = self.entryPoints.map(\.plistRepresentation)
        plist[.PageHiearchy.pages] = self.pages.map(\.plistRepresentation)
        plist[.PageHiearchy.links] = self.links.map(\.plistRepresentation)
        return plist
    }

    public func update(fromPlistRepresentation plist: [ModelPlistKey: Any]) throws {
        guard self.id == plist.attribute(withKey: .id) else {
            throw ModelObjectUpdateErrors.idsDontMatch
        }

        let rootPageID: ModelID? = plist.attribute(withKey: .PageHiearchy.rootPageID)
        let rawEntryPoints: [[ModelPlistKey: Any]] = try plist.requiredAttribute(withKey: .PageHiearchy.entryPoints)
        let rawPages: [[ModelPlistKey: Any]] = try plist.requiredAttribute(withKey: .PageHiearchy.pages)
        let rawLinks: [[ModelPlistKey: Any]] = try plist.requiredAttribute(withKey: .PageHiearchy.links)

        var entryPoints: [EntryPoint] = []
        for rawEntryPoint in rawEntryPoints {
            guard let entryPoint = EntryPoint(plist: rawEntryPoint) else {
                throw ModelObjectUpdateErrors.attributeNotFound("entryPoints")
            }
            entryPoints.append(entryPoint)
        }

        var pages: [PageRef] = []
        for rawPage in rawPages {
            guard let pageRef = PageRef(plist: rawPage) else {
                throw ModelObjectUpdateErrors.attributeNotFound("pages")
            }
            pages.append(pageRef)
        }

        var links: [LinkRef] = []
        for rawLink in rawLinks {
            guard let link = LinkRef(plist: rawLink) else {
                throw ModelObjectUpdateErrors.attributeNotFound("links")
            }
            links.append(link)
        }

        self.rootPageID = rootPageID
        self.entryPoints = entryPoints
        self.pages = pages
        self.links = links
    }

    //MARK: - Relationship Setup
    public func objectWasInserted() {
        self.$canvas.modelController = self.modelController
    }

    public func objectWasDeleted() {
        self.$canvas.performCleanUp()
    }
}

extension PageHierarchy {
    public struct EntryPoint {
        var pageLink: PageLink
        var relativePosition: CGPoint

        init(pageLink: PageLink, relativePosition: CGPoint) {
            self.pageLink = pageLink
            self.relativePosition = relativePosition
        }

        init?(plist: [ModelPlistKey: Any]) {
            guard
                let pageLinkString: String = try? plist.requiredAttribute(withKey: .PageHiearchy.EntryPoint.pageLink),
                let url = URL(string: pageLinkString),
                let pageLink = PageLink(url: url),
                let relativePositionString: String = try? plist.requiredAttribute(withKey: .PageHiearchy.EntryPoint.relativePosition)
            else {
                return nil
            }

            self.pageLink = pageLink
            self.relativePosition = CGPoint(string: relativePositionString)
        }

        var plistRepresentation: [ModelPlistKey: Any] {
            return [
                .PageHiearchy.EntryPoint.pageLink: self.pageLink.url.absoluteString,
                .PageHiearchy.EntryPoint.relativePosition: self.relativePosition.stringRepresentation,
            ]
        }
    }

    public struct PageRef {
        var canvasPageID: ModelID
        var pageID: ModelID
        /// Position relative to the hierarchy
        var relativeContentFrame: CGRect

        internal init(canvasPageID: ModelID, pageID: ModelID, relativeContentFrame: CGRect) {
            self.canvasPageID = canvasPageID
            self.pageID = pageID
            self.relativeContentFrame = relativeContentFrame
        }


        init?(plist: [ModelPlistKey: Any]) {
            guard
                let canvasPageID: ModelID = try? plist.requiredAttribute(withKey: .PageHiearchy.PageRef.canvasPageID),
                let pageID: ModelID = try? plist.requiredAttribute(withKey: .PageHiearchy.PageRef.pageID),
                let relativeFrameString: String = try? plist.requiredAttribute(withKey: .PageHiearchy.PageRef.relativeContentFrame)
            else {
                return nil
            }

            self.canvasPageID = canvasPageID
            self.pageID = pageID
            self.relativeContentFrame = CGRect(string: relativeFrameString)
        }

        var plistRepresentation: [ModelPlistKey: Any] {
            return [
                .PageHiearchy.PageRef.canvasPageID: self.canvasPageID,
                .PageHiearchy.PageRef.pageID: self.pageID,
                .PageHiearchy.PageRef.relativeContentFrame: self.relativeContentFrame.stringRepresentation,
            ]
        }
    }

    public struct LinkRef {
        var sourceID: ModelID
        var destinationID: ModelID
        var link: PageLink

        init(sourceID: ModelID, destinationID: ModelID, link: PageLink) {
            self.sourceID = sourceID
            self.destinationID = destinationID
            self.link = link
        }

        init?(plist: [ModelPlistKey: Any]) {
            guard
                let sourceID: ModelID = try? plist.requiredAttribute(withKey: .PageHiearchy.LinkRef.sourceID),
                let destinationID: ModelID = try? plist.requiredAttribute(withKey: .PageHiearchy.LinkRef.destinationID),
                let linkString: String = try? plist.requiredAttribute(withKey: .PageHiearchy.LinkRef.link),
                let url = URL(string: linkString),
                let pageLink = PageLink(url: url)
            else {
                return nil
            }

            self.sourceID = sourceID
            self.destinationID = destinationID
            self.link = pageLink
        }

        var plistRepresentation: [ModelPlistKey: Any] {
            return [
                .PageHiearchy.LinkRef.sourceID: self.sourceID,
                .PageHiearchy.LinkRef.destinationID: self.destinationID,
                .PageHiearchy.LinkRef.link: self.link.url.absoluteString,
            ]
        }
    }
}

extension ModelPlistKey {
    enum PageHiearchy {
        static let rootPageID = ModelPlistKey(rawValue: "rootPageID")
        static let entryPoints = ModelPlistKey(rawValue: "entryPoints")
        static let pages = ModelPlistKey(rawValue: "pages")
        static let links = ModelPlistKey(rawValue: "links")

        enum EntryPoint {
            static let pageLink = ModelPlistKey(rawValue: "pageLink")
            static let relativePosition = ModelPlistKey(rawValue: "relativePosition")
        }

        enum PageRef {
            static let canvasPageID = ModelPlistKey(rawValue: "canvasPageID")
            static let pageID = ModelPlistKey(rawValue: "pageID")
            static let relativeContentFrame = ModelPlistKey(rawValue: "relativeContentFrame")
        }

        enum LinkRef {
            static let sourceID = ModelPlistKey(rawValue: "sourceID")
            static let destinationID = ModelPlistKey(rawValue: "destinationID")
            static let link = ModelPlistKey(rawValue: "link")
        }
    }
}
