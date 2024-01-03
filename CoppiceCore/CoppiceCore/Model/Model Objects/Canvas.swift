//
//  Canvas.swift
//  Coppice
//
//  Created by Martin Pilkington on 15/07/2019.
//  Copyright © 2019 M Cubed Software. All rights reserved.
//

import AppKit
import M3Data

@Model
final public class Canvas {
    public func objectWasInserted() {
        self.sortIndex = self.collection?.all.count ?? 0
    }


    //MARK: - Attributes
    @Attribute public var title: String = "New Canvas"
    @Attribute public var dateCreated = Date()
    @Attribute public var dateModified = Date()
    @Attribute public var sortIndex = 0
    @Attribute public var theme: Theme = Canvas.defaultTheme
    @Attribute public var viewPort: CGRect?
    @Attribute public var zoomFactor: Double = 1 {
        didSet {
            if self.zoomFactor > 1 {
                self.zoomFactor = 1
            } else if self.zoomFactor < 0.25 {
                self.zoomFactor = 0.25
            }
        }
    }

    @Attribute(isModelFile: true) public var thumbnail: Thumbnail?
    ///Added 2021.2
    @Attribute(optional: true, default: false) public var alwaysShowPageTitles: Bool = false

    lazy var hierarchyRestorer: PageHierarchyRestorer = {
        return PageHierarchyRestorer(canvas: self)
    }()


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
}
